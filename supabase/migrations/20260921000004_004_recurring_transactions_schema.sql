-- =============================================================================
-- Migration: 20260921000004_004_recurring_transactions_schema.sql
-- Description: Recurring Transactions schema with scheduling metadata,
--              Row Level Security (RLS), and Base Audit trigger.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'CREDIT')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    frequency TEXT NOT NULL CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM')),
    start_date DATE NOT NULL,
    next_occurrence DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    auto_create BOOLEAN NOT NULL DEFAULT false,

    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.recurring_transactions IS 'User recurring transaction templates (subscriptions, rent, salary, bills).';

-- Indexes for fast retrieval and scheduling checks
CREATE INDEX IF NOT EXISTS idx_recurring_user_active_next
    ON public.recurring_transactions (user_id, is_active, next_occurrence)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_recurring_user_category
    ON public.recurring_transactions (user_id, category_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_recurring_user_account
    ON public.recurring_transactions (user_id, account_id)
    WHERE deleted_at IS NULL;

-- Enable Row Level Security (RLS)
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "recurring_select_own"
    ON public.recurring_transactions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "recurring_insert_own"
    ON public.recurring_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "recurring_update_own"
    ON public.recurring_transactions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Attach base audit trigger
CREATE OR REPLACE TRIGGER trg_recurring_transactions_audit
    BEFORE INSERT OR UPDATE ON public.recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_base_audit_fields();

-- =============================================================================
-- Migration: 20260921000000_003_budgets_schema.sql
-- Description: Budgets & Spending Limits schema with category linkage,
--              Row Level Security (RLS), and Base Audit trigger.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE, -- NULL = Overall budget
    name TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    period TEXT NOT NULL CHECK (period IN ('WEEKLY', 'MONTHLY', 'CUSTOM')),
    start_date DATE NOT NULL,
    end_date DATE,
    alert_threshold NUMERIC(5, 2) NOT NULL DEFAULT 0.80 CHECK (alert_threshold > 0 AND alert_threshold <= 1.0),
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.budgets IS 'User-defined spending limits and category budgets.';

-- Indexes for fast retrieval
CREATE INDEX IF NOT EXISTS idx_budgets_user_active_deleted
    ON public.budgets (user_id, is_active)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_budgets_user_category
    ON public.budgets (user_id, category_id)
    WHERE deleted_at IS NULL;

-- Enable Row Level Security (RLS)
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "budgets_select_own"
    ON public.budgets
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "budgets_insert_own"
    ON public.budgets
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "budgets_update_own"
    ON public.budgets
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Attach base audit trigger
CREATE OR REPLACE TRIGGER trg_budgets_audit
    BEFORE INSERT OR UPDATE ON public.budgets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_base_audit_fields();

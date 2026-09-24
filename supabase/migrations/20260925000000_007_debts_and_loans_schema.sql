-- ════════════════════════════════════════════════════════════════════════════
-- Migration: 007_debts_and_loans_schema.sql
-- Description: Phase 11 Debts & Loans Tracking with Principal/Interest
--              separation, Installment Schedules, and Repayment Ledger.
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Create debts table
CREATE TABLE IF NOT EXISTS public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('YOU_OWE', 'YOU_ARE_OWED')),
    person_name TEXT NOT NULL,
    contact_number TEXT,
    principal_amount NUMERIC(12, 2) NOT NULL CHECK (principal_amount > 0),
    interest_type TEXT NOT NULL DEFAULT 'NONE' CHECK (interest_type IN ('NONE', 'PERCENTAGE', 'FIXED')),
    interest_rate NUMERIC(5, 2) DEFAULT 0.00 CHECK (interest_rate >= 0),
    interest_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (interest_amount >= 0),
    total_repayment_amount NUMERIC(12, 2) NOT NULL CHECK (total_repayment_amount >= principal_amount),
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SETTLED', 'CANCELLED')),
    account_id UUID,
    notes TEXT,

    -- Base audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    deleted_by UUID REFERENCES auth.users(id),

    -- Composite FK for tenant isolation
    CONSTRAINT fk_debts_account
        FOREIGN KEY (account_id, user_id)
        REFERENCES public.accounts(id, user_id)
        ON DELETE SET NULL,

    -- Unique composite constraint for child FK references
    CONSTRAINT uq_debts_id_user UNIQUE (id, user_id)
);

-- Indexes for performance & query filtering
CREATE INDEX IF NOT EXISTS idx_debts_user_status 
    ON public.debts(user_id, status) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_debts_user_type 
    ON public.debts(user_id, type) 
    WHERE deleted_at IS NULL;

-- Enable RLS for debts
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "debts_select_policy" ON public.debts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "debts_insert_policy" ON public.debts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "debts_update_policy" ON public.debts
    FOR UPDATE USING (auth.uid() = user_id);

-- Attach base audit trigger
CREATE TRIGGER trg_debts_base_audit
    BEFORE INSERT OR UPDATE ON public.debts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_base_audit_fields();


-- 2. Create debt_installments table (Repayment schedule)
CREATE TABLE IF NOT EXISTS public.debt_installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    principal_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    interest_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_due NUMERIC(12, 2) NOT NULL CHECK (total_due > 0),
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PARTIAL', 'PAID')),

    -- Base audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    deleted_by UUID REFERENCES auth.users(id),

    -- Composite FK for tenant isolation and cascading
    CONSTRAINT fk_debt_installments_debt
        FOREIGN KEY (debt_id, user_id)
        REFERENCES public.debts(id, user_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_debt_installments_debt 
    ON public.debt_installments(debt_id, installment_number) 
    WHERE deleted_at IS NULL;

-- Enable RLS for debt_installments
ALTER TABLE public.debt_installments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "debt_installments_select_policy" ON public.debt_installments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "debt_installments_insert_policy" ON public.debt_installments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "debt_installments_update_policy" ON public.debt_installments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "debt_installments_delete_policy" ON public.debt_installments
    FOR DELETE USING (auth.uid() = user_id);

-- Attach base audit trigger
CREATE TRIGGER trg_debt_installments_base_audit
    BEFORE INSERT OR UPDATE ON public.debt_installments
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_base_audit_fields();


-- 3. Create debt_repayments table (Actual payment ledger)
CREATE TABLE IF NOT EXISTS public.debt_repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL,
    installment_id UUID,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    repayment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,

    -- Base audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    deleted_by UUID REFERENCES auth.users(id),

    -- Composite FKs for tenant isolation
    CONSTRAINT fk_debt_repayments_debt
        FOREIGN KEY (debt_id, user_id)
        REFERENCES public.debts(id, user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_debt_repayments_account
        FOREIGN KEY (account_id, user_id)
        REFERENCES public.accounts(id, user_id)
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_debt_repayments_debt 
    ON public.debt_repayments(debt_id, repayment_date DESC) 
    WHERE deleted_at IS NULL;

-- Enable RLS for debt_repayments
ALTER TABLE public.debt_repayments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "debt_repayments_select_policy" ON public.debt_repayments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "debt_repayments_insert_policy" ON public.debt_repayments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "debt_repayments_update_policy" ON public.debt_repayments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "debt_repayments_delete_policy" ON public.debt_repayments
    FOR DELETE USING (auth.uid() = user_id);

-- Attach base audit trigger
CREATE TRIGGER trg_debt_repayments_base_audit
    BEFORE INSERT OR UPDATE ON public.debt_repayments
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_base_audit_fields();

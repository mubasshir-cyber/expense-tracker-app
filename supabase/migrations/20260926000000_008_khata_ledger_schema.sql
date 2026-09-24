-- ════════════════════════════════════════════════════════════════════════════
-- Migration: 20260926000000_008_khata_ledger_schema.sql
-- Description: Phase 14 Khata / Customer Ledger Module Schema
--              Dynamic ledger for credit sales (GIVEN) & payments (RECEIVED)
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Create khata_customers table
CREATE TABLE IF NOT EXISTS public.khata_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT,
    notes TEXT,

    -- Base audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    deleted_by UUID REFERENCES auth.users(id),

    -- Unique composite constraint to allow foreign key references with user_id
    CONSTRAINT uq_khata_customers_id_user UNIQUE (id, user_id)
);

-- Indexes for khata_customers
CREATE INDEX IF NOT EXISTS idx_khata_customers_user_name
    ON public.khata_customers(user_id, name)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_khata_customers_user_phone
    ON public.khata_customers(user_id, phone)
    WHERE deleted_at IS NULL;

-- Enable RLS for khata_customers
ALTER TABLE public.khata_customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "khata_customers_select_policy" ON public.khata_customers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "khata_customers_insert_policy" ON public.khata_customers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "khata_customers_update_policy" ON public.khata_customers
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "khata_customers_delete_policy" ON public.khata_customers
    FOR DELETE USING (auth.uid() = user_id);


-- 2. Create khata_entries table
CREATE TABLE IF NOT EXISTS public.khata_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('GIVEN', 'RECEIVED')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_opening_balance BOOLEAN NOT NULL DEFAULT FALSE,

    -- Base audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    deleted_by UUID REFERENCES auth.users(id),

    -- Composite FK for tenant isolation (prevents cross-user customer attachment)
    CONSTRAINT fk_khata_entries_customer
        FOREIGN KEY (customer_id, user_id)
        REFERENCES public.khata_customers(id, user_id)
        ON DELETE CASCADE
);

-- Indexes for khata_entries
CREATE INDEX IF NOT EXISTS idx_khata_entries_customer_date
    ON public.khata_entries(customer_id, entry_date, created_at)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_khata_entries_user_date
    ON public.khata_entries(user_id, entry_date)
    WHERE deleted_at IS NULL;

-- Enable RLS for khata_entries
ALTER TABLE public.khata_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "khata_entries_select_policy" ON public.khata_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "khata_entries_insert_policy" ON public.khata_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "khata_entries_update_policy" ON public.khata_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "khata_entries_delete_policy" ON public.khata_entries
    FOR DELETE USING (auth.uid() = user_id);


-- 3. Trigger for updated_at timestamps
CREATE OR REPLACE TRIGGER trg_khata_customers_updated_at
    BEFORE UPDATE ON public.khata_customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_khata_entries_updated_at
    BEFORE UPDATE ON public.khata_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

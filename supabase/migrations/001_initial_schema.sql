-- =============================================================================
-- Migration: 001_initial_schema.sql
-- Description: Hardened multi-user database schema with composite foreign keys,
--              user ownership enforcement, server-managed audit fields,
--              soft deletion, and automatic user onboarding seed.
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. BASE AUDIT TRIGGER FUNCTION
-- Server-managed timestamps and user attribution.
-- Prevents clients from tampering with created_at, created_by, updated_by, deleted_by.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_base_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := NOW();
        NEW.updated_at := NOW();
        IF auth.uid() IS NOT NULL THEN
            NEW.created_by := auth.uid();
            NEW.updated_by := auth.uid();
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Strictly preserve creation audit data
        NEW.created_at := OLD.created_at;
        NEW.created_by := OLD.created_by;
        NEW.updated_at := NOW();

        IF auth.uid() IS NOT NULL THEN
            NEW.updated_by := auth.uid();
            
            -- Soft delete transition: NULL -> timestamp
            IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
                NEW.deleted_by := auth.uid();
            -- Restore transition: timestamp -> NULL
            ELSIF NEW.deleted_at IS NULL AND OLD.deleted_at IS NOT NULL THEN
                NEW.deleted_by := NULL;
            -- If already deleted and updating other fields, retain original deleted_by
            ELSIF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NOT NULL THEN
                NEW.deleted_by := OLD.deleted_by;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public;

-- -----------------------------------------------------------------------------
-- 2. PROFILES TABLE (1:1 with auth.users)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    currency_code TEXT NOT NULL DEFAULT 'INR',
    currency_symbol TEXT NOT NULL DEFAULT '₹',
    
    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.profiles IS 'User profiles linked directly to auth.users.';

-- -----------------------------------------------------------------------------
-- 3. ACCOUNTS TABLE (Payment sources: Cash, Bank, UPI, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'CASH' CHECK (type IN ('CASH', 'BANK', 'UPI', 'SAVINGS', 'WALLET', 'OTHER')),
    opening_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Unique composite constraint for cross-user FK verification
    CONSTRAINT uq_accounts_id_user_id UNIQUE (id, user_id)
);

COMMENT ON TABLE public.accounts IS 'User payment sources and financial accounts.';

-- -----------------------------------------------------------------------------
-- 4. CATEGORIES TABLE (Expense & Credit classifications)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'CREDIT')),
    icon TEXT NOT NULL DEFAULT 'tag',
    color TEXT NOT NULL DEFAULT '#4F46E5',
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Unique composite constraint for cross-user & type matching FK verification
    CONSTRAINT uq_categories_id_user_id_type UNIQUE (id, user_id, type)
);

COMMENT ON TABLE public.categories IS 'Expense and income categorization catalog.';

-- -----------------------------------------------------------------------------
-- 5. TRANSACTIONS TABLE (Core financial entries)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL,
    category_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'CREDIT')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT,
    
    -- Audit fields
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Composite Foreign Keys enforcing:
    -- 1) Account belongs to the EXACT same user
    CONSTRAINT fk_transactions_account_user 
        FOREIGN KEY (account_id, user_id) 
        REFERENCES public.accounts (id, user_id) 
        ON DELETE RESTRICT,

    -- 2) Category belongs to the EXACT same user AND has the SAME transaction type (EXPENSE vs CREDIT)
    CONSTRAINT fk_transactions_category_user_type 
        FOREIGN KEY (category_id, user_id, type) 
        REFERENCES public.categories (id, user_id, type) 
        ON DELETE RESTRICT
);

COMMENT ON TABLE public.transactions IS 'Individual credit and expense transactions with composite integrity checks.';

-- -----------------------------------------------------------------------------
-- 6. INDEXES (Optimized for user isolation, date range, and soft deletes)
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_deleted_at ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS idx_accounts_user_active ON public.accounts(user_id, is_active) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_accounts_deleted_at ON public.accounts(deleted_at);

CREATE INDEX IF NOT EXISTS idx_categories_user_type ON public.categories(user_id, type, is_active) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_categories_deleted_at ON public.categories(deleted_at);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_user_type_date ON public.transactions(user_id, type, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_account ON public.transactions(account_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_deleted_at ON public.transactions(deleted_at);

-- -----------------------------------------------------------------------------
-- 7. AUDIT TRIGGERS ATTACHMENT
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_profiles ON public.profiles;
CREATE TRIGGER trg_audit_profiles
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_base_audit_fields();

DROP TRIGGER IF EXISTS trg_audit_accounts ON public.accounts;
CREATE TRIGGER trg_audit_accounts
BEFORE INSERT OR UPDATE ON public.accounts
FOR EACH ROW EXECUTE FUNCTION public.handle_base_audit_fields();

DROP TRIGGER IF EXISTS trg_audit_categories ON public.categories;
CREATE TRIGGER trg_audit_categories
BEFORE INSERT OR UPDATE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.handle_base_audit_fields();

DROP TRIGGER IF EXISTS trg_audit_transactions ON public.transactions;
CREATE TRIGGER trg_audit_transactions
BEFORE INSERT OR UPDATE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION public.handle_base_audit_fields();

-- -----------------------------------------------------------------------------
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- Strict user data isolation (auth.uid() = id / auth.uid() = user_id)
-- Hard DELETE is NOT granted to client roles to preserve audit trail.
-- Deletions are executed via soft delete: UPDATE table SET deleted_at = NOW()
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Profiles Policies (Owner is id = auth.uid())
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id AND deleted_at IS NULL);

CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Accounts Policies (Owner is user_id = auth.uid())
CREATE POLICY "accounts_select_own" ON public.accounts
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "accounts_insert_own" ON public.accounts
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "accounts_update_own" ON public.accounts
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Categories Policies (Owner is user_id = auth.uid())
CREATE POLICY "categories_select_own" ON public.categories
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "categories_insert_own" ON public.categories
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "categories_update_own" ON public.categories
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Transactions Policies (Owner is user_id = auth.uid())
CREATE POLICY "transactions_select_own" ON public.transactions
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "transactions_insert_own" ON public.transactions
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "transactions_update_own" ON public.transactions
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 9. AUTOMATED USER ONBOARDING TRIGGER (Seed Profile, Accounts & Categories)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user_onboarding()
RETURNS TRIGGER AS $$
DECLARE
    v_cash_account_id UUID;
BEGIN
    -- 1. Create Profile (id = auth.users.id)
    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        avatar_url,
        currency_code,
        currency_symbol,
        created_by,
        updated_by
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url',
        'INR',
        '₹',
        NEW.id,
        NEW.id
    );

    -- 2. Seed Default Accounts (Cash, Primary Bank, UPI)
    INSERT INTO public.accounts (user_id, name, type, opening_balance, created_by, updated_by)
    VALUES (NEW.id, 'Cash', 'CASH', 0.00, NEW.id, NEW.id)
    RETURNING id INTO v_cash_account_id;

    INSERT INTO public.accounts (user_id, name, type, opening_balance, created_by, updated_by)
    VALUES (NEW.id, 'Primary Bank', 'BANK', 0.00, NEW.id, NEW.id);

    INSERT INTO public.accounts (user_id, name, type, opening_balance, created_by, updated_by)
    VALUES (NEW.id, 'UPI / Wallet', 'UPI', 0.00, NEW.id, NEW.id);

    -- 3. Seed Default Expense Categories (11 items)
    INSERT INTO public.categories (user_id, name, type, icon, color, created_by, updated_by) VALUES
    (NEW.id, 'Food & Dining', 'EXPENSE', 'utensils', '#F59E0B', NEW.id, NEW.id),
    (NEW.id, 'Groceries', 'EXPENSE', 'shopping-cart', '#10B981', NEW.id, NEW.id),
    (NEW.id, 'Travel & Transport', 'EXPENSE', 'car', '#06B6D4', NEW.id, NEW.id),
    (NEW.id, 'Shopping', 'EXPENSE', 'shopping-bag', '#EC4899', NEW.id, NEW.id),
    (NEW.id, 'Bills & Utilities', 'EXPENSE', 'receipt', '#3B82F6', NEW.id, NEW.id),
    (NEW.id, 'Rent & Housing', 'EXPENSE', 'home', '#8B5CF6', NEW.id, NEW.id),
    (NEW.id, 'Entertainment', 'EXPENSE', 'film', '#F43F5E', NEW.id, NEW.id),
    (NEW.id, 'Health & Medical', 'EXPENSE', 'heart-pulse', '#14B8A6', NEW.id, NEW.id),
    (NEW.id, 'Education', 'EXPENSE', 'book-open', '#F97316', NEW.id, NEW.id),
    (NEW.id, 'Fuel', 'EXPENSE', 'fuel', '#EF4444', NEW.id, NEW.id),
    (NEW.id, 'Other Expense', 'EXPENSE', 'more-horizontal', '#64748B', NEW.id, NEW.id);

    -- 4. Seed Default Income / Credit Categories (7 items)
    INSERT INTO public.categories (user_id, name, type, icon, color, created_by, updated_by) VALUES
    (NEW.id, 'Salary', 'CREDIT', 'briefcase', '#10B981', NEW.id, NEW.id),
    (NEW.id, 'Freelance & Side Gig', 'CREDIT', 'laptop', '#3B82F6', NEW.id, NEW.id),
    (NEW.id, 'Business & Sales', 'CREDIT', 'trending-up', '#8B5CF6', NEW.id, NEW.id),
    (NEW.id, 'Investments & Returns', 'CREDIT', 'badge-percent', '#F59E0B', NEW.id, NEW.id),
    (NEW.id, 'Gift & Allowance', 'CREDIT', 'gift', '#EC4899', NEW.id, NEW.id),
    (NEW.id, 'Refund & Cashback', 'CREDIT', 'rotate-ccw', '#06B6D4', NEW.id, NEW.id),
    (NEW.id, 'Other Income', 'CREDIT', 'plus-circle', '#64748B', NEW.id, NEW.id);

    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public;

-- Trigger on auth.users when a new user signs up
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_onboarding();

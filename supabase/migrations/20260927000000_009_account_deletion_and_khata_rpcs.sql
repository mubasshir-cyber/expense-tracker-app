-- ════════════════════════════════════════════════════════════════════════════
-- Migration: 20260927000000_009_account_deletion_and_khata_rpcs.sql
-- Description: Production readiness hardening:
--              1. Secure RPC for atomic Khata customer & opening balance creation
--              2. Complete account & user data deletion RPC (Google Play / App Store compliance)
--              3. Partial performance indexes for Khata queries
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Atomic Customer Creation with Opening Balance RPC
CREATE OR REPLACE FUNCTION public.create_khata_customer_with_opening(
    p_name TEXT,
    p_phone TEXT,
    p_address TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_opening_balance NUMERIC(12, 2) DEFAULT 0.00,
    p_opening_description TEXT DEFAULT 'Opening Balance'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_customer_id UUID;
    v_customer_row RECORD;
    v_entry_row RECORD;
BEGIN
    -- Secure auth check
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Validate input
    IF TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Customer name cannot be empty';
    END IF;

    -- 1. Create Customer
    INSERT INTO public.khata_customers (
        user_id,
        name,
        phone,
        address,
        notes,
        created_by,
        updated_by
    ) VALUES (
        v_user_id,
        TRIM(p_name),
        TRIM(p_phone),
        p_address,
        p_notes,
        v_user_id,
        v_user_id
    )
    RETURNING * INTO v_customer_row;

    v_customer_id := v_customer_row.id;

    -- 2. If opening balance > 0, create GIVEN ledger entry atomically
    IF p_opening_balance > 0 THEN
        INSERT INTO public.khata_entries (
            user_id,
            customer_id,
            type,
            amount,
            description,
            entry_date,
            is_opening_balance,
            created_by,
            updated_by
        ) VALUES (
            v_user_id,
            v_customer_id,
            'GIVEN',
            p_opening_balance,
            COALESCE(p_opening_description, 'Opening Balance'),
            CURRENT_DATE,
            TRUE,
            v_user_id,
            v_user_id
        )
        RETURNING * INTO v_entry_row;
    END IF;

    RETURN to_jsonb(v_customer_row);
END;
$$ 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public;

-- Grant execution to authenticated users only
REVOKE ALL ON FUNCTION public.create_khata_customer_with_opening FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_khata_customer_with_opening TO authenticated;


-- 2. User Account Data Deletion RPC (Google Play / App Store compliance)
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete all user data across all financial systems (or soft delete)
    -- Transactions & Categories & Accounts
    DELETE FROM public.transactions WHERE user_id = v_user_id;
    DELETE FROM public.categories WHERE user_id = v_user_id;
    DELETE FROM public.accounts WHERE user_id = v_user_id;
    
    -- Budgets & Recurring
    DELETE FROM public.budgets WHERE user_id = v_user_id;
    DELETE FROM public.recurring_transactions WHERE user_id = v_user_id;
    
    -- Notifications
    DELETE FROM public.notifications WHERE user_id = v_user_id;
    DELETE FROM public.notification_settings WHERE user_id = v_user_id;
    
    -- Goals & Contributions
    DELETE FROM public.goal_contributions WHERE user_id = v_user_id;
    DELETE FROM public.savings_goals WHERE user_id = v_user_id;
    
    -- Debts & Repayments
    DELETE FROM public.debt_repayments WHERE user_id = v_user_id;
    DELETE FROM public.debt_installments WHERE user_id = v_user_id;
    DELETE FROM public.debts WHERE user_id = v_user_id;
    
    -- Khata
    DELETE FROM public.khata_entries WHERE user_id = v_user_id;
    DELETE FROM public.khata_customers WHERE user_id = v_user_id;
    
    -- Profile
    DELETE FROM public.profiles WHERE id = v_user_id;

    RETURN TRUE;
END;
$$ 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public;

REVOKE ALL ON FUNCTION public.delete_user_account FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account TO authenticated;


-- 3. Additional Composite & Partial Query Performance Indexes
CREATE INDEX IF NOT EXISTS idx_khata_entries_user_customer_date 
    ON public.khata_entries(user_id, customer_id, entry_date ASC) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_khata_entries_running_calc 
    ON public.khata_entries(customer_id, entry_date ASC, created_at ASC, id ASC) 
    WHERE deleted_at IS NULL;

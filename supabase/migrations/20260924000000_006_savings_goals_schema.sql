-- ==============================================================================
-- Migration: 006_savings_goals_schema
-- Description: Creates savings_goals and goal_contributions tables with RLS and composite constraints
-- ==============================================================================

-- 1. Create savings_goals table
CREATE TABLE IF NOT EXISTS public.savings_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    target_amount NUMERIC(12,2) NOT NULL CHECK (target_amount > 0),
    target_date DATE,
    icon TEXT,
    color TEXT,
    account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_savings_goals_id_user UNIQUE (id, user_id)
);

-- 2. Create goal_contributions table (ledger of deposits and withdrawals)
CREATE TABLE IF NOT EXISTS public.goal_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL,
    user_id UUID NOT NULL,
    account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount != 0),
    contribution_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_contributions_goal_user FOREIGN KEY (goal_id, user_id) 
        REFERENCES public.savings_goals(id, user_id) ON DELETE CASCADE
);

-- 3. Enable RLS
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_contributions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for savings_goals
CREATE POLICY "Users can view own savings goals"
    ON public.savings_goals
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own savings goals"
    ON public.savings_goals
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own savings goals"
    ON public.savings_goals
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own savings goals"
    ON public.savings_goals
    FOR DELETE
    USING (auth.uid() = user_id);

-- 5. RLS Policies for goal_contributions
CREATE POLICY "Users can view own goal contributions"
    ON public.goal_contributions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goal contributions"
    ON public.goal_contributions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goal contributions"
    ON public.goal_contributions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own goal contributions"
    ON public.goal_contributions
    FOR DELETE
    USING (auth.uid() = user_id);

-- 6. Attach audit triggers if trigger function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'handle_base_audit_fields'
    ) THEN
        DROP TRIGGER IF EXISTS tr_savings_goals_audit ON public.savings_goals;
        CREATE TRIGGER tr_savings_goals_audit
            BEFORE INSERT OR UPDATE ON public.savings_goals
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_base_audit_fields();

        DROP TRIGGER IF EXISTS tr_goal_contributions_audit ON public.goal_contributions;
        CREATE TRIGGER tr_goal_contributions_audit
            BEFORE INSERT OR UPDATE ON public.goal_contributions
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_base_audit_fields();
    END IF;
END $$;

-- 7. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_savings_goals_user 
    ON public.savings_goals (user_id, is_active) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal 
    ON public.goal_contributions (goal_id, contribution_date) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_goal_contributions_user 
    ON public.goal_contributions (user_id, contribution_date) 
    WHERE deleted_at IS NULL;

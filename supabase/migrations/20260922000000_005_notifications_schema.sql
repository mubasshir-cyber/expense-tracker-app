-- ==============================================================================
-- Migration: 005_notifications_schema
-- Description: Creates notifications and notification_settings tables with RLS
-- ==============================================================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'BUDGET_WARNING',
        'BUDGET_EXCEEDED',
        'RECURRING_UPCOMING',
        'RECURRING_DUE',
        'RECURRING_COMPLETED',
        'SPENDING_ALERT',
        'MONTHLY_SUMMARY',
        'SYSTEM'
    )),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    reference_id TEXT,
    scheduled_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb,
    idempotency_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Unique index for idempotent alert generation
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_idempotency 
    ON public.notifications (user_id, idempotency_key) 
    WHERE deleted_at IS NULL AND idempotency_key IS NOT NULL;

-- 2. Create notification_settings table
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    budget_warning_enabled BOOLEAN NOT NULL DEFAULT true,
    budget_exceeded_enabled BOOLEAN NOT NULL DEFAULT true,
    recurring_upcoming_enabled BOOLEAN NOT NULL DEFAULT true,
    recurring_auto_created_enabled BOOLEAN NOT NULL DEFAULT true,
    spending_alerts_enabled BOOLEAN NOT NULL DEFAULT true,
    monthly_summary_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
    ON public.notifications
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
    ON public.notifications
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
    ON public.notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
    ON public.notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- 5. RLS Policies for notification_settings
CREATE POLICY "Users can view own notification settings"
    ON public.notification_settings
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification settings"
    ON public.notification_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification settings"
    ON public.notification_settings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 6. Attach audit triggers if trigger function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'handle_base_audit_fields'
    ) THEN
        DROP TRIGGER IF EXISTS tr_notifications_audit ON public.notifications;
        CREATE TRIGGER tr_notifications_audit
            BEFORE INSERT OR UPDATE ON public.notifications
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_base_audit_fields();

        DROP TRIGGER IF EXISTS tr_notification_settings_audit ON public.notification_settings;
        CREATE TRIGGER tr_notification_settings_audit
            BEFORE INSERT OR UPDATE ON public.notification_settings
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_base_audit_fields();
    END IF;
END $$;

-- 7. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread 
    ON public.notifications (user_id, read_at) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created 
    ON public.notifications (user_id, created_at DESC) 
    WHERE deleted_at IS NULL;

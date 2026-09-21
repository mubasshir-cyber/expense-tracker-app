-- =============================================================================
-- Migration: 002_accounts_icon_color_opening_balance
-- Description: Adds icon and color columns to the accounts table to support
--              visual account customization in the Flutter UI. These fields
--              are referenced by AccountRepository.createAccount() and
--              AccountRepository.updateAccount() but were absent from the
--              initial schema.
--
--              Also confirms opening_balance is visible to RLS-authenticated
--              clients (it already exists — no column change needed for it).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Add icon column to accounts
-- Stores an icon identifier (e.g. lucide icon name or emoji).
-- NULL = no custom icon set; UI falls back to the account type default icon.
-- -----------------------------------------------------------------------------
ALTER TABLE public.accounts
    ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT NULL;

COMMENT ON COLUMN public.accounts.icon IS
    'Optional icon identifier for the account (e.g. lucide icon name or emoji).';

-- -----------------------------------------------------------------------------
-- Add color column to accounts
-- Stores a hex color string (e.g. '#10B981') for UI theming.
-- NULL = no custom color; UI falls back to the account type default color.
-- -----------------------------------------------------------------------------
ALTER TABLE public.accounts
    ADD COLUMN IF NOT EXISTS color TEXT DEFAULT NULL;

COMMENT ON COLUMN public.accounts.color IS
    'Optional hex color string for account UI theming (e.g. #10B981).';

-- -----------------------------------------------------------------------------
-- Update onboarding seed to remain compatible (no change needed — the new
-- columns default to NULL so the existing INSERT in handle_new_user_onboarding
-- continues to work without modification).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Verification: list accounts columns (informational — no-op in production)
-- -----------------------------------------------------------------------------
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'accounts'
-- ORDER BY ordinal_position;

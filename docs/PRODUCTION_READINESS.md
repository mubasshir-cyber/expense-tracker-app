# Expense Tracker — Production Readiness Specification & Verification

## 1. Architecture Overview
- **Frontend Architecture**: Flutter (Material 3) with feature-first organization (`lib/features/*`), Riverpod for asynchronous and immutable state management, GoRouter for declarative route handling and authentication guards.
- **Backend Architecture**: Supabase PostgreSQL backend with Row Level Security (RLS) on 100% of tenant tables.
- **Ledger Separation**: Strict isolation maintained between independent financial systems:
  - **System A**: Personal Transactions (Income/Expense, Accounts, Categories, Monthly Summaries, Cash Flow Reports)
  - **System B**: Budgets (Monthly spending limits and warning thresholds derived dynamically)
  - **System C**: Recurring Payments (Scheduled bills, auto-computation, leap year & month-end handling)
  - **System D**: Savings Goals (Targets, dedicated deposit/withdrawal ledger)
  - **System E**: Debt & Loans (Principal, interest rate models, installments, repayment ledger)
  - **System F**: Khata / Customer Ledger (Customers, GIVEN credit sales, RECEIVED customer payments, dynamic running ledger, advance balances, total receivable aggregation)

---

## 2. Security & Data Protection
- **Secrets Management**: No elevated `service_role` keys or private credentials are embedded in client source code. Client uses public Anonymous API keys with authenticated JWT validation.
- **Tenant Isolation**: Every database table enforces `user_id` ownership checks and RLS policies (`auth.uid() = user_id`).
- **Composite Ownership Protection**:
  - `transactions`: Foreign key `(account_id, user_id)` and `(category_id, user_id, type)` prevents cross-tenant data tampering.
  - `khata_entries`: Composite foreign key `(customer_id, user_id)` guarantees entries cannot be attached to another user's customer.
  - `goal_contributions`: Composite foreign key `(goal_id, user_id)`.
  - `debt_repayments` & `debt_installments`: Composite foreign keys `(debt_id, user_id)`.
- **Soft Deletion & Audit Fields**: Audit fields (`created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`, `deleted_by`) managed securely via database triggers (`handle_base_audit_fields`).

---

## 3. Khata / Customer Ledger Verification
- **Formulas**:
  - `balance = SUM(GIVEN) - SUM(RECEIVED)`
  - `balance > 0` $\rightarrow$ **DUE / RECEIVABLE**
  - `balance == 0` $\rightarrow$ **SETTLED**
  - `balance < 0` $\rightarrow$ **ADVANCE**
- **Deterministic Ledger Ordering**: Sorted chronologically by `entry_date ASC`, `created_at ASC`, `id ASC`.
- **Total Portfolio Receivables**: Sums strictly positive due balances without subtracting advances (advance balances reported separately).
- **Opening Balance**: Represented as a first-class `GIVEN` ledger entry with `is_opening_balance = true`.
- **Atomic Creation**: Supported via atomic PostgreSQL RPC `create_khata_customer_with_opening` with client-side rollback fallback.

---

## 4. Navigation & Dashboard Redesign
- **Top App Bar Hamburger Menu**: Opens a sliding `AppDrawer` with grouped sections (Home, Financial Tools, Account & Data, Settings & Preferences, Sign Out).
- **Bottom Navigation**: Preserved 4 core daily hubs (Home, Transactions, Reports, Profile).
- **Phase 13 Dashboard Customization**: Reorderable and toggleable widget layout persisted to local versioned storage (`dashboard_layout_v1`) without refetching underlying financial providers on reordering.

---

## 5. Standardized Application States
Reusable `AppStateView` component implemented in `lib/core/widgets/app_state_view.dart` covering:
1. `AppLoadingState`
2. `AppEmptyState`
3. `AppOfflineState` (No Internet)
4. `AppTimeoutState`
5. `AppUnauthorizedState` (401 / Session Expired)
6. `AppForbiddenState` (403 Access Denied)
7. `AppNotFoundState` (404 Not Found)
8. `AppServerErrorState` (500 Internal Error)
9. `AppMaintenanceState`
10. `AppUpdateRequiredState`
11. `AppGenericErrorState`
12. `AppSuccessState`

---

## 6. Authentication & Account Deletion Compliance
- **Account Deletion Flow**: User can permanently delete account and all associated financial records directly from `ProfileScreen -> Delete Account & Data` or via the web endpoint `${AppConfig.accountDeletionUrl}` (fulfilling Google Play and Apple App Store guidelines).
- **Privacy Policy & Terms**: Accessible directly within the app and via configurable URLs in `AppConfig`.

---

## 7. Platform Verification
- **Android**:
  - `compileSdk`: 36 (target API 36+ supported)
  - `minSdk`: Flutter default (API 21+)
  - `INTERNET` permission explicitly declared in `AndroidManifest.xml`
  - Release Proguard/R8 optimization rules configured in `android/app/proguard-rules.pro`
- **iOS**:
  - `PrivacyInfo.xcprivacy` manifest added with declarations for `UserDefaults`, `FileTimestamp`, `SystemBootTime`, and `DiskSpace` required-reason APIs.
  - `ITSAppUsesNonExemptEncryption` set to `false` in `Info.plist`.

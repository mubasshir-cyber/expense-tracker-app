# Project Memory & Progress Log

**Project:** Personal Expense & Finance Management App  
**Platform:** Flutter / Android (Google Play Store)  
**Database & Auth:** Supabase + PostgreSQL (RLS)  
**Initialized:** September 19, 2026  
**Last Updated:** September 20, 2026 (Migration Audit + Milestone 4 Complete)  

---

## 📌 Active Architecture & Technical Decisions

- **State Management:** Flutter Riverpod (`AsyncNotifier`, `StreamProvider`, `Provider`)
- **Routing:** GoRouter (declarative routing with reactive auth state guards via `routerProvider`)
- **Database:** Supabase PostgreSQL with strict Row Level Security (RLS)
- **Primary Database Choice:** Supabase PostgreSQL (Google Sheets will *not* be used as primary database)
- **Data Isolation:** `auth.uid() = user_id` on all tables (`profiles`, `accounts`, `categories`, `transactions`)
- **Design Principles:** Mobile-first, Dark/Light mode, Google Fonts Inter, vibrant Credit (green `#10B981`) vs. Expense (red `#EF4444`) aesthetics, `fl_chart` visualizations
- **Authentication:** Decoupled `AuthUser` domain model, `AuthRepository`, `AuthController` (`AsyncNotifier<void>`), and `authStateProvider` (`StreamProvider<AuthState>`)
- **Transaction Types:** `EXPENSE` and `CREDIT` (not `income`) — enforced by DB `CHECK` constraint and `TransactionType` enum
- **Balance Formula:** `Current Balance = openingBalance + Σ(CREDIT) - Σ(EXPENSE)` — computed from transactions, NOT stored on accounts
- **Migration Rule:** Every schema change requires a new `supabase/migrations/` file created via `npm run db:new` and pushed via `npm run db:push`. See `docs/rule.md` for full policy.

---

## 📂 Documentation Manifest

| Document | Path | Purpose |
|---|---|---|
| **BRD** | [docs/Expense_Tracker_BRD.md](file:///c:/src/expense_tracker/docs/Expense_Tracker_BRD.md) | Full Business Requirements Document |
| **Phases & Roadmap** | [docs/phase.md](file:///c:/src/expense_tracker/docs/phase.md) | 8-Phase implementation plan & task checklist |
| **System Architecture** | [docs/architecture.md](file:///c:/src/expense_tracker/docs/architecture.md) | System design, Flutter layer structure, ER diagram, balance formulas |
| **Security Architecture** | [docs/security.md](file:///c:/src/expense_tracker/docs/security.md) | PostgreSQL RLS policies, threat modeling, token storage, database constraints |
| **Development Rules & Testing** | [docs/rule.md](file:///c:/src/expense_tracker/docs/rule.md) | Code standards, feature boundaries, and testing strategy |
| **Project Memory** | [docs/memory.md](file:///c:/src/expense_tracker/docs/memory.md) | Continuous changelog and project state tracker |

---

## 🪵 Project Activity & Changelog

### 🚀 Step 1: Environment & Project Inception
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Verified Flutter SDK (`3.47.5`), Dart SDK (`3.13.4`), and Android toolchain.
  - Verified Android Pixel 7 Emulator (`emulator-5554`, API 36).
  - Executed initial build and verified debug APK installation on Android emulator.

### 📄 Step 2: BRD Ingestion & Documentation Foundation
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Migrated and saved full Business Requirements Document to `docs/Expense_Tracker_BRD.md`.
  - Created `docs/phase.md` establishing the 8-phase development roadmap and checklists.
  - Authored `docs/architecture.md` outlining the Feature-First directory structure, Mermaid flowcharts, and PostgreSQL ER diagrams.
  - Authored `docs/security.md` containing complete SQL Row Level Security (RLS) policies, threat modeling matrix, and Android KeyStore token security rules.
  - Authored `docs/rule.md` defining architecture standards, MVP feature boundaries, and comprehensive unit/widget/security testing strategy.
  - Created `docs/memory.md` to continuously log all project evolutions and state transitions.

### 🧱 Step 3: Milestone 1 — Tasks 1.1 & 1.2 (Folder Structure & Dependencies)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Created Feature-First directory structure (`lib/app/`, `lib/core/`, `lib/features/`).
  - Added dependencies in `pubspec.yaml`: `flutter_riverpod: ^2.6.1`, `go_router: ^16.2.1`, `google_fonts: ^6.3.2`, `lucide_icons: ^0.257.0`, `intl: ^0.20.2`, `flutter_secure_storage: ^9.2.4`.
  - Executed `flutter pub get` (43 dependencies resolved & synced).
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.
  - Enhanced `.gitignore` with environment variables (`.env*`), keystores (`*.jks`, `key.properties`), and Android local configurations.
  - Initialized Git repository (`git init`).
  - Created project [README.md](file:///c:/src/expense_tracker/README.md) covering non-technical overview, multi-user privacy, feature breakdown, comparison matrix, tech stack, and documentation index.

### 🎨 Step 4: Milestone 1 — Task 1.3 (Design System Foundation)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Implemented `lib/core/theme/app_colors.dart`: Centralized financial palette (Primary Indigo, Credit Emerald Green `#10B981`, Expense Coral Red `#EF4444`, dark/light surfaces and borders).
  - Implemented `lib/core/theme/app_typography.dart`: Full Material 3 text hierarchy using Google Fonts Inter + dedicated financial amount typography styles.
  - Implemented `lib/core/theme/app_theme.dart`: Configured complete `AppTheme.light` and `AppTheme.dark` (`useMaterial3: true`) covering `ColorScheme`, `CardTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `NavigationBarTheme`, `AppBarTheme`.
  - Implemented atomic UI widgets in `lib/core/widgets/`:
    - `app_card.dart`: Configurable padding, margin, border, elevation, and tap callback.
    - `app_button.dart`: Supporting primary, secondary, outlined, ghost styles with loading spinner and icon support.
    - `amount_display.dart`: Formatted financial values with currency symbol (`₹` default), credit/expense semantics (`+` / `-`), and multi-size typography.
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.

### 🧭 Step 5: Milestone 1 — Task 1.4 (Declarative Navigation & Shell)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Implemented `lib/app/app_shell.dart`: Stateful shell host with Material 3 `NavigationBar` (Home, Transactions, Reports, Profile) and global `FloatingActionButton` (`+`) linking to `/add-transaction`.
  - Implemented `lib/app/router.dart`: `GoRouter` declarative navigation using `StatefulShellRoute.indexedStack` with 4 branches and modal `/add-transaction` route.
  - Implemented presentation placeholders:
    - `lib/features/dashboard/presentation/dashboard_screen.dart`
    - `lib/features/transactions/presentation/transactions_screen.dart`
    - `lib/features/transactions/presentation/add_transaction_screen.dart`
    - `lib/features/reports/presentation/reports_screen.dart`
    - `lib/features/profile/presentation/profile_screen.dart`
  - Replaced legacy icons package with `lucide_icons_flutter` for full compatibility with modern Flutter SDK `final class IconData`.
  - Updated `lib/app/app.dart` to use `MaterialApp.router`.
  - Updated `lib/main.dart` with `WidgetsFlutterBinding.ensureInitialized()` and `ProviderScope`.
  - Updated `test/widget_test.dart` smoke tests verifying shell navigation and tab loading.
  - Executed `flutter test` $\rightarrow$ **All tests passed!**
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.

### ⚡ Step 6: Milestone 1 — Task 1.5 (Riverpod Foundation) & Milestone 1 Completion
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Implemented `lib/app/providers.dart`: Added `ThemeModeNotifier` and `themeModeProvider` supporting `system`, `light`, and `dark` modes with `setThemeMode()` and `toggle()`.
  - Updated `lib/app/app.dart`: Converted `ExpenseTrackerApp` to `ConsumerWidget` to reactively consume `themeModeProvider`.
  - Authored unit test suite [test/unit/theme_mode_notifier_test.dart](file:///c:/src/expense_tracker/test/unit/theme_mode_notifier_test.dart) covering all state transitions.
  - Executed `flutter test` $\rightarrow$ **All 4 tests passed!**
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.
  - **Milestone 1 is now 100% COMPLETE**.

### 🗄️ Step 7: Milestone 2 — Tasks 2.1 to 2.4 (Hardened Multi-User Schema, Composite FKs & RLS Migration)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Authored and hardened final SQL migration [supabase/migrations/001_initial_schema.sql](file:///c:/src/expense_tracker/supabase/migrations/001_initial_schema.sql):
    - Explicit `SET search_path = public` on all `SECURITY DEFINER` functions (`handle_base_audit_fields`, `handle_new_user_onboarding`).
    - Standardized on `pgcrypto` extension (`gen_random_uuid()`).
    - **`profiles` RLS**: Uses `auth.uid() = id`.
    - **Pure Soft-Delete**: Hard `DELETE` removed for client roles; deletions handled via `UPDATE ... SET deleted_at = NOW()`.
    - **Composite Foreign Keys**:
      - `transactions(account_id, user_id) -> accounts(id, user_id)` (enforces account ownership).
      - `transactions(category_id, user_id, type) -> categories(id, user_id, type)` (enforces category ownership + `EXPENSE` / `CREDIT` semantic consistency).
    - **Audit Immutability**: `handle_base_audit_fields()` trigger preserves `created_at` and `created_by` across updates while managing `updated_by`, `updated_at`, and `deleted_by` via `auth.uid()`.
    - **Onboarding Trigger**: `trg_on_auth_user_created` seeds profile + 3 accounts (Cash, Bank, UPI) + 18 categories on sign up.
  - Updated [docs/architecture.md](file:///c:/src/expense_tracker/docs/architecture.md) and [docs/security.md](file:///c:/src/expense_tracker/docs/security.md).

### 🔐 Step 8: Milestone 2 — Task 2.5 (Environment Configuration & flutter_dotenv)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Added `flutter_dotenv: ^5.2.1` to `pubspec.yaml` and registered `.env` under assets.
  - Created `.env` for local secrets and committed `.env.example` as template.
  - Updated [.gitignore](file:///c:/src/expense_tracker/.gitignore) to securely ignore `.env` while allowing `!.env.example`.
  - Created typed environment accessor [lib/core/config/env.dart](file:///c:/src/expense_tracker/lib/core/config/env.dart) (`Env.supabaseUrl`, `Env.supabaseAnonKey`).
  - Updated `lib/main.dart` with `await dotenv.load(fileName: '.env')`.
  - Authored unit test suite [test/unit/env_test.dart](file:///c:/src/expense_tracker/test/unit/env_test.dart).
  - Executed `flutter test` $\rightarrow$ **All 5 tests passed!**
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.

### 🛠️ Step 9: Milestone 2 — Task 2.6 & 2.7 (Migration Applied & Verified, Milestone 2 Complete)
- **Date:** 2026-09-19
- **Status:** Completed ✅
- **Details:**
  - Authenticated Supabase CLI via `npm run db:login` and linked project `szytuopieuuzvpttiypi` via `npm run db:link`.
  - Pushed [supabase/migrations/001_initial_schema.sql](file:///c:/src/expense_tracker/supabase/migrations/001_initial_schema.sql) to the remote Supabase database (`npm run db:push`).
  - Verified remote migration status: `{"migrations":[{"local":"001","remote":"001","time":"001"}]}` $\rightarrow$ **100% In Sync**.
  - All 4 tables (`profiles`, `accounts`, `categories`, `transactions`), composite FKs, base audit trigger, RLS policies, and onboarding seed triggers are active on Supabase.
  - Initialized `Supabase.initialize()` in `lib/main.dart` with `Env.supabaseUrl` and `Env.supabaseAnonKey`.
  - Executed `flutter test` $\rightarrow$ **All 5 tests passed!**
  - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.
  - **Milestone 2 is now 100% COMPLETE**.

### 🔒 Step 10: Milestone 3 — Tasks 3.1 to 3.7 (Authentication & Session Management Complete)
- **Date:** 2026-09-20
- **Status:** Completed ✅
- **Details:**
  - **Supabase SDK & Configuration**: Added `supabase_flutter: ^2.17.2`. Updated `lib/core/config/supabase_config.dart` with centralized `SupabaseConfig.initialize()` and `client` getter. Exposed `supabasePublishableKey` in `Env`.
  - **Domain Model**: Created `lib/features/auth/domain/models/auth_user.dart` (`id`, `email`, `emailConfirmedAt`, `isEmailConfirmed`).
  - **Auth Repository**: Implemented `lib/features/auth/data/repositories/auth_repository.dart` (`signUp`, `signIn`, `signOut`, `resetPassword`, `currentUser`, `authStateChanges`) with `hide AuthUser` avoiding SDK naming collision.
  - **Reactive Auth State Provider**: Implemented `lib/features/auth/presentation/providers/auth_state_provider.dart` with `StreamProvider<AuthState>` emitting `AuthLoading`, `AuthUnauthenticated`, and `AuthAuthenticated(user)`.
  - **Auth Controller**: Implemented `lib/features/auth/presentation/providers/auth_controller.dart` (`AsyncNotifier<void>`) handling action states, errors, and button loading indicators.
  - **Authentication Screens**:
    - `lib/features/auth/presentation/screens/splash_screen.dart` (Initial loading session check).
    - `lib/features/auth/presentation/screens/login_screen.dart` (Email/password validation, snackbars, GoRouter links).
    - `lib/features/auth/presentation/screens/signup_screen.dart` (Password confirmation, minimum length validation).
    - `lib/features/auth/presentation/screens/forgot_password_screen.dart` (Password reset instructions).
  - **GoRouter Auth Guard**:
    - Created `lib/app/auth_router_refresh_notifier.dart` bridging session changes to GoRouter.
    - Updated `lib/app/router.dart` with `routerProvider` enforcing automatic redirect rules:
      - Unauthenticated users $\rightarrow$ `/login`.
      - Authenticated users $\rightarrow$ `/` (Dashboard).
      - Loading $\rightarrow$ `/splash`.
    - Added Logout button to `ProfileScreen`.
  - **Verification**:
    - Updated `test/widget_test.dart` testing both unauthenticated login redirect and authenticated dashboard shell.
    - Executed `flutter test` $\rightarrow$ **All 12 tests passed!**
    - Executed `flutter analyze` $\rightarrow$ **No issues found! (0 errors, 0 warnings)**.
    - Executed `flutter build apk --debug` $\rightarrow$ **Debug APK compiled successfully**.
  - **Milestone 3 is now 100% COMPLETE**.

---

### ⚙️ Step 11: Milestone 4 — Core Data Layer (Models, Repositories, Services, Tests)
- **Date:** 2026-09-20
- **Status:** Completed ✅
- **Details:**
  - **4.1 Domain Models**: Created `UserProfile`, `AccountModel` (with `openingBalance`), `CategoryModel`, `TransactionModel`, `TransactionType` enum (`EXPENSE` / `CREDIT`).
  - **4.2 Repositories**: Implemented `ProfileRepository` (getCurrentProfile, updateProfile) and `AccountRepository` (CRUD + soft-delete + `openingBalance`).
  - **4.3 CategoryRepository**: Handles both system-seeded and user-owned categories. `getCategories(type:)` filters by `EXPENSE` or `CREDIT`.
  - **4.4 TransactionRepository**: Filtered queries via `TransactionFilter`, CRUD, soft-delete, `sumByType()` aggregation. DB columns corrected to `transaction_date` / `description`.
  - **4.5 FinancialCalculationService**: `getAccountBalance`, `getOverallSummary`, `getCurrentMonthSummary` — all computed from transactions, not stored on accounts.
  - **4.6 Riverpod Providers**: `accountsProvider`, `accountBalanceProvider`, `financialCalculationServiceProvider`, `categoriesProvider`, `transactionsProvider`, `overallSummaryProvider`, `currentMonthSummaryProvider`.
  - **4.7 Unit Tests (4.8)**: 60 new tests — `TransactionFilter` (9), `FinancialCalculationService` (15), `AccountRepository` serialization (8), `CategoryRepository` serialization (10), `TransactionRepository` serialization + DB contract (18).
  - **Milestone 4 is now 100% COMPLETE.** `flutter test` → **91/91 passing**, `flutter analyze` → **0 issues**.

### 🗃️ Step 12: Migration Audit — `002_accounts_icon_color_opening_balance`
- **Date:** 2026-09-20
- **Status:** Completed ✅
- **Details:**
  - **Audit Finding**: `accounts` table in `001_initial_schema.sql` was missing `icon` and `color` columns referenced by `AccountRepository.createAccount()` / `updateAccount()`.
  - **Fix**: Created and pushed [`supabase/migrations/20260920173737_002_accounts_icon_color_opening_balance.sql`](file:///c:/src/expense_tracker/supabase/migrations/20260920173737_002_accounts_icon_color_opening_balance.sql):
    - `ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT NULL`
    - `ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS color TEXT DEFAULT NULL`
  - **Model Fix**: Added `openingBalance` field to `AccountModel.fromMap()` / `toMap()` / `copyWith()` — it existed in the DB but was absent from the Dart model.
  - **Repository Fix**: Updated `AccountRepository.createAccount()` to include `openingBalance` parameter and use null-aware `?` syntax for `icon` / `color`.
  - **Migration Status**: Pushed to remote Supabase (`npm run db:push`) — confirmed `upToDate: true`.
  - **Rule Added**: Migration policy added to `docs/rule.md` and enforced going forward.

### 📱 Step 13: Step 5.1 — Authenticated App Shell Integration
- **Date:** 2026-09-20
- **Status:** Completed ✅
- **Details:**
  - Preserved `StatefulShellRoute.indexedStack` with `AppShell` in `lib/app/app_shell.dart`.
  - Configured 4 semantic navigation destinations: Home (`/`), Transactions (`/transactions`), Reports (`/reports`), Profile (`/profile`).
  - Configured global FAB (`+ Add Transaction`) routing via `context.push('/add-transaction')`.
  - Verified auth-driven routing via `authStateProvider` and `routerProvider` (no manual route pushes on login/logout).
  - Authored comprehensive widget test suite [`test/app/app_shell_test.dart`](file:///c:/src/expense_tracker/test/app/app_shell_test.dart) verifying all destinations, tab switching, state preservation, and FAB navigation.
  - Verification: `flutter analyze` → **0 issues**, `flutter test` → **94/94 passing**.

### 📱 Step 14: Step 5.2 — Dashboard Integration & Modular Components
- **Date:** 2026-09-20
- **Status:** Completed ✅
- **Details:**
  - Built modular Dashboard presentation architecture:
    - [`lib/features/dashboard/presentation/dashboard_screen.dart`](file:///c:/src/expense_tracker/lib/features/dashboard/presentation/dashboard_screen.dart): Reactive `ConsumerWidget` consuming `overallSummaryProvider`, `currentMonthSummaryProvider`, `recentTransactionsProvider`, `accountsProvider`, `categoriesProvider`, and `userProfileProvider`.
    - [`lib/features/dashboard/presentation/widgets/balance_card.dart`](file:///c:/src/expense_tracker/lib/features/dashboard/presentation/widgets/balance_card.dart): Hero Current Balance (`Opening Balance + ΣCredits - ΣExpenses`) and Total Credits / Expenses.
    - [`lib/features/dashboard/presentation/widgets/monthly_summary_card.dart`](file:///c:/src/expense_tracker/lib/features/dashboard/presentation/widgets/monthly_summary_card.dart): "This Month" side-by-side credit/expense breakdown cards.
    - [`lib/features/dashboard/presentation/widgets/quick_actions.dart`](file:///c:/src/expense_tracker/lib/features/dashboard/presentation/widgets/quick_actions.dart): Responsive "+ Add Expense" and "+ Add Credit" quick action buttons.
    - [`lib/features/dashboard/presentation/widgets/recent_transactions.dart`](file:///c:/src/expense_tracker/lib/features/dashboard/presentation/widgets/recent_transactions.dart): Top 5 recent transactions with category icons, account info, relative dates, and dedicated Empty State.
  - Implemented reactive loading, error state with retry (invalidating Riverpod providers), and pull-to-refresh (`RefreshIndicator`).
  - Added 7 widget tests in [`test/features/dashboard/dashboard_screen_test.dart`](file:///c:/src/expense_tracker/test/features/dashboard/dashboard_screen_test.dart).
  - Verification: `flutter analyze` → **0 issues**, `flutter test` → **101/101 passing**.

---

### 📱 Step 15: Milestone 5.3 to 5.7 — Core UI & State Management MVP Complete
- **Date:** 2026-09-21
- **Status:** Completed ✅
- **Details:**
  - **5.3 Add Transaction**:
    - Created [`lib/features/transactions/presentation/add_transaction_screen.dart`](file:///c:/src/expense_tracker/lib/features/transactions/presentation/add_transaction_screen.dart) supporting both Expense and Credit modes via custom segmented toggle.
    - Dynamic category filtering matching selected type (`EXPENSE` vs `CREDIT`).
    - Active accounts dropdown and currency-aware amount field with positive number validation.
    - Form submission guards against duplicate submissions while saving.
    - Invalidation of `overallSummaryProvider`, `currentMonthSummaryProvider`, `recentTransactionsProvider`, `allTransactionsProvider`, and `accountsProvider`.
  - **5.4 Transaction History**:
    - Implemented [`lib/features/transactions/presentation/transactions_screen.dart`](file:///c:/src/expense_tracker/lib/features/transactions/presentation/transactions_screen.dart).
    - Chronological date grouping (`TODAY`, `YESTERDAY`, formatted dates).
    - Filter chips (`All`, `Expense`, `Credit`), search bar, and dropdown filters using domain `TransactionFilter`.
    - Pull-to-refresh, empty states, error with retry, and tap to edit.
  - **5.5 Edit & Delete Transactions**:
    - Reused `AddTransactionScreen` for editing existing transactions, pre-filling amount, type, category, account, date, and notes.
    - Updates executed via `TransactionRepository.updateTransaction()`.
    - Soft delete via `TransactionRepository.deleteTransaction()` guarded by confirmation dialog (`AlertDialog`).
  - **5.6 Accounts & Categories Management UI**:
    - Implemented [`lib/features/accounts/presentation/accounts_screen.dart`](file:///c:/src/expense_tracker/lib/features/accounts/presentation/accounts_screen.dart): Active/inactive accounts list, dynamic balance calculation per account, Add/Edit Account bottom sheet, and soft-delete/deactivation.
    - Implemented [`lib/features/categories/presentation/categories_screen.dart`](file:///c:/src/expense_tracker/lib/features/categories/presentation/categories_screen.dart): Expense and Credit tabbed lists, system vs. custom category badges, custom category creation/editing, and soft delete protection for system defaults.
    - Updated [`lib/features/profile/presentation/profile_screen.dart`](file:///c:/src/expense_tracker/lib/features/profile/presentation/profile_screen.dart) with navigation tiles linking to `/accounts` and `/categories`.
  - **5.7 Routes & Providers**:
    - Updated [`lib/app/router.dart`](file:///c:/src/expense_tracker/lib/app/router.dart) with `/add-transaction` (accepting pre-selected type/transaction model), `/accounts`, and `/categories`.
    - Added `allAccountsProvider` (`activeOnly: false`) in [`lib/features/accounts/presentation/providers/account_providers.dart`](file:///c:/src/expense_tracker/lib/features/accounts/presentation/providers/account_providers.dart).
  - **Testing & Verification**:
    - Authored unit & widget test suites:
      - `test/features/transactions/presentation/add_transaction_screen_test.dart` (7 tests)
      - `test/features/transactions/presentation/transactions_screen_test.dart` (6 tests)
      - `test/features/accounts/presentation/accounts_screen_test.dart` (4 tests)
      - `test/features/categories/presentation/categories_screen_test.dart` (4 tests)
      - `test/app/app_shell_test.dart` (updated)
    - `flutter analyze`: **0 issues found (No issues found!)**.
    - `flutter test`: **121/121 tests passed!**.
  - **Milestone 5 is now 100% COMPLETE**.

---

## ✅ Step N: Phase 6 — Analytics, Charts & Reports COMPLETE

- **Date:** 2026-09-21
- **Status:** Completed ✅
- **Details:**
  - **Critical Bug Fixed:** `TransactionRepository.getTransactions()` was missing `.isFilter('deleted_at', null)`. Added the filter — now consistent with `sumByType()`. Soft-deleted transactions no longer appear in Reports or Transaction History.
  - **fl_chart ^0.70.2** added to pubspec.yaml.
  - **New domain models** (`report_period.dart`, `report_granularity.dart`, `category_expense_summary.dart`, `account_summary.dart`, `trend_point.dart`, `financial_report.dart`).
  - **ReportsAnalyticsService**: pure Dart aggregation — totals, averages, largest, category %, account breakdowns, time-series bucketing (daily/weekly/monthly). No NaN. No div-by-zero.
  - **Single-dataset rule**: `reportTransactionsProvider` fetches once → `financialReportProvider` computes `FinancialReport` → all widgets read from that single result.
  - **Report filters**: thisWeek / thisMonth / lastMonth / last3Months / thisYear / custom date range. `ReportFilterNotifier` guards invalid (start > end) ranges.
  - **Charts**: `IncomeExpenseChart` (LineChart, tooltips, empty state) + `ExpensePieChart` (PieChart, touch-to-select, legend, top-6 + Others).
  - **UI states**: Loading shimmer / Error + Retry / Empty with guidance / Pull-to-refresh.
  - **Tests added**:
    - `test/features/reports/domain/reports_analytics_service_test.dart` (~40 tests)
    - `test/features/reports/domain/report_period_test.dart` (~20 tests)
    - `test/features/reports/domain/soft_delete_regression_test.dart` (5 regression tests)
    - `test/features/reports/presentation/reports_screen_test.dart` (widget + notifier tests)
  - **Opening & Closing Balance & Negative Sign Fix**:
    - Fixed `AmountDisplay` negative amount formatting — negative numbers always retain their `-` sign regardless of `showSign`.
    - Added `openingBalance` (sum of net transactions prior to period start) and `closingBalance` (`openingBalance + netCashFlow`) to `FinancialReport`.
    - Added `openingBalanceProvider` in `reports_providers.dart` computing prior credits − expenses.
    - Updated `FinancialOverviewCard` with an Opening → Closing balance flow banner and inflow/outflow grid.
    - Added `ReportPeriod.today` ("Today") and `ReportPeriod.yesterday` ("Yesterday") presets and Single Date picker to `PeriodSelector`.
- **Documentation updated**: `docs/phase.md` + `docs/memory.md`
  - `flutter analyze`: **0 issues**
  - `flutter test`: **196/196 tests passed!**
  - **Milestone 6 is now 100% COMPLETE.**

---

## ✅ Step 8: Phase 7 — Budgets & Spending Limits COMPLETE

- **Date:** 2026-09-21
- **Status:** Completed ✅
- **Details:**
  - **Database Migration (`20260921000000_003_budgets_schema.sql`)**:
    - Created `budgets` table with `category_id` (nullable for overall budget), `name`, `amount`, `period` (`WEEKLY`, `MONTHLY`, `CUSTOM`), `start_date`, `end_date`, `alert_threshold` (default 0.80), `is_active`, and base audit columns.
    - Attached `handle_base_audit_fields()` trigger and enabled Row Level Security (RLS) with user ownership check (`auth.uid() = user_id`).
    - Successfully pushed migration to remote database via `npm run db:push`.
  - **Dynamic Calculation Engine (`BudgetCalculationService`)**:
    - Single source of truth: Calculates spending strictly from actual expense transactions in `TransactionRepository.sumByType(type: expense, ...)` over the budget's active date range. Zero manual `spent` cache in the database.
    - Added `String? categoryId` support to `TransactionRepository.sumByType`.
  - **Domain Models**:
    - `BudgetPeriod` enum (Weekly, Monthly, Custom) with date range calculations.
    - `BudgetModel` entity with JSON mapping, copyWith, and equality.
    - `BudgetProgress` computed spending state (`spent`, `remaining`, `percentage`, `progressRatioClamped`, `isWarning`, `isOverBudget`, `status`).
  - **Riverpod State Layer**:
    - `budgetRepositoryProvider`, `budgetCalculationServiceProvider`, `allBudgetsProvider`, `activeBudgetsProvider`, `activeBudgetsProgressProvider`, `overallMonthlyBudgetProgressProvider`, `budgetProgressFamily`, `budgetControllerProvider`.
  - **Presentation & UI**:
    - `BudgetsScreen`: Overview banner (Total Budget, Total Spent, Net Remaining), active vs. all filters, animated progress indicators, warning/over-budget badges, empty state graphic, and CRUD actions.
    - `AddEditBudgetSheet`: Bottom sheet modal with overall vs category scope toggle, category dropdown, amount input, period selector, custom date picker, warning alert threshold slider, and form validation.
    - `BudgetCard`: Color-coded meters (green $\to$ amber $\to$ red) and over-budget delta calculations.
    - `DashboardBudgetCard`: Live budget meters on the dashboard with "See All" navigation.
    - `ProfileScreen`: Added "Budgets & Spending Limits" ListTile under Data Management.
    - `GoRouter`: Registered `/budgets` route.
  - **Testing & Verification**:
    - Added unit test suites for `budget_period_test.dart`, `budget_model_test.dart`, `budget_progress_test.dart`, `budget_calculation_service_test.dart`.
    - Added widget test suites for `budgets_screen_test.dart` and `dashboard_budget_card_test.dart`.
    - `flutter analyze`: **No issues found! (0 errors, 0 warnings)**.
    - `flutter test`: **214/214 tests passed!**.
  - **Phase 7 is now 100% COMPLETE.**

---

## ✅ Step 9: Phase 8 — Recurring Transactions COMPLETE

- **Date:** 2026-09-22
- **Status:** Completed ✅
- **Details:**
  - **Database Migration (`20260921000004_004_recurring_transactions_schema.sql`)**:
    - Created `recurring_transactions` table with columns: `id`, `user_id`, `account_id`, `category_id`, `type` (`EXPENSE`, `CREDIT`), `amount`, `description`, `frequency` (`DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`, `CUSTOM`), `start_date`, `next_occurrence`, `end_date`, `is_active`, `auto_create`, `created_at`, `updated_at`, `deleted_at`.
    - Attached `handle_base_audit_fields()` trigger and enabled Row Level Security (RLS) with user ownership check (`auth.uid() = user_id`).
    - Successfully pushed migration to remote Supabase database via `npm run db:push`.
  - **Scheduling Engine & Domain Architecture (`RecurringScheduleService`)**:
    - Implemented strict separation: Recurring Template $\neq$ Transaction.
    - `RecurringFrequency` enum with month-end drift prevention (e.g. Jan 31 $\to$ Feb 28/29 $\to$ Mar 31).
    - `RecurringTransactionModel` entity with JSON serialization, `isDue` validation, and next occurrence calculation.
    - `RecurringScheduleService`: `findDue`, `findUpcoming`, `processRecurringOccurrence`, and `processAutoCreateDueItems`.
  - **Data Layer (`RecurringRepository`)**:
    - Supabase CRUD operations, soft-delete handling, and `advanceNextOccurrence` mutation.
  - **Riverpod State Management**:
    - `recurringRepositoryProvider`, `recurringScheduleServiceProvider`, `allRecurringTransactionsProvider`, `activeRecurringTransactionsProvider`, `upcomingRecurringProvider`, and `recurringControllerProvider`.
  - **Presentation & UI**:
    - `RecurringTransactionsScreen`: Filter chips (Active, Paused, All), Monthly Commitments Banner, Pull-to-Refresh, empty states, and Delete confirmation dialog.
    - `AddEditRecurringSheet`: Material bottom sheet modal with type selector, description, amount, frequency picker, start/next/end date pickers, account/category dropdowns, and auto-create toggle.
    - `RecurringTransactionCard`: Color-coded amount, frequency badge, auto-create indicator, due status pill, quick "Record Now" button, and options popup menu (pause/resume, edit, delete).
    - `DashboardUpcomingPaymentsCard`: Integrated into `DashboardScreen` displaying 30-day horizon upcoming bills.
    - `ProfileScreen`: Added "Recurring Schedules" entry in Profile screen under Data Management.
    - `GoRouter`: Registered `/recurring` route.
  - **Testing & Verification**:
    - Added unit test suites: `recurring_frequency_test.dart`, `recurring_transaction_model_test.dart`, `recurring_schedule_service_test.dart`.
    - Added widget test suites: `recurring_transactions_screen_test.dart`, `dashboard_upcoming_payments_card_test.dart`.
    - `flutter analyze`: **No issues found! (0 errors, 0 warnings)**.
    - `flutter test`: **237/237 tests passed! (100% passing)**.
  - **Phase 8 is now 100% COMPLETE & LOCKED.**

---

## ✅ Step 10: Phase 9 — Smart Financial Notifications COMPLETE

- **Date:** 2026-09-22
- **Status:** Completed ✅
- **Details:**
  - **Database Migration (`20260922000000_005_notifications_schema.sql`)**:
    - Created `notifications` table (`id`, `user_id`, `type`, `title`, `message`, `data`, `is_read`, `read_at`, `created_at`, `deleted_at`) with RLS (`auth.uid() = user_id`) and `handle_base_audit_fields()`.
    - Created `notification_settings` table (`user_id`, `budget_alerts_enabled`, `recurring_reminders_enabled`, `daily_summary_enabled`, `spending_surge_enabled`, `created_at`, `updated_at`) with RLS.
    - Successfully pushed migration to remote Supabase DB via `npm run db:push`.
  - **Domain Models & Smart Alert Engine (`SmartAlertEngine`)**:
    - Clean architectural separation: Alerts consume domain models (`BudgetProgress`, `RecurringTransactionModel`, `FinancialSummary`) without repeating calculation logic.
    - `NotificationType` enum (`BUDGET_WARNING`, `BUDGET_EXCEEDED`, `RECURRING_DUE_SOON`, `RECURRING_DUE_TODAY`, `RECURRING_AUTO_RECORDED`, `SPENDING_SURGE`, `DAILY_SUMMARY`, `SYSTEM`) with icons and semantic colors.
    - `NotificationModel` entity with JSON serialization, `copyWith`, and `markAsRead`.
    - `NotificationSettingsModel` entity for user notification preference switches.
    - `SmartAlertEngine`: Evaluates budget threshold warnings, over-budget alerts, recurring reminders, auto-created notifications, and spending surges with preference filtering.
  - **Data Repositories**:
    - `NotificationRepository` (getNotifications, markAsRead, markAllAsRead, deleteNotification, clearAll).
    - `NotificationSettingsRepository` (getSettings, updateSettings).
  - **Riverpod State Management**:
    - `notificationRepositoryProvider`, `notificationSettingsRepositoryProvider`.
    - `notificationsListProvider`, `unreadNotificationCountProvider`, `notificationSettingsProvider`.
    - `notificationsControllerProvider`.
  - **Presentation & UI**:
    - `NotificationsScreen`: Filter tabs (All, Unread), swipe-to-dismiss, mark-all-as-read action, empty state, and deep link navigation.
    - `NotificationSettingsScreen`: Preference switches for Budget Alerts, Recurring Reminders, Daily Summaries, and Spending Surge alerts.
    - `NotificationCard`: Type-based icon container, semantic badge colors, relative timestamp, read/unread status dot.
    - `NotificationBadgeIcon`: Dashboard app bar bell icon with live unread count badge.
    - `ProfileScreen`: Added Notifications menu item with unread badge.
    - `GoRouter`: Registered `/notifications` and `/notification-settings` routes.
  - **Testing & Verification**:
    - Added unit test suites: `notification_model_test.dart`, `notification_type_test.dart`, `notification_settings_model_test.dart`, `smart_alert_engine_test.dart`.
    - Added widget test suites: `notifications_screen_test.dart`, `notification_settings_screen_test.dart`, `dashboard_notification_bell_test.dart`.
    - `flutter analyze`: **No issues found! (0 errors, 0 warnings)**.
    - `flutter test`: **260/260 tests passed! (100% passing)**.
  - **Phase 9 is now 100% COMPLETE & LOCKED.**

---

## 🎯 Next: Step 11: Phase 10 — Savings Goals 💰

Phase 9 is locked. All 260 tests passing. Ready for Phase 10.




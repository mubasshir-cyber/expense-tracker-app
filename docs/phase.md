# Personal Expense Tracker --- Project Implementation Phases & Roadmap

This document outlines the step-by-step development phases, milestones, deliverables, and checklists for building the **Personal Expense & Finance Management App** based on the [BRD (Business Requirements Document)](file:///c:/src/expense_tracker/docs/Expense_Tracker_BRD.md).

---

## 📊 Overall Progress & Milestones

- [x] **Phase 1: Flutter Foundation & Architecture Setup** (100%)
- [x] **Phase 2: Supabase Backend & Database Schema with RLS** (100%)
- [x] **Phase 3: Authentication & Session Management** (100%)
- [x] **Phase 4: Core Data Layer, Models & Repositories** (100%)
- [x] **Phase 5: Core UI & State Management (MVP)** (100%)
- [x] **Phase 6: Analytics, Charts & Reports** (100%)
- [x] **Phase 7: Budgets & Spending Limits** (100%) ✅
- [x] **Phase 8: Recurring Transactions** (100%) 🔁
- [x] **Phase 9: Smart Financial Notifications** (100%) 🔔
- [ ] **Phase 10: Savings Goals** (Next) 💰
- [ ] **Phase 11: Debt / Loan Tracker** (Planned) 💳
- [ ] **Phase 12: Export & Import (CSV, PDF)** (Planned) 📤
- [ ] **Phase 13: Dashboard Customization & Widget System** (Planned) 🎨

---

## 🚀 Phase 1: Flutter Foundation & Architecture Setup (Milestone 1) ✅ COMPLETE

**Goal:** Establish a solid technical baseline: configure folder structure, define premium design system & theme tokens, configure GoRouter navigation, and initialize Riverpod state management foundation.

### Deliberate Step-by-Step Sequence:
1. [x] **1.1 Folder Structure & Architecture Layout**:
   - Scaffolded `lib/app/`, `lib/core/`, and `lib/features/` modular directories.
   - Cleaned up initial layout.
2. [x] **1.2 Core Dependencies & Configuration (`pubspec.yaml`)**:
   - State Management: `flutter_riverpod` (^2.6.1)
   - Navigation: `go_router` (^16.2.1)
   - Typography & Icons: `google_fonts` (^6.3.2), `lucide_icons_flutter` (^3.1.20)
   - Utilities & Storage: `intl` (^0.20.2), `flutter_secure_storage` (^9.2.4)
   - Verified via `flutter pub get` and `flutter analyze` (0 issues).
3. [x] **1.3 Design System & Theme Foundation**:
   - `core/theme/app_colors.dart` (Semantic Green for Credit, Coral/Red for Expense, Dark/Light palettes, surface & border tokens).
   - `core/theme/app_typography.dart` (Google Fonts Inter styles with financial amount typography).
   - `core/theme/app_theme.dart` (Complete Material 3 Light & Dark themes with Card, Input, Button, NavigationBar, and AppBar configs).
   - `core/widgets/` (Atomic UI widgets: `AppCard`, `AppButton`, `AmountDisplay` with semantic currency formatting).
4. [x] **1.4 Declarative Navigation & Shell (`go_router`)**:
   - `app/app_shell.dart`: Implemented `AppShell` with `StatefulNavigationShell`, Material 3 `NavigationBar` (Home, Transactions, Reports, Profile), and global `+` Floating Action Button.
   - `app/router.dart`: Configured `GoRouter` with `StatefulShellRoute.indexedStack` (preserving tab state across all 4 branches) and full-screen dialog route for `/add-transaction`.
   - `features/*/presentation/`: Scaffolded minimal placeholder screens (`DashboardScreen`, `TransactionsScreen`, `ReportsScreen`, `ProfileScreen`, `AddTransactionScreen`).
   - `app/app.dart`: Configured root `MaterialApp.router`.
   - `lib/main.dart`: Wired up `ProviderScope` entry point.
   - Verified via `flutter test` (all passed) and `flutter analyze` (0 issues).
5. [x] **1.5 Riverpod State Management Baseline**:
   - `lib/app/providers.dart`: Implemented global `ThemeModeNotifier` and `themeModeProvider`.
   - `lib/app/app.dart`: Wired up `ConsumerWidget` with reactive `themeMode` consumption.
   - `test/unit/theme_mode_notifier_test.dart`: Added unit tests for theme mode initialization, toggle, and explicit updates.
   - Verified via `flutter test` (all 4 passed) and `flutter analyze` (0 issues).

---

## 🗄️ Phase 2: Supabase Backend, Database Schema & RLS (Milestone 2) ✅ COMPLETE

**Goal:** Author and apply reproducible SQL migrations, establish Base Audit entity triggers, enforce Row Level Security (RLS), configure automated onboarding seed data, and connect the Flutter client.

### Step-by-Step Sequence:
1. [x] **2.1 Base Entity / Audit Design**:
   - Standardized `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`, `deleted_by` referencing `auth.users(id)`.
   - Automated `handle_base_audit_fields()` trigger populating audit fields securely via `auth.uid()`.
2. [x] **2.2 Initial PostgreSQL Migration (`001_initial_schema.sql`)**:
   - `profiles`: 1:1 with `auth.users` (`full_name`, `email`, `avatar_url`, `currency_code`, `currency_symbol` + base audit).
   - `accounts`: Multi-account support (`CASH`, `BANK`, `UPI`, `WALLET`, `SAVINGS`, `OTHER` + base audit).
   - `categories`: Expense/Credit classification (`name`, `type`, `icon`, `color`, `is_active` + base audit).
   - `transactions`: Core ledger (`amount > 0`, `type`, `account_id`, `category_id`, `transaction_date`, `payment_method` + base audit).
   - Performance Indexes for tenant isolation and soft delete queries (`WHERE deleted_at IS NULL`).
3. [x] **2.3 Row Level Security (RLS) Policies**:
   - RLS enabled on all 4 tables with strict `auth.uid() = user_id` / `auth.uid() = id` policies across SELECT, INSERT, UPDATE.
   - Client hard DELETE disabled to protect audit trail.
4. [x] **2.4 Automated User Onboarding Trigger**:
   - Trigger `trg_on_auth_user_created` on `auth.users` auto-creates profile and seeds 3 default accounts (Cash, Primary Bank, UPI) + 18 default categories (11 Expense, 7 Credit).
5. [x] **2.5 Environment Configuration (`flutter_dotenv`)**:
   - Added `flutter_dotenv` to `pubspec.yaml` and registered `.env` asset.
   - Created `.env` (gitignored) and `.env.example` (tracked in git).
   - Created typed configuration access in [lib/core/config/env.dart](file:///c:/src/expense_tracker/lib/core/config/env.dart).
   - Loaded `.env` in `lib/main.dart` with `await dotenv.load(fileName: '.env')`.
6. [x] **2.6 Supabase CLI Migration Tooling & Flutter Client**:
   - Created [package.json](file:///c:/src/expense_tracker/package.json) with npm migration scripts (`db:push`, `db:push:dry`, `db:new`, `db:status`, `db:reset`, `db:link`, `db:login`).
   - Initialized Supabase CLI config (`supabase/config.toml`).
   - Added `supabase_flutter: ^2.17.2` to `pubspec.yaml`.
   - Configured `Supabase.initialize()` in `lib/main.dart`.
7. [x] **2.7 Database Migration Applied & Verified**:
   - Pushed migration `001_initial_schema.sql` via `npm run db:push`.
   - Verified local and remote migrations are 100% in sync (`npm run db:status`).
   - Verified via `flutter test` (all 5 passed) and `flutter analyze` (0 issues).

---

## 🔐 Phase 3: Authentication & Session Management (Milestone 3) ✅ COMPLETE

**Goal:** Implement full Supabase Auth integration with reactive routing and auto-redirection based on auth state.

### Deliberate Step-by-Step Sequence:
1. [x] **3.1 Supabase Flutter Setup & Verification**:
   - Resolved `supabase_flutter: ^2.17.2` dependency and verified toolchain compatibility.
2. [x] **3.2 Environment & Client Configuration**:
   - Configured `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in `.env` and [lib/core/config/env.dart](file:///c:/src/expense_tracker/lib/core/config/env.dart).
   - Implemented [lib/core/config/supabase_config.dart](file:///c:/src/expense_tracker/lib/core/config/supabase_config.dart) with centralized `initialize()` and `client` accessor.
   - Updated `main.dart` initialization sequence: `load .env` $\rightarrow$ `SupabaseConfig.initialize()` $\rightarrow$ `ProviderScope` $\rightarrow$ `ExpenseTrackerApp`.
3. [x] **3.3 Domain Model & Data Repository**:
   - Created decoupled domain model [lib/features/auth/domain/models/auth_user.dart](file:///c:/src/expense_tracker/lib/features/auth/domain/models/auth_user.dart).
   - Created [lib/features/auth/data/repositories/auth_repository.dart](file:///c:/src/expense_tracker/lib/features/auth/data/repositories/auth_repository.dart) encapsulating `signUp`, `signIn`, `signOut`, `resetPassword`, `currentUser`, and `authStateChanges` stream.
   - Created [lib/features/auth/presentation/providers/auth_repository_provider.dart](file:///c:/src/expense_tracker/lib/features/auth/presentation/providers/auth_repository_provider.dart).
   - Authored unit tests in [test/features/auth/domain/auth_user_test.dart](file:///c:/src/expense_tracker/test/features/auth/domain/auth_user_test.dart).
4. [x] **3.4 Reactive Auth State Provider**:
   - Created [lib/features/auth/presentation/providers/auth_state_provider.dart](file:///c:/src/expense_tracker/lib/features/auth/presentation/providers/auth_state_provider.dart) exposing sealed `AuthState` (`AuthLoading`, `AuthUnauthenticated`, `AuthAuthenticated`).
   - Implemented `authStateProvider` using `StreamProvider` emitting initial `currentUser` immediately and listening to subsequent stream changes.
   - Authored unit tests in [test/features/auth/presentation/auth_state_provider_test.dart](file:///c:/src/expense_tracker/test/features/auth/presentation/auth_state_provider_test.dart).
5. [x] **3.5 Auth Controller & UI Screens**:
   - Created [lib/features/auth/presentation/providers/auth_controller.dart](file:///c:/src/expense_tracker/lib/features/auth/presentation/providers/auth_controller.dart) with `AsyncNotifier<void>` handling loading spinners, execution guards, and error messages.
   - Implemented [SplashScreen](file:///c:/src/expense_tracker/lib/features/auth/presentation/screens/splash_screen.dart).
   - Implemented [LoginScreen](file:///c:/src/expense_tracker/lib/features/auth/presentation/screens/login_screen.dart) with validation and async submission.
   - Implemented [SignupScreen](file:///c:/src/expense_tracker/lib/features/auth/presentation/screens/signup_screen.dart) with password matching validation.
   - Implemented [ForgotPasswordScreen](file:///c:/src/expense_tracker/lib/features/auth/presentation/screens/forgot_password_screen.dart) with reset link dispatch.
6. [x] **3.6 GoRouter Auth Guard & Route Protection**:
   - Created [lib/app/auth_router_refresh_notifier.dart](file:///c:/src/expense_tracker/lib/app/auth_router_refresh_notifier.dart).
   - Restructured [lib/app/router.dart](file:///c:/src/expense_tracker/lib/app/router.dart) with `routerProvider` enforcing redirect guards:
     - Unauthenticated $\rightarrow$ `/login` (from protected routes or `/splash`).
     - Authenticated $\rightarrow$ `/` (from auth/splash pages).
     - Loading $\rightarrow$ `/splash`.
   - Updated [lib/app/app.dart](file:///c:/src/expense_tracker/lib/app/app.dart) to reactively consume `routerProvider`.
   - Added Logout button to [lib/features/profile/presentation/profile_screen.dart](file:///c:/src/expense_tracker/lib/features/profile/presentation/profile_screen.dart).
7. [x] **3.7 Verification & Testing**:
   - Updated [test/widget_test.dart](file:///c:/src/expense_tracker/test/widget_test.dart) testing unauthenticated login redirect and authenticated Dashboard shell.
   - Verified via `flutter test` (**All 12 tests passed!**).
   - Verified via `flutter analyze` (**0 issues found!**).
   - Verified build via `flutter build apk --debug` (**Built successfully**).

---

## 💳 Phase 4: Core Financial Models, Repositories & Business Logic ✅ COMPLETE

**Goal:** Build data models, serialization/deserialization, Supabase repository services, and Riverpod state controllers for profiles, accounts, categories, and transactions.

### Completed Tasks:
1. [x] **4.1 Dart Domain Models**: `UserProfile`, `AccountModel` (id, userId, name, type, icon, color, isActive, openingBalance), `CategoryModel`, `TransactionModel` (transaction_date, description, paymentMethod), `TransactionType` (`EXPENSE`/`CREDIT`).
2. [x] **4.2 ProfileRepository**: `getCurrentProfile()`, `updateProfile({fullName, avatarUrl, currencyCode, currencySymbol})`.
3. [x] **4.3 AccountRepository**: `getAccounts(activeOnly)`, `getAccount(id)`, `createAccount({name, type, icon, color, openingBalance})`, `updateAccount(...)`, `deleteAccount()` (soft-delete).
4. [x] **4.4 CategoryRepository**: `getCategories(type?)`, `getCategory(id)`, `createCategory(...)`, `updateCategory(...)`, `deleteCategory()` (soft-delete). System + user-owned categories.
5. [x] **4.5 TransactionRepository**: `getTransactions(filter)`, `getTransaction(id)`, `createTransaction(...)`, `updateTransaction(...)`, `deleteTransaction()` (soft-delete), `sumByType(type, accountId?, from?, to?)`.
6. [x] **4.6 FinancialCalculationService**: `getAccountBalance(accountId)`, `getOverallSummary(from?, to?)`, `getCurrentMonthSummary()`. Balance = `Σ(CREDIT) - Σ(EXPENSE)` from transactions.
7. [x] **4.7 Riverpod Data Providers**: `accountsProvider`, `accountBalanceProvider`, `financialCalculationServiceProvider`, `categoriesProvider`, `expenseCategoriesProvider`, `incomeCategoriesProvider`, `transactionsProvider`, `allTransactionsProvider`, `overallSummaryProvider`, `currentMonthSummaryProvider`.
8. [x] **4.8 Unit Tests**: 60 tests covering `TransactionFilter`, `FinancialCalculationService` (fake repo, no Supabase), `AccountRepository` serialization, `CategoryRepository` serialization, `TransactionRepository` DB column contract. Total: **91/91 passing**.
9. [x] **4.9 Migration 002**: `ADD COLUMN icon TEXT` + `ADD COLUMN color TEXT` on `accounts` table. Pushed to Supabase remote.

---

## 📱 Phase 5: Core UI & Transaction Management (MVP) ✅ COMPLETE

**Goal:** Build the primary screens enabling users to view summaries, log income/expenses, view transaction history, edit/delete records, and manage accounts and categories.

### Key Tasks & Deliverables:
- [x] **5.1 Authenticated App Shell**:
  - `AppShell` with `StatefulNavigationShell`, Material 3 `NavigationBar` (Home, Transactions, Reports, Profile), and global `+ Add Transaction` Floating Action Button.
  - Centralized GoRouter routing preserving branch state across tabs (`/`, `/transactions`, `/reports`, `/profile`, `/add-transaction`, `/accounts`, `/categories`).
  - Auth-aware automatic redirect via `authStateProvider`.
  - Comprehensive widget tests in `test/app/app_shell_test.dart`.
- [x] **5.2 Dashboard Screen**:
  - Total Current Balance Card (`Opening Balance + ΣCredits - ΣExpenses`).
  - Income & Expense quick summary cards (Total & This Month).
  - Quick Action Buttons (Add Expense, Add Credit).
  - Recent Transactions list (top 5 with category icon, account, date, amount) & Empty State.
  - Reactive loading, error + retry, and pull-to-refresh.
  - Comprehensive widget tests in `test/features/dashboard/dashboard_screen_test.dart`.
- [x] **5.3 Add Transaction**:
  - Route: `/add-transaction` supporting both Expense and Credit mode with quick toggle.
  - Dynamic category selector filtering by selected transaction type (`EXPENSE` vs `CREDIT`).
  - Active-only account selector with default selection.
  - Date picker defaulting to current date with custom date selection.
  - Numeric amount field with regex formatters and positive amount validation.
  - Optional payment method and description fields.
  - Prevents duplicate submissions while saving and preserves input on error.
  - Comprehensive widget tests in `test/features/transactions/presentation/add_transaction_screen_test.dart`.
- [x] **5.4 Transaction History**:
  - Route: `/transactions` displaying all transactions newest first.
  - Chronological date grouping (e.g. `TODAY`, `YESTERDAY`, formatted dates).
  - Live search filtering by note/description.
  - Type filter chips (`All`, `Expense`, `Credit`).
  - Account and Category dropdown filters with `TransactionFilter`.
  - Pull-to-refresh, empty state, and error with retry action.
  - Tap transaction card to open Edit flow.
  - Comprehensive widget tests in `test/features/transactions/presentation/transactions_screen_test.dart`.
- [x] **5.5 Edit & Delete Transactions**:
  - Reuses `AddTransactionScreen` pre-filling amount, type, category, account, date, and description.
  - Updates records through `TransactionRepository.updateTransaction()`.
  - Soft-delete with confirmation dialog via `TransactionRepository.deleteTransaction()`.
  - Invalidates financial summaries, account balances, and transaction lists upon mutation.
  - Comprehensive widget tests in `test/features/transactions/presentation/add_transaction_screen_test.dart`.
- [x] **5.6 Accounts & Categories UI**:
  - Route `/accounts`: Displays active/inactive accounts, calculated dynamic balances, add account bottom sheet, edit account, and soft-delete/deactivation.
  - Route `/categories`: Displays tabbed Expense and Credit lists, system-seeded category protections (cannot edit/delete system categories), add custom category bottom sheet, edit category, and soft-delete.
  - Accessible via Profile & Settings (`/profile`) navigation tiles.
  - Comprehensive widget tests in `test/features/accounts/presentation/accounts_screen_test.dart` and `test/features/categories/presentation/categories_screen_test.dart`.
- [x] **5.7 Full Phase 5 Integration & Verification**:
  - 100% end-to-end data propagation from Add/Edit/Delete $\rightarrow$ Riverpod invalidations $\rightarrow$ Dashboard & History updates.
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **121/121 passing tests**.

---

## 📈 Phase 6: Analytics, Charts & Reports

**Goal:** Visualize financial health and category distributions using interactive charts.

### Key Tasks:
- [ ] **6.1 Spending Breakdown (Category Pie/Donut Chart)**:
  - Interactive donut chart powered by `fl_chart` showing top spending categories.
  - Percentage and total amount breakdown list.
- [ ] **6.2 Income vs. Expense Trends**:
  - Monthly bar or line chart comparing cash flow trends over time.
- [ ] **6.3 Account-wise Insights**:
  - Balances broken down per payment source (Bank vs. UPI vs. Cash).

---

## 🛡️ Phase 7: Security, Error Handling & Quality Assurance

**Goal:** Ensure data integrity, test cross-user isolation, handle network disconnections gracefully, and achieve robust test coverage.

### Key Tasks:
- [ ] **7.1 Security & RLS Validation**:
  - Test multi-user isolation (Verify User A cannot query or alter User B data).
  - Validate sanitization and input restrictions.
- [ ] **7.2 Offline & Network Error Handling**:
  - Graceful connection error states and snackbar toasts.
  - Form validation for negative or zero amounts.
- [ ] **7.3 Testing**:
  - Unit tests for financial balance calculators and formatters.
  - Widget tests for transaction forms and custom buttons.
  - Emulator & physical device verification on Android.

---

## 📦 Phase 8: Android Packaging & Google Play Store Preparation

**Goal:** Prepare the production release build, configure app branding, and create distribution artifacts.

### Key Tasks:
- [ ] **8.1 App Branding**:
  - App launcher icon (`flutter_launcher_icons`).
  - Native splash screen (`flutter_native_splash`).
  - App display name and package identifier (`com.yourname.expensetracker`).
- [ ] **8.2 Release Signing**:
  - Generate upload keystore (`upload-keystore.jks`).
  - Configure `key.properties` and `app/build.gradle`.
- [ ] **8.3 Production Build**:
  - Generate optimized Android App Bundle (`flutter build appbundle --release`).
- [ ] **8.4 Play Store Assets**:
  - Privacy policy document.
  - Store listing description, screenshots, and feature graphic.

---

## 📅 Suggested Immediate Action
Begin with **Phase 4 (Core Financial Models, Repositories & Business Logic)**: implement `UserProfile`, `AccountModel`, `CategoryModel`, `TransactionModel`, and their respective Supabase repository services.

---

## 🚀 Phase 6: Analytics, Charts & Reports (Milestone 6) ✅ COMPLETE

**Goal:** Build a production-quality financial Reports/Analytics module on top of the existing Riverpod/Supabase architecture without creating a second data system.

### Architecture

```
SUPABASE
    ↓
TransactionRepository (existing — getTransactions with soft-delete fix)
    ↓ (one filtered fetch per report view)
reportTransactionsProvider
    ↓
ReportsAnalyticsService.compute()  ← pure Dart, no async
    ↓
FinancialReport (single aggregated model)
    ↓
financialReportProvider
    ↓
ReportsScreen
    ├── PeriodSelector
    ├── FinancialOverviewCard
    ├── IncomeExpenseChart (fl_chart LineChart)
    ├── ExpensePieChart (fl_chart PieChart)
    ├── CategoryBreakdown (expense + credit)
    ├── AccountBreakdown
    └── StatisticsCard (expense + credit)
```

### 6.1 Soft-Delete Fix
`TransactionRepository.getTransactions()` was missing a `deleted_at IS NULL` filter. Fixed by adding `.isFilter('deleted_at', null)` to the Supabase query chain — consistent with how `sumByType()` already worked.

### 6.2 Domain Models Created
- `report_period.dart` — `ReportPeriod` enum with `dateRange()` and `defaultGranularity`
- `report_granularity.dart` — `ReportGranularity` enum (daily/weekly/monthly)
- `category_expense_summary.dart` — per-category aggregation
- `account_summary.dart` — per-account aggregation
- `trend_point.dart` — time-series bucket
- `financial_report.dart` — single aggregated result consumed by all widgets

### 6.3 Analytics Service
`ReportsAnalyticsService.compute()`:
- Input: `List<TransactionModel>` (pre-filtered)
- Output: `FinancialReport` with all aggregations in memory
- No NaN, no Infinity, no division-by-zero
- Category % clamped to 0–100

### 6.4 Providers
- `reportFilterProvider` — `StateNotifierProvider<ReportFilterNotifier, ReportFilter>`
  - Presets: thisWeek / thisMonth / lastMonth / last3Months / thisYear
  - Custom range via `setCustomRange()` (rejects start > end)
- `reportTransactionsProvider` — ONE `FutureProvider` fetching from repo
- `_categoryNameMapProvider` / `_accountNameMapProvider` — name resolution
- `financialReportProvider` — derives `FinancialReport` from single dataset

### 6.5 Filter Presets
| Preset | Start | Granularity |
|--------|-------|-------------|
| This Week | Most recent Monday | Daily |
| This Month | First of current month | Daily |
| Last Month | First of previous month | Daily |
| Last 3 Months | 2 months back | Weekly |
| This Year | Jan 1 current year | Monthly |
| Custom | User-picked | Auto (≤31d→daily, ≤90d→weekly, else monthly) |

### 6.6 Charts (fl_chart ^0.70.2)
- `IncomeExpenseChart`: LineChart, credits vs expenses, tooltips, empty state
- `ExpensePieChart`: PieChart, touch-to-select, legend, top-6 + Others, empty state

### 6.7 UI States
- Loading: shimmer placeholder blocks
- Error: message + Retry button (invalidates provider)
- Empty: icon + message with guidance
- Pull-to-refresh: `RefreshIndicator` → invalidates `reportTransactionsProvider`

### 6.8 Tests Added
- `reports_analytics_service_test.dart` — ~40 domain tests
- `report_period_test.dart` — date range + filter + notifier tests
- `soft_delete_regression_test.dart` — regression for the soft-delete fix
- `reports_screen_test.dart` — widget tests for all UI states

### 6.9 Known Limitations
- Reports make one Supabase query per page load (correct per spec)
- Trend chart shows only dates with transactions (no zero-fill for empty days)

---

## 🎯 Phase 7: Budgets & Spending Limits ✅ COMPLETE

**Goal:** Provide comprehensive budget tracking for overall monthly spending and category-specific limits. Calculate all spending dynamically from actual transactions without storing a separate manually updated `spent` column.

### 7.1 Architecture & Core Principles
- **Dynamic Transaction-Derived Calculation**: `TransactionRepository.sumByType(type: expense, categoryId: ..., from: startDate, to: endDate)`
- **Budget Scope**: Overall Budget (`category_id = null`) or Category Budget (`category_id != null`).
- **Periods**: `MONTHLY` (calendar month), `WEEKLY` (calendar week), `CUSTOM` (arbitrary date range).
- **Alert States**:
  - Normal: `< alert_threshold` (e.g. 0% - 79%)
  - Warning: `≥ alert_threshold` and `≤ 100%` (e.g. 80% - 100%)
  - Over Budget: `> 100%` with remaining deficit calculation.

### 7.2 Deliverables Checklist
1. [x] **7.2.1 Database Migration**: `20260921000000_003_budgets_schema.sql` applied with RLS, audit trigger `handle_base_audit_fields()`, and category foreign keys.
2. [x] **7.2.2 Domain Models & Calculation Service**:
   - `BudgetPeriod` enum (weekly, monthly, custom) with range calculations.
   - `BudgetModel` entity (immutable with serialization).
   - `BudgetProgress` model (progress percentage, remaining, status).
   - `BudgetCalculationService` computing metrics from `TransactionRepository`.
3. [x] **7.2.3 Data Repository**: `BudgetRepository` CRUD operations in Supabase.
4. [x] **7.2.4 Riverpod State Management**: `budgetRepositoryProvider`, `budgetsListProvider`, `activeBudgetsProgressProvider`, `budgetControllerProvider`.
5. [x] **7.2.5 UI & Widgets**:
   - `BudgetsScreen`: Overview banner, progress bars, threshold markers, over-budget warnings, active/all filters.
   - `AddEditBudgetSheet`: Modal form for configuring budget name, scope, category, period, amount, and alert threshold.
   - `BudgetCard`: Animated progress indicators and status badges.
   - `DashboardBudgetCard`: Dashboard widget integration.
6. [x] **7.2.6 Routing & Profile Integration**:
   - Registered `/budgets` route in GoRouter.
   - Added Budgets tile in Profile screen under Data Management.
7. [x] **7.2.7 Automated Tests & Verification**:
   - Unit tests for models, calculation service, repository.
   - Widget tests for screens and bottom sheet.
   - Verified `flutter analyze` clean (0 issues) and `214/214` test suite passing.

---

## 🔁 Phase 8: Recurring Transactions ✅ COMPLETE

**Goal:** Automate recurring financial commitments (subscriptions, rent, utilities, insurance, EMIs, salaries) with a deterministic scheduling engine, maintaining a strict architectural separation between **Recurring Templates** and **Generated Ledger Transactions**.

### 8.1 Core Principles & Architecture
- **Recurring Template $\neq$ Transaction**: Templates define recurrence rules and advance in time, while each generated execution becomes an immutable row in the `transactions` table.
- **Drift-Free Scheduling Engine**: `RecurringFrequency` computes next occurrences (Daily, Weekly, Monthly, Yearly) with month-end day clamping (Jan 31 $\to$ Feb 28/29 $\to$ Mar 31).
- **Auto vs. Manual Recording**:
  - **Auto-Create (`auto_create = true`)**: Automatically logs due items into the transaction ledger upon trigger.
  - **Manual Record Now**: User can review and record individual occurrences on demand with one click.
- **Commitments Overview**: Aggregates estimated monthly recurring expenses and income without querying historical logs.

### 8.2 Deliverables Checklist
1. [x] **8.2.1 Database Schema & Migration**:
   - Migration `20260921000004_004_recurring_transactions_schema.sql` applied to remote Supabase DB.
   - Created `recurring_transactions` table with RLS (`auth.uid() = user_id`), `handle_base_audit_fields()`, and soft delete support.
2. [x] **8.2.2 Domain Models & Scheduling Service**:
   - `RecurringFrequency` enum with next-occurrence calculations and month-end clamping.
   - `RecurringTransactionModel` entity with full JSON/PostgreSQL serialization and `isDue` evaluation.
   - `RecurringScheduleService` discovering due/upcoming payments and generating ledger transactions.
3. [x] **8.2.3 Data Layer**: `RecurringRepository` supporting CRUD, soft delete, and `advanceNextOccurrence`.
4. [x] **8.2.4 Riverpod State Management**:
   - `recurringRepositoryProvider`, `allRecurringTransactionsProvider`, `activeRecurringTransactionsProvider`, `upcomingRecurringProvider`, and `recurringControllerProvider`.
5. [x] **8.2.5 UI & Widget Components**:
   - `RecurringTransactionsScreen`: Filter tabs (Active, Paused, All), Monthly Commitments Banner, Pull-to-Refresh, and Delete Confirmation.
   - `AddEditRecurringSheet`: Form for Type, Frequency, Amount, Description, Account, Category, Start Date, Next Date, End Date, and Auto-Create toggle.
   - `RecurringTransactionCard`: Frequency badges, due status indicators, quick "Record Now" button, and options menu.
   - `DashboardUpcomingPaymentsCard`: Integrated into `DashboardScreen` displaying upcoming bills and 30-day horizon summary.
6. [x] **8.2.6 Navigation & Profile Integration**:
   - Added `/recurring` route in GoRouter.
   - Added Recurring Schedules entry in `ProfileScreen` under Data Management.
7. [x] **8.2.7 Comprehensive Testing & Analysis**:
   - 237/237 tests passing (0 failures, 0 regressions).
   - `flutter analyze`: 0 errors, 0 warnings.

---

## 🔔 Phase 9: Smart Financial Notifications ✅ COMPLETE

**Goal:** Deliver proactive, intelligent financial alerts and reminders (budget thresholds, upcoming recurring bills, auto-recorded transactions, spending surge warnings) driven by pure domain rules with complete user preference toggles.

### 9.1 Core Principles & Architecture
- **Strict Separation of Concerns**: `SmartAlertEngine` does NOT recalculate finance or schedule logic. It consumes `BudgetProgress` from `BudgetCalculationService`, `RecurringTransactionModel` from `RecurringScheduleService`, and `FinancialSummary` from `FinancialCalculationService`.
- **Dynamic Alert Generation**: Alerts are produced deterministically based on live financial state and filtered by `NotificationSettingsModel`.
- **Persistent Notifications & Status**: Notifications can be marked as read, cleared, or deleted.
- **Interactive Notification Actions**: Tapping a notification navigates directly to the relevant screen (e.g. `/budgets`, `/recurring`, `/transactions`).

### 9.2 Deliverables Checklist
1. [x] **9.2.1 Database Schema & Migration**:
   - Migration `20260922000000_005_notifications_schema.sql` applied to remote Supabase DB.
   - Created `notifications` table (`id`, `user_id`, `type`, `title`, `message`, `data`, `is_read`, `read_at`, `created_at`, `deleted_at`) with RLS (`auth.uid() = user_id`) and `handle_base_audit_fields()`.
   - Created `notification_settings` table (`user_id`, `budget_alerts_enabled`, `recurring_reminders_enabled`, `daily_summary_enabled`, `spending_surge_enabled`, `created_at`, `updated_at`) with RLS.
2. [x] **9.2.2 Domain Models & Smart Alert Engine**:
   - `NotificationType` enum with icons, colors, and display labels.
   - `NotificationModel` entity with JSON serialization, `copyWith`, and `markAsRead`.
   - `NotificationSettingsModel` entity for user notification preferences.
   - `SmartAlertEngine` evaluating budget warning/over-budget states, recurring reminders, auto-created notifications, and spending surges.
3. [x] **9.2.3 Data Repositories**:
   - `NotificationRepository` (getNotifications, markAsRead, markAllAsRead, deleteNotification, clearAll).
   - `NotificationSettingsRepository` (getSettings, updateSettings).
4. [x] **9.2.4 Riverpod State Management**:
   - `notificationRepositoryProvider`, `notificationSettingsRepositoryProvider`.
   - `notificationsListProvider`, `unreadNotificationCountProvider`, `notificationSettingsProvider`.
   - `notificationsControllerProvider`.
5. [x] **9.2.5 UI & Widgets**:
   - `NotificationsScreen`: Filter tabs (All, Unread), swipe-to-dismiss, mark-all-as-read, empty state, and deep link navigation.
   - `NotificationSettingsScreen`: Toggle switches for Budget Alerts, Recurring Reminders, Daily Summaries, and Spending Surge alerts.
   - `NotificationCard`: Type-based icon container, semantic badge colors, relative timestamp, read/unread status dot.
   - `NotificationBadgeIcon`: Dashboard app bar bell icon with live unread count badge.
6. [x] **9.2.6 Routing & Integration**:
   - Registered `/notifications` and `/notification-settings` routes in GoRouter.
   - Added Notifications tile and badge in `ProfileScreen` and bell icon in `DashboardScreen`.
7. [x] **9.2.7 Automated Tests & Verification**:
   - Unit tests for models, types, settings, and `SmartAlertEngine`.
   - Widget tests for `NotificationsScreen`, `NotificationSettingsScreen`, and `NotificationBadgeIcon`.
   - 260/260 tests passing (0 failures, 0 regressions).
   - `flutter analyze`: 0 errors, 0 warnings.

---

## 💰 Phase 10: Savings Goals (Next)

**Goal:** Help users define, allocate money toward, and track progress for structured financial savings goals (e.g., Emergency Fund, Vacation, New Vehicle, Tech Upgrade).

### Key Focus Areas:
- **Goal Scope**: Target amount, target date, priority level, visual icon/color.
- **Contribution Flow**: Allocate money from accounts into specific goal buckets with visual celebration animations.
- **Projected Timeline**: Calculation of required monthly/weekly contribution to hit target by deadline.



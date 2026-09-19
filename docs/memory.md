# Project Memory & Progress Log

**Project:** Personal Expense & Finance Management App  
**Platform:** Flutter / Android (Google Play Store)  
**Database & Auth:** Supabase + PostgreSQL (RLS)  
**Initialized:** September 19, 2026  

---

## 📌 Active Architecture & Technical Decisions

- **State Management:** Flutter Riverpod
- **Routing:** GoRouter (declarative routing with auth state guards)
- **Database:** Supabase PostgreSQL with strict Row Level Security (RLS)
- **Primary Database Choice:** Supabase PostgreSQL (Google Sheets will *not* be used as primary database)
- **Data Isolation:** `auth.uid() = user_id` on all tables (`profiles`, `accounts`, `categories`, `transactions`)
- **Design Principles:** Mobile-first, Dark/Light mode, Google Fonts, vibrant Income (green) vs. Expense (red/orange) aesthetics, `fl_chart` visualizations

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

---

## 🎯 Next Immediate Milestones (Milestone 3 — Authentication & Session Management)

- [ ] **3.1 Auth Repository & Services**: Implement Supabase Auth methods (SignUp, Login, Logout, ResetPassword, Session listener).
- [ ] **3.2 Auth State Provider**: Riverpod AsyncNotifier managing user session state (`authenticated`, `unauthenticated`, `loading`).
- [ ] **3.3 Auth Screens & UI**: Build Splash screen, Login screen, Sign-up screen, and Forgot Password screen.
- [ ] **3.4 GoRouter Auth Guard**: Configure reactive redirection in `app_router.dart` (redirect unauthenticated users to `/login` and authenticated users to `/`).

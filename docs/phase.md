# Personal Expense Tracker --- Project Implementation Phases & Roadmap

This document outlines the step-by-step development phases, milestones, deliverables, and checklists for building the **Personal Expense & Finance Management App** based on the [BRD (Business Requirements Document)](file:///c:/src/expense_tracker/docs/Expense_Tracker_BRD.md).

---

## 📊 Overall Progress & Milestones

- [x] **Milestone 0: Environment Setup & Toolchain** (100%)
- [ ] **Milestone 1: Flutter Foundation & Architecture Setup** (0%)
- [ ] **Milestone 2: Supabase Backend & Database Schema with RLS** (0%)
- [ ] **Milestone 3: Authentication & Session Management** (0%)
- [ ] **Milestone 4: Core Data Layer, Models & Repositories** (0%)
- [ ] **Milestone 5: Core UI & State Management (MVP)** (0%)
- [ ] **Milestone 6: Analytics, Charts & Reports** (0%)
- [ ] **Milestone 7: Security, Testing & Edge-Case Validation** (0%)
- [ ] **Milestone 8: Production Polish & Google Play Store Release** (0%)

---

## 🚀 Phase 1: Flutter Foundation & Architecture Setup (Milestone 1)

**Goal:** Establish a solid technical baseline: configure folder structure, define premium design system & theme tokens, configure GoRouter navigation, and initialize Riverpod state management foundation.

### Deliberate Step-by-Step Sequence:
1. [x] **1.1 Folder Structure & Architecture Layout**:
   - Scaffolded `lib/app/`, `lib/core/`, and `lib/features/` modular directories.
   - Cleaned up initial layout.
2. [x] **1.2 Core Dependencies & Configuration (`pubspec.yaml`)**:
   - State Management: `flutter_riverpod` (^2.6.1)
   - Navigation: `go_router` (^16.2.1)
   - Typography & Icons: `google_fonts` (^6.3.2), `lucide_icons` (^0.257.0)
   - Utilities & Storage: `intl` (^0.20.2), `flutter_secure_storage` (^9.2.4)
   - Verified via `flutter pub get` and `flutter analyze` (0 issues).
3. [ ] **1.3 Design System & Theme Foundation**:
   - `core/constants/app_colors.dart` (Semantic Green for Credit, Coral/Red for Expense, Dark/Light palettes, modern surface tokens).
   - `core/constants/app_typography.dart` (Clean Google Fonts styles - e.g. Inter / Plus Jakarta Sans).
   - `core/theme/app_theme.dart` (Light & Dark theme data with custom card, button, and input decorations).
   - `core/widgets/` (Foundational atomic widgets: `AppCard`, `AppButton`, `AmountDisplay`).
4. **1.4 Declarative Navigation & Shell (`go_router`)**:
   - `app/app_router.dart`: Set up initial routes (`/splash`, `/login`, `/dashboard`, `/transactions`, `/reports`, `/profile`).
   - Stateful shell route for bottom navigation bar.
5. **1.5 Riverpod State Management Baseline**:
   - `app/app.dart`: Wrap root with `ProviderScope`.
   - Setup global providers for theme mode (Dark/Light) and basic app lifecycle state.

---

## 🗄️ Phase 2: Supabase Backend, Database Schema & RLS

**Goal:** Create and configure the Supabase project, execute PostgreSQL schema migrations, establish Row Level Security (RLS) policies, and prepare database triggers.

### Key Tasks:
- [ ] **2.1 Supabase Configuration**:
  - Configure Supabase URL & Anon Key securely via environment configs (`.env` or dart defines).
  - Initialize Supabase in `main.dart`.
- [ ] **2.2 PostgreSQL Schema Execution**:
  - `profiles` table (linked to `auth.users` via trigger on sign-up).
  - `accounts` table (`id`, `user_id`, `name`, `type`, `opening_balance`, `is_active`).
  - `categories` table (`id`, `user_id`, `name`, `type` [`EXPENSE`|`CREDIT`], `icon`, `color`, `is_active`).
  - `transactions` table (`id`, `user_id`, `account_id`, `category_id`, `type`, `amount`, `description`, `transaction_date`, `payment_method`).
- [ ] **2.3 Row Level Security (RLS) Policies**:
  - Restrict `SELECT`, `INSERT`, `UPDATE`, `DELETE` to authenticated user matching `auth.uid() = user_id`.
- [ ] **2.4 Default Data Seed**:
  - Seed default categories on user profile creation (Food, Shopping, Travel, Bills, Rent, Salary, Freelance, etc.).
  - Seed default account (Cash / Primary Bank).

---

## 🔐 Phase 3: Authentication & Onboarding Flow

**Goal:** Implement full Supabase Auth integration with reactive routing and auto-redirection based on auth state.

### Key Tasks:
- [ ] **3.1 Splash Screen & Auth State Listener**:
  - Splash screen checking current session token validity.
  - Reactive redirect with `go_router` (`/splash` -> `/login` or `/dashboard`).
- [ ] **3.2 Authentication UI & Logic**:
  - Sign-up Screen (Full Name, Email, Password, Currency selection).
  - Login Screen (Email, Password, Remember Me).
  - Password Reset / Forgot Password flow.
  - Logout confirmation and session purge.
- [ ] **3.3 Profile Management**:
  - View & edit profile details.
  - Manage display currency (₹, $, €, etc.).

---

## 💳 Phase 4: Core Financial Models, Repositories & Business Logic

**Goal:** Build data models, serialization/deserialization, Supabase repository services, and Riverpod state controllers.

### Key Tasks:
- [ ] **4.1 Dart Models**:
  - `UserProfile`, `AccountModel`, `CategoryModel`, `TransactionModel`.
- [ ] **4.2 Repositories**:
  - `AuthRepository`: Supabase auth methods.
  - `AccountRepository`: CRUD for accounts and balances.
  - `CategoryRepository`: Fetch active expense/credit categories.
  - `TransactionRepository`: Add/Edit/Delete transactions, filter queries, pagination.
- [ ] **4.3 Financial Calculation Logic**:
  - Real-time balance calculator: `Opening Balance + Total Credits - Total Expenses`.
  - Monthly credits vs. monthly expenses aggregation.

---

## 📱 Phase 5: Core UI & Transaction Management (MVP)

**Goal:** Build the primary screens enabling users to view summaries, log income/expenses, and view transaction history.

### Key Tasks:
- [ ] **5.1 Bottom Navigation Shell**:
  - Tabs: **Home (Dashboard)** | **Transactions** | **Reports** | **Profile**.
  - Prominent Floating Action Button (`+ Add Transaction`).
- [ ] **5.2 Dashboard Screen**:
  - Total Current Balance Card.
  - Income & Expense quick summary pill cards.
  - Recent Transactions list with tap-to-view details.
  - Quick action buttons (Add Expense, Add Income).
- [ ] **5.3 Add / Edit Transaction Flow**:
  - Seamless toggle between **Expense (-)** and **Credit (+)**.
  - Large numeric keypad / amount input field.
  - Category selector with visual icons and colors.
  - Account/Payment source selector (Cash, UPI, Bank).
  - Date & Time picker (defaults to now).
  - Optional note / description input.
- [ ] **5.4 Transactions History Screen**:
  - Chronological grouped list (Today, Yesterday, This Month).
  - Search bar (by description or category).
  - Filter drawer/chips (Filter by Month/Year, Type, Category, Account).
  - Swipe-to-delete or tap-to-edit action.

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
Begin with **Phase 1 (Flutter Architecture & Dependencies Setup)** followed by **Phase 2 (Supabase Project & SQL Schema)** to lay the technical bedrock before screen development.

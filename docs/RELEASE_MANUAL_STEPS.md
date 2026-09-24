# Android & Google Play Release Guide & Checklist

This document details all external console actions, human-owned credentials, store listings, and configuration required to launch **Expense Tracker & Business Khata** on the **Google Play Store**.

---

## 1. Google Play Store Listing Copy & Metadata

### App Details
- **App Name**: `Expense Tracker & Khata Book` (30 characters max)
- **Short Description**: (80 characters max)
  ```text
  Track daily personal expenses, budgets, savings, loans, and business khata.
  ```
- **Full Description**:
  ```text
  Take full control of your personal finances and business customer ledgers with Expense Tracker & Khata Book.

  KEY FEATURES:
  • Personal Expense & Income Tracking: Effortlessly log daily transactions with accounts and categories.
  • Business Khata (Customer Ledger): Manage customer credit (Given) and debit (Received) with dynamic real-time balances, statement generation, and PDF export.
  • Budget Management: Set monthly and categorical spending limits to avoid overspending.
  • Savings Goals: Plan, track contributions, and reach your financial goals.
  • Debt & Loan Tracker: Manage borrowings, repayments, installments, and interest calculation.
  • Recurring Payments: Set automated reminders and transaction templates for subscriptions and recurring bills.
  • Customizable Dashboard: Arrange your widgets to prioritize the financial data most important to you.
  • Detailed Reports & Export: Generate clean visual reports, filter by dates, and export statements to CSV and PDF.
  • Privacy-First & Secure: Your data is protected with enterprise-grade Row-Level Security (RLS) and encrypted cloud synchronization.
  ```

### Graphical Assets Requirements
- **App Icon**: 512 x 512 px, 32-bit PNG with alpha channel (Max 1MB).
- **Feature Graphic**: 1024 x 500 px, JPG or 24-bit PNG (No alpha, max 15MB).
- **Screenshots**: At least 4 phone screenshots (16:9 or 18:9 aspect ratio, minimum 1080px).

---

## 2. Google Play Console Setup & Declarations

### A. App Access (Demo / Reviewer Account)
If Google Play Reviewers require login credentials to review the app:
- **Username / Email**: `reviewer@expensetracker.app` (or create a dedicated test account in Supabase)
- **Password**: `TestPassword123!`
- **Notes for Reviewer**: "Self-registration is enabled via the sign-up screen, or use the provided credentials to inspect all personal finance and business khata features."

### B. Ads Declaration
- Select: **"No, my app does not contain ads"**.

### C. Content Rating Questionnaire
- Category: **Utility, Productivity, Finance**.
- Violence, Sexual Content, Offensive Language, Controlled Substances: **None / No**.
- Rating Result: **PEGI 3 / ESRB Everyone / General Audience**.

### D. Target Audience and Content
- Target Age Group: **18 and over**.
- Appeal to Children: **No**.

### E. Data Safety Form Responses
- **Does your app collect or share user data?**: **Yes**.
- **Is all user data encrypted in transit?**: **Yes** (TLS 1.3 / HTTPS to Supabase).
- **Do you provide a way for users to request that their data be deleted?**: **Yes** (Both within the app via Profile -> Delete Account and via the public web URL).
- **Data Types Collected**:
  1. **Personal Info**:
     - *Name, Email Address* (Collected for App Functionality, Account Management; Linked to User; Not used for Tracking).
  2. **Financial Info**:
     - *User Payment Info / Transaction History* (Transactions, accounts, balances, khata entries; Collected for Core App Functionality; Linked to User; Not shared with third parties).
  3. **Contacts (Khata)**:
     - *Customer Names & Phone numbers manually entered by user for ledger bookkeeping* (Collected for App Functionality; Linked to User; Not synced from phone contact book).

### F. Privacy Policy & Account Deletion URLs
- **Privacy Policy URL**: `https://yourdomain.com/privacy-policy` (Configure in `AppConfig.privacyPolicyUrl`)
- **Account Deletion URL**: `https://yourdomain.com/delete-account` (Configure in `AppConfig.accountDeletionUrl`)
- **Support Email**: `support@yourdomain.com` (Configure in `AppConfig.supportEmail`)

---

## 3. Android Release Signing Setup

1. **Generate your Upload Keystore** (Run in terminal):
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Create `android/key.properties`** (This file is git-ignored):
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
3. **Build the Signed Release App Bundle**:
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

4. **Google Play App Signing**:
   - Opt in to Google Play App Signing in Google Play Console (Release > Setup > App Integrity). Google will manage the app signing key while you use your upload key.

---

## 4. Production Database & Backend Migration

Execute all SQL migrations in order on the production Supabase PostgreSQL instance:
1. `supabase/migrations/20260919000000_001_initial_schema.sql`
2. `supabase/migrations/20260920000000_002_budgets_schema.sql`
3. `supabase/migrations/20260921000000_003_recurring_transactions.sql`
4. `supabase/migrations/20260922000000_004_notifications_schema.sql`
5. `supabase/migrations/20260923000000_005_savings_goals.sql`
6. `supabase/migrations/20260924000000_006_debt_loan_schema.sql`
7. `supabase/migrations/20260925000000_007_khata_schema.sql`
8. `supabase/migrations/20260926000000_008_audit_soft_delete_hardening.sql`
9. `supabase/migrations/20260927000000_009_account_deletion_and_khata_rpcs.sql`

---

## 5. Google Play Testing Track Deployment

1. **Internal Testing**:
   - Upload `app-release.aab` to Play Console under **Internal Testing**.
   - Add internal tester emails for rapid validation.
2. **Closed Testing** (Required for new personal developer accounts):
   - Recruit at least 12 testers.
   - Run closed test for at least 14 continuous days.
   - Collect opt-ins and feedback before applying for Production access.
3. **Production Track**:
   - Create production release, review roll-out percentage, and submit for Google Play review.

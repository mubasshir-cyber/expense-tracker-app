# 💰 Personal Expense & Finance Tracker

> **A fast, beautiful, and secure mobile application to take full control of your daily money, income, and expenses.**

---

## 🌟 What is this App? (For Everyone)

Have you ever wondered at the end of the month:
* *"Where did my salary go?"*
* *"How much did I actually spend on food or dining out this week?"*
* *"What is my exact total balance across Cash, Bank accounts, and UPI wallets?"*

Most people try to track their money using WhatsApp self-chats, paper notebooks, notes apps, or complicated Excel/Google Sheets. These methods are manual, prone to errors, and difficult to analyze over time.

**Personal Expense Tracker** simplifies this into a clean, pocket-sized mobile experience. It lets you record an expense or income in seconds, organizes your transactions into clear categories, and provides visual charts so you can understand your financial health at a glance.

---

## 👥 True Multi-User System & 100% Data Privacy

This app is built from the ground up as a **secure multi-user platform**:
* **Individual Private Accounts**: Every user signs up with their own email and password.
* **Complete Data Isolation**: Powered by PostgreSQL **Row Level Security (RLS)**, your financial records, balances, income, and categories are strictly isolated. No user can ever see or modify another user's financial data.
* **Cloud Sync**: Your transactions are safely backed up in real time, so switching or resetting your phone will never lose your data.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| ⚡ **Lightning Fast Entry** | Record an expense or credit in under 5 seconds with an ergonomic keypad and instant category selection. |
| 📊 **Interactive Dashboard** | Live total balance card, monthly income vs. expense summary, and quick access to recent transactions. |
| 🏷️ **Smart Categorization** | Pre-built essential categories (Food, Travel, Shopping, Bills, Salary, Freelance) plus the freedom to create custom ones. |
| 💳 **Multi-Account Management** | Track money across various payment sources — Cash, Bank Accounts, UPI, and Digital Wallets. |
| 📈 **Visual Reports & Charts** | Beautiful category distribution donut charts and spending trends to identify saving opportunities. |
| 🔍 **Deep Search & Filters** | Filter transactions by date range, month, transaction type (Income/Expense), category, or payment account. |
| 🌙 **Modern Design & Themes** | Clean Material 3 design system supporting both vibrant Light Mode and battery-saving Dark Mode. |

---

## ⚖️ How We Compare

| Feature | 📱 This App | 📊 Google Sheets / Excel | 📝 WhatsApp / Notes App | 🏦 Heavy Banking Apps |
|---|---|---|---|---|
| **Speed of Entry** | 🟢 **Ultra fast (seconds)** | 🔴 Slow on mobile | 🟡 Fast but unstructured | 🔴 Slow & login-heavy |
| **Visual Charts** | 🟢 **Automatic & interactive** | 🟡 Requires manual setup | 🔴 None | 🟡 Basic / Limited |
| **Balance Calculation** | 🟢 **Automatic per account** | 🟡 Requires formula maintenance | 🔴 Manual calculation | 🟡 Only shows 1 bank |
| **Privacy & Security** | 🟢 **Database-level RLS isolation** | 🟡 Risk of accidental sheet sharing | 🔴 Plaintext / No isolation | 🟢 Bank grade |
| **Multi-User Support** | 🟢 **Built-in multi-tenancy** | 🔴 Complex permissions | 🔴 Not supported | 🔴 Single person only |
| **Mobile Experience** | 🟢 **Native mobile-first UI** | 🔴 Clunky on mobile screens | 🟢 Mobile friendly | 🟡 Heavy and bloated |

---

## 🛠️ Technology Stack

* **Frontend**: [Flutter](https://flutter.dev/) (Dart 3.x)
* **Backend & Database**: [Supabase](https://supabase.com/) (PostgreSQL 15+ with Row Level Security)
* **Authentication**: Supabase Auth (Secure JWT with Android KeyStore storage)
* **State Management**: [Riverpod](https://riverpod.dev/)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)
* **Charts & Data Viz**: [fl_chart](https://pub.dev/packages/fl_chart)
* **Typography & Icons**: Google Fonts (Inter / Plus Jakarta Sans) & Lucide Icons

---

## 📁 Architecture & Documentation

Comprehensive architectural design and engineering documents are available in the [`docs/`](file:///c:/src/expense_tracker/docs/) directory:

* 📄 [**Business Requirements (BRD)**](file:///c:/src/expense_tracker/docs/Expense_Tracker_BRD.md) — Product requirements and MVP scope.
* 📋 [**Implementation Phases & Roadmap**](file:///c:/src/expense_tracker/docs/phase.md) — 8-Phase implementation plan and checklist.
* 🏗️ [**System Architecture**](file:///c:/src/expense_tracker/docs/architecture.md) — Layered feature-first architecture and ER database diagram.
* 🔒 [**Security Architecture**](file:///c:/src/expense_tracker/docs/security.md) — PostgreSQL RLS policies, threat modeling, and encryption.
* 📏 [**Development Rules & Testing Strategy**](file:///c:/src/expense_tracker/docs/rule.md) — Implementation guidelines, feature boundaries, and testing pyramid.
* 🧠 [**Project Memory & Changelog**](file:///c:/src/expense_tracker/docs/memory.md) — Chronological progress tracker.

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.47.5`)
* [Dart SDK](https://dart.dev/get-dart) (`^3.13.4`)
* Android Studio / Android SDK with Android Emulator

### Installation & Run
1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd expense_tracker
   ```
2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```
3. **Run Code Analysis**:
   ```bash
   flutter analyze
   ```
4. **Launch on Android Emulator / Physical Device**:
   ```bash
   flutter run -d emulator-5554
   ```

---

## 📄 License
This project is proprietary and intended for release on the **Google Play Store**.

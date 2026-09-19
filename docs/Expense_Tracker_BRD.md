# BRD --- Personal Expense & Finance Management App

**Project Type:** Multi-user Android Mobile Application\
**Platform:** Android / Google Play Store\
**Frontend:** Flutter + Dart\
**Backend / Database:** Supabase + PostgreSQL\
**Authentication:** Supabase Auth\
**Authorization / Data Security:** PostgreSQL Row Level Security (RLS)\
**Initial Release:** Android\
**Database Decision:** Supabase PostgreSQL --- Google Sheets will not be
used as the primary database.

------------------------------------------------------------------------

## 1. Project Overview

The application is a lightweight personal finance management application
that allows multiple registered users to record, manage, and analyze
their personal financial transactions.

Each user will have a private financial workspace where they can:

-   Record expenses
-   Record credits / income
-   Track current balance
-   Categorize transactions
-   View transaction history
-   Analyze spending
-   View dashboard statistics
-   Manage categories
-   Manage accounts / payment sources
-   Filter and search transactions

The application is a **multi-user system**. Each user's financial data
must be isolated from every other user's data.

### Core Architecture

``` text
Flutter Mobile App
        |
        v
Supabase Auth
        |
        v
PostgreSQL Database
        |
        v
Row Level Security (RLS)
        |
        v
User's own financial data
```

------------------------------------------------------------------------

# 2. Problem Statement

People commonly record expenses using notes, WhatsApp messages,
spreadsheets, Google Sheets, memory, or multiple finance applications.

This makes it difficult to answer questions such as:

-   How much did I spend this month?
-   Where did my money go?
-   How much did I receive?
-   What is my current balance?
-   How much did I spend on food?
-   What did I spend today or yesterday?
-   How much did I spend through UPI?
-   Which categories consume most of my spending?

The application centralizes these activities into a simple mobile
interface.

------------------------------------------------------------------------

# 3. Project Objectives

## Primary Objectives

1.  Allow users to record expenses quickly.
2.  Allow users to record credits / income.
3.  Maintain an accurate balance.
4.  Categorize transactions.
5.  Provide a financial dashboard.
6.  Provide transaction history.
7.  Provide spending analysis.
8.  Secure each user's financial data.
9.  Support multiple users.
10. Publish the application on Google Play Store.

## Secondary Objectives

-   Make transaction entry fast.
-   Provide useful charts.
-   Keep the UI simple.
-   Keep infrastructure inexpensive.
-   Keep the architecture scalable for future features.

------------------------------------------------------------------------

# 4. Target Users

The primary users are individuals who want to track their personal
finances.

Examples:

-   Employees
-   Students
-   Freelancers
-   Business owners
-   Self-employed users
-   Personal / household users

The first version is **not intended to be a complete accounting or ERP
system**.

------------------------------------------------------------------------

# 5. Application Scope

## 5.1 Authentication

-   Sign up
-   Login
-   Logout
-   Forgot password
-   User profile
-   Session management

## 5.2 Dashboard

-   Current balance
-   Total credits
-   Total expenses
-   Current month expenses
-   Current month credits
-   Recent transactions
-   Category-wise spending
-   Spending chart

## 5.3 Expenses

-   Add expense
-   Edit expense
-   Delete expense
-   Expense category
-   Amount
-   Date
-   Description
-   Payment method
-   Account

## 5.4 Credits / Income

-   Add credit
-   Edit credit
-   Delete credit
-   Credit source
-   Amount
-   Date
-   Description
-   Account

## 5.5 Transactions

-   View all transactions
-   Expense / credit filtering
-   Category filtering
-   Date filtering
-   Account filtering
-   Search
-   Transaction details

## 5.6 Categories

-   Default categories
-   Custom categories
-   Edit category
-   Disable category

## 5.7 Accounts

Users can maintain multiple financial accounts / sources, such as:

-   Cash
-   Bank Account
-   UPI
-   Savings
-   Wallet

## 5.8 Reports

-   Daily spending
-   Weekly spending
-   Monthly spending
-   Category spending
-   Credit vs expense
-   Account-wise transactions

------------------------------------------------------------------------

# 6. Future Scope

These features are not part of the initial MVP unless specifically
approved:

-   Budgets
-   Recurring expenses
-   Recurring income
-   Monthly budget alerts
-   Expense reminders
-   Receipt image upload
-   OCR receipt scanning
-   CSV export
-   PDF export
-   Cloud backup
-   Multiple currencies
-   Family / shared accounts
-   Financial goals
-   Savings tracking
-   Subscription tracking
-   Notifications
-   Advanced analytics
-   AI expense analysis
-   Web dashboard
-   iOS application

------------------------------------------------------------------------

# 7. User Roles

The initial system has one primary role:

``` text
USER
```

Each registered user has their own financial data.

A future version may introduce:

``` text
SUPER ADMIN
    |
    +-- Users
    +-- Categories
    +-- System Settings

USER
    |
    +-- Own Financial Data
```

The first version does not require an administrative dashboard.

------------------------------------------------------------------------

# 8. Multi-User Architecture

User A must never be able to access User B's transactions.

Example:

``` text
User A
 |
 +-- Account A
 +-- Expense A
 +-- Credit A
 +-- Categories A

User B
 |
 +-- Account B
 +-- Expense B
 +-- Credit B
 +-- Categories B
```

The database will enforce this isolation through PostgreSQL Row Level
Security (RLS).

The application must not rely only on Flutter-side filtering for
security.

------------------------------------------------------------------------

# 9. Financial Model

The basic balance calculation is:

``` text
Current Balance
=
Opening Balance
+
Total Credits
-
Total Expenses
```

Example:

``` text
Opening Balance       ₹10,000
Credits                ₹5,000
Expenses               ₹3,500
------------------------------
Current Balance       ₹11,500
```

------------------------------------------------------------------------

# 10. Expense Module

A user selects:

``` text
+ Add Expense
```

### Required Fields

-   Amount
-   Category
-   Date
-   Account

### Optional Fields

-   Description
-   Payment method
-   Notes
-   Receipt

### Example

``` text
Amount: ₹350
Category: Food
Date: 19 September 2026
Account: UPI
Description: Dinner
```

Result:

``` text
Expense
- ₹350
```

------------------------------------------------------------------------

# 11. Credit Module

A user selects:

``` text
+ Add Credit
```

### Fields

-   Amount
-   Source
-   Date
-   Account
-   Description

### Example

``` text
Amount: ₹5,000
Source: Salary
Date: 18 September 2026
Account: Bank
Description: September Salary
```

Result:

``` text
Credit
+ ₹5,000
```

------------------------------------------------------------------------

# 12. Transaction Model

Every transaction must have a unique ID.

Example:

``` text
TXN-000001
```

Transaction structure:

``` text
Transaction
 |
 +-- ID
 +-- User ID
 +-- Account ID
 +-- Category ID
 +-- Type
 +-- Amount
 +-- Description
 +-- Transaction Date
 +-- Payment Method
 +-- Created At
 +-- Updated At
```

Transaction type:

``` text
EXPENSE
CREDIT
```

------------------------------------------------------------------------

# 13. Categories

## Initial Expense Categories

-   Food
-   Travel
-   Shopping
-   Bills
-   Rent
-   Entertainment
-   Health
-   Education
-   Fuel
-   Other

## Initial Credit Sources

-   Salary
-   Freelance
-   Business
-   Gift
-   Refund
-   Other

Users should eventually be able to create custom categories.

------------------------------------------------------------------------

# 14. Dashboard Requirements

The dashboard is the main screen after login.

## Balance Card

``` text
Current Balance

₹11,500
```

## Summary

``` text
Credits        ₹5,000
Expenses       ₹3,500
```

## Spending Chart

Example:

``` text
Food          ₹1,200
Travel          ₹800
Shopping        ₹700
Bills           ₹500
Other           ₹300
```

## Recent Transactions

``` text
Dinner               -₹350
Salary             +₹5,000
Fuel                 -₹800
Shopping             -₹600
```

------------------------------------------------------------------------

# 15. Transaction Filters

Users should be able to filter transactions by:

-   Date
-   Date range
-   Type
-   Category
-   Account
-   Amount

Example:

``` text
September 2026
    +
  Expense
    +
   Food
```

Result:

``` text
All Food expenses during September 2026
```

------------------------------------------------------------------------

# 16. Database Design

## Initial Tables

``` text
profiles
accounts
categories
transactions
```

## Future Tables

``` text
budgets
recurring_transactions
attachments
notifications
financial_goals
```

------------------------------------------------------------------------

# 17. Profiles Table

``` text
profiles
-------------------------
id
full_name
email
avatar_url
currency
created_at
updated_at
```

`id` corresponds to the authenticated Supabase user.

------------------------------------------------------------------------

# 18. Accounts Table

``` text
accounts
-------------------------
id
user_id
name
type
opening_balance
is_active
created_at
updated_at
```

Examples:

``` text
Cash
Bank
UPI
Savings
Wallet
```

------------------------------------------------------------------------

# 19. Categories Table

``` text
categories
-------------------------
id
user_id
name
type
icon
color
is_active
created_at
updated_at
```

`type`:

``` text
EXPENSE
CREDIT
```

------------------------------------------------------------------------

# 20. Transactions Table

``` text
transactions
-------------------------
id
user_id
account_id
category_id
type
amount
description
transaction_date
payment_method
created_at
updated_at
```

This is the core table of the application.

------------------------------------------------------------------------

# 21. Security Requirements

Financial information is private, so security is a core requirement.

## Authentication

Supabase Auth will manage:

-   Registration
-   Login
-   Sessions
-   Password recovery

## Database Security

Conceptually:

``` text
auth.uid() = user_id
```

Therefore:

``` text
User A -> SELECT -> only User A records
User A -> INSERT -> only User A records
User A -> UPDATE -> only User A records
User A -> DELETE -> only User A records
```

The same principle applies to accounts and categories.

## Credential Security

-   Never expose Supabase service-role credentials in the Flutter
    application.
-   Never use privileged server credentials in the mobile client.
-   Use the appropriate client-side Supabase configuration.
-   Enforce authorization at the database layer using RLS.

------------------------------------------------------------------------

# 22. Application Navigation

Initial navigation:

``` text
Splash
  |
  v
Authentication
  +-- Login
  +-- Register
  +-- Forgot Password
          |
          v
       Dashboard
          |
     +----+----------+
     |    |          |
     v    v          v
 Expense Credit  Transactions
     |    |          |
     +----+----------+
          |
          v
       Reports
          |
          v
       Profile
```

## Suggested Bottom Navigation

``` text
+-----------------------------------+
|                                   |
|          Application              |
|                                   |
+-----------------------------------+
| Home | Transactions | Reports | Me|
+-----------------------------------+
```

A prominent action should provide:

``` text
+ Add Transaction
 |
 +-- Add Expense
 +-- Add Credit
```

------------------------------------------------------------------------

# 23. Technology Stack

## Mobile

``` text
Flutter
Dart
```

## Backend / Platform

``` text
Supabase
```

## Database

``` text
PostgreSQL
```

## Authentication

``` text
Supabase Auth
```

## Security

``` text
PostgreSQL RLS
```

## Charts

``` text
fl_chart
```

## State Management

Recommended:

``` text
Riverpod
```

## Navigation

Recommended:

``` text
go_router
```

## Version Control

``` text
Git
GitHub
```

## Deployment

``` text
Google Play Store
```

------------------------------------------------------------------------

# 24. Why Supabase Instead of Google Sheets?

The initial idea was:

``` text
Flutter
   |
Google Sheets
```

For the multi-user version, the database architecture was changed to:

``` text
Flutter
   |
Supabase
   |
PostgreSQL
```

### Reason

Google Sheets is not the appropriate primary database architecture for
this multi-user application.

Supabase provides:

-   PostgreSQL
-   Authentication
-   Row Level Security
-   Structured relational data
-   SQL queries
-   Better concurrent access
-   Better data integrity
-   Easier scaling
-   Easier future backend integration

Google Sheets can still be added later as an export or reporting
destination if required.

------------------------------------------------------------------------

# 25. Non-Functional Requirements

## Performance

-   Dashboard should load quickly.
-   Transaction lists should use pagination where appropriate.
-   Avoid unnecessary database requests.
-   Charts should not block the UI.

## Security

-   HTTPS / TLS through Supabase.
-   Secure authentication.
-   RLS enabled on user-owned tables.
-   No privileged credentials in the mobile application.

## Reliability

-   Transactions must not be duplicated.
-   Amounts must use an appropriate numeric / decimal representation.
-   Database constraints should prevent invalid references.

## Usability

-   Fast transaction entry.
-   Large amount input.
-   Minimal number of steps.
-   Mobile-first UI.
-   Clear distinction between credits and expenses.

------------------------------------------------------------------------

# 26. MVP Definition

## Authentication

-   [ ] Register
-   [ ] Login
-   [ ] Logout
-   [ ] Forgot password

## Dashboard

-   [ ] Balance
-   [ ] Credits
-   [ ] Expenses
-   [ ] Monthly summary
-   [ ] Recent transactions
-   [ ] Category chart

## Expenses

-   [ ] Add
-   [ ] Edit
-   [ ] Delete
-   [ ] Category
-   [ ] Date
-   [ ] Account
-   [ ] Description

## Credits

-   [ ] Add
-   [ ] Edit
-   [ ] Delete
-   [ ] Source
-   [ ] Date
-   [ ] Account

## Transactions

-   [ ] List
-   [ ] Search
-   [ ] Filter
-   [ ] Details

## Security

-   [ ] Supabase Auth
-   [ ] PostgreSQL
-   [ ] RLS
-   [ ] User data isolation

------------------------------------------------------------------------

# 27. Development Environment Completed

The local development environment is fully configured.

## Flutter

Installed:

``` text
Flutter 3.47.5
```

Location:

``` text
C:\src\flutter
```

PATH:

``` text
C:\src\flutter\bin
```

## Dart

Installed through Flutter:

``` text
Dart 3.13.4
```

A separate Dart SDK installation is not required.

## Android Studio

Installed and configured.

## Android SDK

Location:

``` text
C:\Users\MUBASSIR\AppData\Local\Android\Sdk
```

## Android Development Tools

Configured:

``` text
Android SDK
Android SDK Build Tools
Android SDK Platform Tools
Android SDK Command-line Tools
Android Emulator
NDK
```

## Android Emulator

Created:

``` text
Pixel 7
Android 16
API 36
x86_64
```

Emulator ID:

``` text
emulator-5554
```

## Flutter Doctor

Verified:

``` text
[√] Flutter
[√] Windows
[√] Android toolchain
[√] Chrome
[√] Visual Studio
[√] Connected device
[√] Network resources

No issues found!
```

## Flutter Project

Created:

``` text
C:\src\expense_tracker
```

## First Android Build

Successfully executed:

``` bash
flutter run -d emulator-5554
```

The project successfully generated:

``` text
build\app\outputs\flutter-apk\app-debug.apk
```

and installed it on the Android emulator.

Therefore, the complete local pipeline has been verified:

``` text
Dart
  |
Flutter
  |
Android Gradle
  |
Android SDK
  |
APK
  |
Android Emulator
```

------------------------------------------------------------------------

# 28. Current Project Status

``` text
Development Environment    100%
Flutter Installation       100%
Android Setup              100%
Android Emulator           100%
First Android Build        100%
BRD                        100%

UI                           0%
Supabase                     0%
Database                     0%
Authentication               0%
Expense Features             0%
Credit Features              0%
Dashboard                    0%
Reports                      0%
Testing                      0%
Play Store                   0%
```

------------------------------------------------------------------------

# 29. Development Roadmap

## Phase 1 --- Flutter Foundation

-   Dart fundamentals
-   Flutter fundamentals
-   Project structure
-   App architecture
-   Theme / design system
-   Navigation
-   State management

## Phase 2 --- Supabase Foundation

-   Create Supabase project
-   Configure Flutter client
-   Design PostgreSQL schema
-   Create migrations
-   Configure RLS
-   Configure authentication

## Phase 3 --- Authentication

-   Splash
-   Login
-   Registration
-   Forgot password
-   Session management
-   Logout
-   Profile

## Phase 4 --- Core UI

-   Dashboard
-   Add Expense
-   Add Credit
-   Transactions
-   Transaction details
-   Categories
-   Accounts
-   Reports
-   Profile

## Phase 5 --- Backend Integration

-   Connect Flutter to Supabase
-   CRUD operations
-   Balance calculations
-   Dashboard queries
-   Filters
-   Search
-   Pagination

## Phase 6 --- Security

-   RLS policies
-   Authentication testing
-   Cross-user access testing
-   Invalid input handling
-   Credential review

## Phase 7 --- Testing

-   Unit tests
-   Widget tests
-   Integration tests
-   Android device testing
-   Emulator testing
-   Error handling
-   Performance testing

## Phase 8 --- Release

-   App icon
-   Splash screen
-   Application metadata
-   Versioning
-   Release signing
-   Android App Bundle (AAB)
-   Play Console setup
-   Internal testing
-   Production release

------------------------------------------------------------------------

# 30. Immediate Next Step

Before implementing the UI, create the technical foundation:

``` text
Flutter project
      |
      v
Project architecture
      |
      v
Supabase project
      |
      v
Database schema
      |
      v
Migrations
      |
      v
RLS policies
      |
      v
Authentication
      |
      v
Application UI
```

The database and security model should be finalized before connecting
the production UI so that the application does not need major
restructuring later.

------------------------------------------------------------------------

# 31. Project Decision Log

  Decision            Final Choice
  ------------------- ---------------------
  Platform            Android
  Distribution        Google Play Store
  Mobile Framework    Flutter
  Language            Dart
  Database            Supabase PostgreSQL
  Authentication      Supabase Auth
  Authorization       PostgreSQL RLS
  Primary database    Supabase
  Google Sheets       Not primary DB
  State Management    Riverpod
  Navigation          go_router
  Charts              fl_chart
  Version Control     Git / GitHub
  Architecture        Multi-user
  Initial user role   USER
  Initial backend     Supabase
  Custom NestJS API   Future option
  Android emulator    Pixel 7 / API 36

------------------------------------------------------------------------

## 32. Final Architecture

``` text
                         EXPENSE TRACKER
                               |
                     +---------+---------+
                     |                   |
                     v                   v
                Flutter App        Supabase Auth
                     |                   |
                     +---------+---------+
                               |
                               v
                       PostgreSQL Database
                               |
                    +----------+----------+
                    |          |           |
                    v          v           v
                 Profiles   Accounts   Categories
                               |
                               v
                         Transactions
                               |
                               v
                         RLS Security
                               |
                               v
                    User-specific data only
```

**Current milestone:** local Flutter + Android development environment
is complete, the first Flutter Android project has been created, and the
default APK has successfully built and launched on the Pixel 7 API 36
emulator.

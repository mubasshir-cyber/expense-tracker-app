# Security & Data Governance Architecture

**Project:** Personal Expense & Finance Management App  
**Scope:** Client-Side Security, Backend Access Control, Row Level Security (RLS), & Data Protection  

---

## 1. Security Philosophy & Principles

Personal finance management requires enterprise-grade security standards. The system enforces four fundamental security pillars:

1. **Zero-Trust Client Boundary**: The client application is treated as an untrusted environment. Security rules are never purely client-side; authorization must be strictly enforced at the database level.
2. **Strict Multi-Tenant Isolation**: Complete row-level isolation between users. User $A$ cannot under any circumstance read, query, insert, or alter User $B$'s financial records.
3. **Principle of Least Privilege**: The mobile app only receives and transmits the public Anonymous Key (`anon_key`) and user JWTs. The elevated `service_role` key is strictly forbidden from inclusion in client source code.
4. **Defense in Depth**: End-to-end transport layer security (TLS 1.3), hardware-backed credential storage on Android, and relational foreign key constraints.

---

## 2. PostgreSQL Row Level Security (RLS) Specification

All tables containing user financial data have Row Level Security explicitly **ENABLED** (`ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;`).

Every query sent through the Supabase client attaches the user's JWT bearer token, resolving `auth.uid()` at the PostgreSQL engine level.

### 2.1 `profiles` Security Policy
```sql
-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Select policy (Users can only read their own profile)
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id);

-- Insert policy (System trigger or authenticated user creates own profile)
CREATE POLICY "Users can insert own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Update policy (Users can only edit their own profile)
CREATE POLICY "Users can update own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

### 2.2 `accounts` Security Policy
```sql
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own accounts" 
ON public.accounts 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create own accounts" 
ON public.accounts 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own accounts" 
ON public.accounts 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own accounts" 
ON public.accounts 
FOR DELETE 
USING (auth.uid() = user_id);
```

### 2.3 `categories` Security Policy
```sql
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own categories" 
ON public.categories 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories" 
ON public.categories 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories" 
ON public.categories 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories" 
ON public.categories 
FOR DELETE 
USING (auth.uid() = user_id);
```

### 2.4 `transactions` Security Policy
```sql
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions" 
ON public.transactions 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions" 
ON public.transactions 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions" 
ON public.transactions 
FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions" 
ON public.transactions 
FOR DELETE 
USING (auth.uid() = user_id);
```

---

## 3. Database Constraints & Data Integrity Safeguards

To prevent mathematical or referential anomalies:

- **Strict Positive Amounts**:
  ```sql
  ALTER TABLE public.transactions 
  ADD CONSTRAINT chk_transaction_amount_positive 
  CHECK (amount > 0);
  ```
- **Transaction Types**:
  ```sql
  ALTER TABLE public.transactions 
  ADD CONSTRAINT chk_transaction_type 
  CHECK (type IN ('EXPENSE', 'CREDIT'));
  ```
- **Category Types**:
  ```sql
  ALTER TABLE public.categories 
  ADD CONSTRAINT chk_category_type 
  CHECK (type IN ('EXPENSE', 'CREDIT'));
  ```
- **Foreign Key Cascading Protection**:
  - `transactions.account_id` references `accounts(id)` on delete **RESTRICT** (prevents deleting an account that has transaction history without user confirmation/cleanup).
  - `transactions.category_id` references `categories(id)` on delete **RESTRICT** / **SET DEFAULT**.

---

## 4. Authentication & Token Management

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as Flutter Client
    participant KeyStore as Android Keystore
    participant Supabase as Supabase Auth (GoTrue)
    participant DB as PostgreSQL (RLS)

    User->>App: Submits Email & Password
    App->>Supabase: signInWithPassword(email, password)
    Supabase-->>App: Returns Access JWT & Refresh Token
    App->>KeyStore: Securely write Session Tokens
    App->>Supabase: Query /rest/v1/transactions (Bearer JWT)
    Supabase->>DB: Resolves auth.uid() from JWT claims
    DB-->>Supabase: Filtered row dataset
    Supabase-->>App: Return User-only data
```

### 4.1 Token Storage on Android
- Supabase SDK uses `flutter_secure_storage` which utilizes **Android KeyStore** and **EncryptedSharedPreferences** (AES-256 GCM encryption).
- Session tokens are auto-refreshed prior to expiration without requiring manual user re-authentication.

---

## 5. Threat Modeling & Mitigation Matrix

| Threat | Risk Level | Mitigation Strategy |
|---|---|---|
| **Cross-User Data Leakage (IDOR)** | **Critical** | Enforce PostgreSQL RLS (`auth.uid() = user_id`). Even if an attacker manually passes another user's transaction ID, PostgreSQL returns 0 rows. |
| **API Key Exposure / Decompilation** | **High** | Only the public `anon_key` is bundled into the client. The `anon_key` has zero permissions without a valid user JWT. The `service_role` key is never bundled. |
| **Tampered Transaction Amounts** | **High** | Database-level `CHECK (amount > 0)` constraint prevents negative expenses or fraudulent balance credits. |
| **Man-in-the-Middle (MitM)** | **Medium** | Enforce HTTPS / TLS 1.3 encryption across all network communication. |
| **Device Theft / Local Memory Dump** | **Medium** | Sensitive session credentials are saved using Android KeyStore-backed encrypted storage. |
| **SQL Injection** | **Low** | Supabase PostgREST uses prepared parameterized statements exclusively; raw SQL string interpolation is avoided. |

---

## 6. Pre-Production Security Checklist

- [ ] All 4 tables (`profiles`, `accounts`, `categories`, `transactions`) have RLS enabled.
- [ ] No table has public write or read access without `auth.uid()` verification.
- [ ] Supabase `service_role` secret is stored strictly in secure CI/CD environment variables and never present in Flutter source code.
- [ ] Proguard / R8 code obfuscation is enabled in `android/app/build.gradle` for release builds.
- [ ] Cross-tenant penetration test executed (attempt to access User A's data using User B's auth token).

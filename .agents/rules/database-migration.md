# Database Migration Rule

## MANDATORY: All schema changes require a SQL migration file

Whenever you need to change the Supabase database schema for the `expense_tracker` project at `c:\src\expense_tracker`, you MUST follow this process:

### 1. Create the migration file
```powershell
cd c:\src\expense_tracker
npm run db:new -- <NNN_description>
```
Example: `npm run db:new -- 003_add_tags_to_transactions`

This creates: `supabase/migrations/<timestamp>_NNN_description.sql`

### 2. Write the SQL (idempotent patterns)
- `ALTER TABLE t ADD COLUMN IF NOT EXISTS col TYPE DEFAULT val;`
- `CREATE TABLE IF NOT EXISTS ...`
- `CREATE INDEX IF NOT EXISTS ...`
- `CREATE OR REPLACE FUNCTION ...`
- `DROP TRIGGER IF EXISTS ... ; CREATE TRIGGER ...`

### 3. Push the migration
```powershell
npm run db:push:dry   # validate first
npm run db:push       # apply to remote
npm run db:status     # confirm in sync
```

### 4. Sync Dart code (Model / Repository Sync Rule)
When a column is added to the DB:
1. Add the field to the domain model (`fromMap`, `toMap`, `copyWith`)
2. Update the repository insert/update methods
3. Add a serialization test for the new column

### 5. Update docs
- `docs/memory.md` — add a changelog entry for the migration
- `docs/phase.md` — tick off the milestone task if applicable

### Triggers that require a migration
- Adding, dropping, or renaming a column
- Adding or removing a table or view
- Changing constraints, indexes, RLS policies, or triggers
- Updating function definitions
- Adding reproducible seed data

### NEVER
- Edit the Supabase cloud console directly without a migration file
- Use `DROP TABLE` or `DROP COLUMN` without `IF EXISTS`
- Hard-code column names in Dart that don't match the migration SQL

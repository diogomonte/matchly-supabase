---
name: add-migration
description: Create a new Supabase migration file following project conventions. Use when the user wants to add a table, column, index, policy, function, or any other schema change.
argument-hint: <short_description>
---

Create a new Supabase migration for: $ARGUMENTS

## Steps

1. **Generate the timestamp** using the current date/time in the format `YYYYMMDDHHMMSS` (e.g. `20260321143000`).

2. **Derive the filename** by combining the timestamp with a snake_case version of the description:
   `supabase/migrations/TIMESTAMP_$ARGUMENTS.sql`
   Example: `supabase/migrations/20260321143000_add_posts_table.sql`

3. **Write the migration SQL** following these rules:
   - Include a comment at the top: `-- Migration: $ARGUMENTS`
   - If creating a new table, always include:
     ```sql
     ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;
     ```
   - Define RLS policies for every operation the table needs (SELECT, INSERT, UPDATE, DELETE)
   - Use `auth.uid()` to scope user-owned data policies
   - Only include schema changes, never seed data

4. **Remind the user** to run the following after reviewing the migration:
   ```
   npm run supabase:reset        # apply locally
   npm run supabase:generate-types  # sync TypeScript types
   ```

5. **Show the full file path** of the created migration so the user can review it.

---
name: db-reset
description: Reset the local Supabase database, reapply all migrations from scratch, and regenerate TypeScript types.
disable-model-invocation: true
allowed-tools: Bash(npm run supabase:reset), Bash(npm run supabase:generate-types)
---

Reset the local Supabase database and sync types.

## Steps

1. Warn the user: this will **wipe all local data** and reapply migrations + seed.sql from scratch.

2. Run the reset:
   ```bash
   npm run supabase:reset
   ```

3. On success, immediately regenerate types:
   ```bash
   npm run supabase:generate-types
   ```

4. Confirm both commands succeeded and that `src/types/supabase.ts` is up to date.

5. If either command fails, check:
   - Local Supabase is running: `npm run supabase:status`
   - Docker is running (Supabase local dev requires Docker)
   - Ports 54321–54326 are not in use by another process

## Notes

- This only affects your **local** development database — production is untouched
- To push schema changes to production, use `npm run supabase:migrate`

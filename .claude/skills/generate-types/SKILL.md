---
name: generate-types
description: Regenerate TypeScript types from the local Supabase schema by running the type generation script.
disable-model-invocation: true
allowed-tools: Bash(npm run supabase:generate-types)
---

Regenerate the TypeScript types from the local Supabase schema.

## Steps

1. Run the type generation command:
   ```bash
   npm run supabase:generate-types
   ```

2. Confirm `src/types/supabase.ts` was updated by checking its modification time or showing a summary of changes.

3. If the command fails, likely causes are:
   - Local Supabase is not running → tell the user to run `npm run supabase:start` first
   - No migrations applied yet → tell the user to run `npm run supabase:reset` first

## Notes

- Never edit `src/types/supabase.ts` manually — it is always overwritten by this command
- Run this after every migration that modifies the `public` schema

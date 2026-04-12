# Template Prompt

> Use this prompt when creating a new repository from this template, or when
> asking an AI assistant to help you set up a new Supabase project.

---

## Prompt

```
I'm creating a new Supabase-powered application from a skeleton template. Help me set it up.

Project details:
- Project name: [YOUR_PROJECT_NAME]
- Description: [SHORT_DESCRIPTION]
- GitHub repo: [OWNER]/[REPO_NAME]
- Supabase project ref: [YOUR_SUPABASE_PROJECT_REF] (optional — can be added later)
- Site URL: [YOUR_SITE_URL, e.g. http://localhost:3000]

The template is a clean skeleton with:
- Google OAuth authentication pre-configured
- Supabase CLI and migrations setup (no tables yet — ready for you to add)
- Auto-generated TypeScript types via supabase gen types
- Row Level Security conventions

Please:
1. Replace all template placeholders with my project values
2. Update the README with my project name and URLs
3. Update package.json with my project name and description
4. Update supabase/config.toml project_id
5. Create my first database migration with the tables I need
6. Set up the .env file from .env.example with my credentials
7. Walk me through running the local Supabase stack and verifying everything works
```

---

## Quick Start (Manual)

If you prefer to initialize without AI, run the interactive setup script:

```bash
chmod +x scripts/init.sh
./scripts/init.sh
```

The script will prompt you for each value and replace all placeholders automatically.

---

## Placeholders Reference

These placeholders appear throughout the codebase and are replaced during initialization:

| Placeholder | Where Used | Description |
|---|---|---|
| `serene-supabase` | `package.json`, `config.toml`, `README.md` | Project name |
| `diogomonte/serene-supabase` | `README.md` | GitHub owner/repo |

---

## What to Customize After Initialization

- [ ] Replace `.env.example` values with your actual credentials
- [ ] Update Google OAuth redirect URIs in Google Cloud Console
- [ ] Create your first migration: `supabase migration new create_my_table`
- [ ] Add RLS policies to every new table
- [ ] Add edge functions if needed: `supabase functions new my-function`
- [ ] Regenerate TypeScript types: `npm run supabase:generate-types`

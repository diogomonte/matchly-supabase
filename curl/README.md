# curl samples

Ready-to-run curl commands for every API in the project.

## Setup

Copy the environment file and fill in the values from `supabase status`:

```bash
cp curl/.env.example curl/.env
source curl/.env
```

Then run any sample:

```bash
bash curl/auth.sh
bash curl/profiles.sh
# etc.
```

## Files

| File | Covers |
|------|--------|
| `auth.sh` | Sign up and sign in via OTP (phone auth) |
| `profiles.sh` | Read and update your own profile |
| `clubs.sh` | List clubs |
| `match_requests.sh` | Create, list, and cancel match requests |
| `feed.sh` | Scored feed via the `score_feed` edge function |
| `matches.sh` | Propose, confirm, and decline matches via `propose_match` |
| `device_tokens.sh` | Register and delete push notification tokens |

## Local base URLs

| Service | URL |
|---------|-----|
| REST API | `http://127.0.0.1:54321/rest/v1` |
| Auth API | `http://127.0.0.1:54321/auth/v1` |
| Edge Functions | `http://127.0.0.1:54321/functions/v1` |

# Matchly API Reference

HTTP reference for the Matchly Supabase backend. All endpoints are consumed over plain HTTP — no SDK required.

---

## 1. Connection Setup

### Base URLs

| Service | Local URL |
|---------|-----------|
| REST API | `http://127.0.0.1:54321/rest/v1` |
| Auth | `http://127.0.0.1:54321/auth/v1` |
| Edge Functions | `http://127.0.0.1:54321/functions/v1` |
| Storage | `http://127.0.0.1:54321/storage/v1` |
| Realtime (WebSocket) | `ws://127.0.0.1:54321/realtime/v1/websocket` |
| Studio (browser) | `http://127.0.0.1:54323` |
| Mailpit / OTP inbox (browser) | `http://127.0.0.1:54324` |

### Required headers

Every request must include these two headers:

```
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
Authorization: Bearer <access_token>
```

- **`apikey`** — always the publishable key above. Safe to hardcode in the app.
- **`Authorization`** — `Bearer <access_token>` once signed in. Before sign-in (e.g. the OTP request itself), use `Bearer sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH` as a fallback.

---

## 2. Authentication — Phone OTP

### Step 1 — Request OTP

```
POST http://127.0.0.1:54321/auth/v1/otp
Content-Type: application/json
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH

{
  "phone": "+4512345678"
}
```

**Response 200** — empty body. The 6-digit code is sent via SMS. Locally, view it at **http://127.0.0.1:54324** (Mailpit).

---

### Step 2 — Verify OTP → get access token

```
POST http://127.0.0.1:54321/auth/v1/verify
Content-Type: application/json
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH

{
  "phone": "+4512345678",
  "token": "123456",
  "type": "sms"
}
```

**Response 200**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "abc123...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "phone": "+4512345678",
    "created_at": "2026-04-20T10:00:00Z"
  }
}
```

Store `access_token`, `refresh_token`, and `user.id`. A profile row is automatically created for the user in the `profiles` table.

---

### Step 3 — Refresh token

```
POST http://127.0.0.1:54321/auth/v1/token?grant_type=refresh_token
Content-Type: application/json
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH

{
  "refresh_token": "abc123..."
}
```

**Response 200** — same shape as Step 2. Replace the stored tokens.

---

### Get current user

```
GET http://127.0.0.1:54321/auth/v1/user
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
Authorization: Bearer <access_token>
```

**Response 200** — the `user` object from Step 2.

---

## 3. REST API

All REST endpoints follow the pattern `http://127.0.0.1:54321/rest/v1/<table>`.

### Common headers for write operations

```
Content-Type: application/json
Prefer: return=representation
```

`Prefer: return=representation` makes the server return the created/updated row in the response body.

---

### 3.1 Clubs

Read-only. Any authenticated user can list clubs.

#### List all clubs

```
GET /rest/v1/clubs?select=*&order=name.asc
apikey: ...
Authorization: Bearer <access_token>
```

**Response 200**
```json
[
  {
    "id": "uuid",
    "name": "Padel Club København",
    "city": "Copenhagen",
    "lat": 55.706374,
    "lng": 12.577550,
    "created_at": "2026-04-15T00:00:00Z"
  }
]
```

#### Get one club

```
GET /rest/v1/clubs?id=eq.<club_id>&select=*
Accept: application/vnd.pgrst.object+json
```

---

### 3.2 Profiles

Each user has exactly one profile, auto-created on sign-up.

#### Read own profile

```
GET /rest/v1/profiles?select=*
apikey: ...
Authorization: Bearer <access_token>
```

**Response 200**
```json
[
  {
    "id": "uuid",
    "phone": "+4512345678",
    "display_name": "Marco Rossi",
    "photo_url": "http://127.0.0.1:54321/storage/v1/object/public/profile-photos/uuid/avatar.jpg",
    "home_club_ids": ["uuid1", "uuid2"],
    "self_rated_level": 3.5,
    "calibrated_level": 3.5,
    "playstyle_tags": ["Aggressive", "NetPlayer"],
    "intent": "competitive",
    "reliability_score": 1.00,
    "created_at": "2026-04-20T10:00:00Z",
    "updated_at": "2026-04-20T10:00:00Z"
  }
]
```

#### Update own profile

```
PATCH /rest/v1/profiles?id=eq.<user_id>
apikey: ...
Authorization: Bearer <access_token>
Content-Type: application/json
Prefer: return=representation

{
  "display_name": "Marco Rossi",
  "self_rated_level": 3.5,
  "playstyle_tags": ["Aggressive", "NetPlayer"],
  "intent": "competitive",
  "home_club_ids": ["uuid1"]
}
```

**Field constraints:**
| Field | Constraint |
|-------|-----------|
| `self_rated_level` | 1.0 – 5.0 |
| `calibrated_level` | 1.0 – 5.0 |
| `playstyle_tags` | max 3 values from: `Aggressive`, `Consistent`, `Defensive`, `Social`, `Competitive`, `NetPlayer`, `Lefty` |
| `home_club_ids` | max 2 UUIDs from clubs table |
| `intent` | `competitive` \| `social` \| `both` |

---

### 3.3 Public Profiles

Safe view of other users' profiles. Excludes phone, self_rated_level, intent, and timestamps.

#### Get one user's public profile

```
GET /rest/v1/public_profiles?id=eq.<user_id>&select=*
apikey: ...
Authorization: Bearer <access_token>
Accept: application/vnd.pgrst.object+json
```

**Response 200**
```json
{
  "id": "uuid",
  "display_name": "Marco Rossi",
  "photo_url": "...",
  "calibrated_level": 3.5,
  "playstyle_tags": ["Aggressive", "NetPlayer"],
  "home_club_ids": ["uuid1"],
  "reliability_score": 0.95
}
```

---

### 3.4 Match Requests

#### Create a match request

```
POST /rest/v1/match_requests
apikey: ...
Authorization: Bearer <access_token>
Content-Type: application/json
Prefer: return=representation

{
  "creator_id": "<your_user_id>",
  "club_id": "<club_uuid>",
  "proposed_window": "[2026-04-20 09:00:00+00,2026-04-20 11:00:00+00)"
}
```

`proposed_window` is a PostgreSQL timestamp range. Format: `[start,end)` in UTC.

**Response 201**
```json
[
  {
    "id": "uuid",
    "creator_id": "uuid",
    "club_id": "uuid",
    "proposed_window": "[\"2026-04-20 09:00:00+00\",\"2026-04-20 11:00:00+00\")",
    "status": "open",
    "created_at": "2026-04-20T08:00:00Z"
  }
]
```

#### List open requests (raw feed, unscored)

```
GET /rest/v1/match_requests?status=eq.open&select=*,creator:public_profiles!creator_id(*)
apikey: ...
Authorization: Bearer <access_token>
```

Use the `score_feed` edge function (section 4.1) for a scored and filtered feed instead.

#### List my own requests (all statuses)

```
GET /rest/v1/match_requests?creator_id=eq.<user_id>&select=*&order=created_at.desc
```

#### Cancel a request

```
PATCH /rest/v1/match_requests?id=eq.<request_id>
Content-Type: application/json
Prefer: return=representation

{
  "status": "cancelled"
}
```

**Status values:** `open` → `cancelled` (by owner), `matched` (by system), `expired` (by system).

---

### 3.5 Matches

Matches are created only via the `propose_match` edge function (section 4.2). The REST endpoint is used to read them.

#### List my matches with participants

```
GET /rest/v1/matches?select=*,match_participants(*,profile:public_profiles!user_id(*))&order=scheduled_at.asc
apikey: ...
Authorization: Bearer <access_token>
```

#### List upcoming confirmed matches

```
GET /rest/v1/matches?status=eq.confirmed&scheduled_at=gt.2026-04-18T00:00:00Z&select=*
```

**Match status values:** `pending` | `confirmed` | `declined` | `cancelled` | `completed`

**Response row shape:**
```json
{
  "id": "uuid",
  "request_id": "uuid",
  "host_id": "uuid",
  "club_id": "uuid",
  "scheduled_at": "2026-04-20T10:00:00Z",
  "format": "singles",
  "status": "pending",
  "created_at": "...",
  "updated_at": "..."
}
```

---

### 3.6 Match Participants

One row per player per match. Used to confirm or decline an invitation.

#### Confirm a match (invited player)

```
PATCH /rest/v1/match_participants?match_id=eq.<match_id>&user_id=eq.<your_user_id>
apikey: ...
Authorization: Bearer <access_token>
Content-Type: application/json
Prefer: return=representation

{
  "status": "confirmed",
  "responded_at": "2026-04-20T09:30:00Z"
}
```

#### Decline a match

Same as above with `"status": "declined"`.

After all invited participants confirm, update the parent match status:

```
PATCH /rest/v1/matches?id=eq.<match_id>
Content-Type: application/json

{
  "status": "confirmed",
  "updated_at": "2026-04-20T09:30:00Z"
}
```

**Participant row shape:**
```json
{
  "match_id": "uuid",
  "user_id": "uuid",
  "team": 1,
  "role": "host",
  "status": "confirmed",
  "joined_at": "2026-04-20T09:00:00Z",
  "responded_at": "2026-04-20T09:30:00Z"
}
```

**Role values:** `host` | `invited`
**Status values:** `pending` | `confirmed` | `declined`

---

### 3.7 Device Tokens

Register push notification tokens for FCM (Android) or APNs (iOS).

#### Register / upsert a token

```
POST /rest/v1/device_tokens
apikey: ...
Authorization: Bearer <access_token>
Content-Type: application/json
Prefer: return=representation,resolution=merge-duplicates

{
  "user_id": "<your_user_id>",
  "platform": "android",
  "token": "<fcm_or_apns_token>"
}
```

`resolution=merge-duplicates` upserts on the `(user_id, token)` unique constraint — safe to call on every app launch.

**Platform values:** `android` | `ios`

#### Delete a token (on sign-out)

```
DELETE /rest/v1/device_tokens?user_id=eq.<user_id>&token=eq.<token>
apikey: ...
Authorization: Bearer <access_token>
```

---

## 4. Edge Functions

Edge functions require only `Authorization` — no `apikey` header needed.

---

### 4.1 `score_feed` — Ranked match feed

Returns the caller's own open requests and a scored feed of other users' open requests.

**Score formula:** `0.5 × level_score + 0.25 × playstyle_score + 0.25 × reliability_score`

**Hard filters applied to `feed` before scoring:**
- Creator must not be soft-blocked by the caller
- Intent must be compatible: `social` and `competitive` are mutually exclusive; `both` matches anything

```
POST http://127.0.0.1:54321/functions/v1/score_feed
Authorization: Bearer <access_token>
```

Body: empty (user identity comes from the JWT).

**Response 200**
```json
{
  "data": {
    "own": [
      {
        "id": "uuid",
        "creator_id": "uuid",
        "club_id": "uuid",
        "proposed_window": "[\"2026-04-20 09:00:00+00\",\"2026-04-20 11:00:00+00\")",
        "proposed_at": "2026-04-20T08:00:00Z",
        "status": "open",
        "created_at": "2026-04-20T07:00:00Z",
        "creator": {
          "id": "uuid",
          "display_name": "Marco Rossi",
          "photo_url": "...",
          "calibrated_level": 3.5,
          "playstyle_tags": ["Aggressive", "NetPlayer"],
          "reliability_score": 1.0,
          "intent": "competitive"
        }
      }
    ],
    "feed": [
      {
        "id": "uuid",
        "creator_id": "uuid",
        "club_id": "uuid",
        "proposed_window": "[\"2026-04-20 09:00:00+00\",\"2026-04-20 11:00:00+00\")",
        "proposed_at": "2026-04-20T07:30:00Z",
        "status": "open",
        "created_at": "2026-04-20T07:00:00Z",
        "score": 87.5,
        "creator": {
          "id": "uuid",
          "display_name": "Anna Larsen",
          "photo_url": "...",
          "calibrated_level": 3.5,
          "playstyle_tags": ["Consistent", "Defensive"],
          "reliability_score": 0.98,
          "intent": "both"
        }
      }
    ]
  },
  "meta": {
    "elapsed_ms": 115
  }
}
```

- `own` — caller's own open requests, ordered by `proposed_at` ascending. No `score` field.
- `feed` — up to 50 other users' open requests after filtering, ordered by `score` descending.

**Error responses:**

| Status | Body | Reason |
|--------|------|--------|
| 401 | `{ "error": "Unauthorized" }` | Missing or invalid JWT |
| 404 | `{ "error": "Profile not found" }` | Caller has no profile row |

---

### 4.2 `propose_match` — Create a match

Proposes a match to the creator of an open request. Transactionally creates a `matches` row and two `match_participants` rows, and marks the request as `matched`.

```
POST http://127.0.0.1:54321/functions/v1/propose_match
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "request_id": "uuid-of-the-open-request",
  "scheduled_at": "2026-04-20T10:00:00Z"
}
```

`scheduled_at` must be an ISO 8601 UTC timestamp that falls **inside** the request's `proposed_window`.

**Response 201**
```json
{
  "data": {
    "match_id": "uuid"
  }
}
```

**Error responses:**

| Status | Body | Reason |
|--------|------|--------|
| 400 | `{ "error": "request_id and scheduled_at are required" }` | Missing fields |
| 400 | `{ "error": "scheduled_at must be inside the proposed window" }` | Time out of range |
| 400 | `{ "error": "Cannot propose a match on your own request" }` | Same user |
| 401 | `{ "error": "Unauthorized" }` | Invalid JWT |
| 404 | `{ "error": "Match request not found" }` | Request doesn't exist |
| 409 | `{ "error": "Match request is no longer open" }` | Already matched/cancelled |

---

## 5. Storage — Profile Photos

### Upload a photo

```
POST http://127.0.0.1:54321/storage/v1/object/profile-photos/<user_id>/avatar.jpg
apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
Authorization: Bearer <access_token>
Content-Type: image/jpeg

<binary image data>
```

The path **must** start with the caller's own user UUID. Uploads to another user's folder are rejected.

Supported content types: `image/jpeg`, `image/png`, `image/webp`. Max size: 2 MB.

### Public read URL

```
GET http://127.0.0.1:54321/storage/v1/object/public/profile-photos/<user_id>/avatar.jpg
```

No auth required. Store this URL in `profiles.photo_url` after a successful upload.

### Replace / update a photo

```
PUT http://127.0.0.1:54321/storage/v1/object/profile-photos/<user_id>/avatar.jpg
Authorization: Bearer <access_token>
Content-Type: image/jpeg

<binary image data>
```

---

## 6. Realtime — Live Updates

Connect to the Realtime WebSocket to receive database change events without polling.

### WebSocket URL

```
ws://127.0.0.1:54321/realtime/v1/websocket?apikey=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH&vsn=1.0.0
```

### Tables with Realtime enabled

| Table | Events | Use case |
|-------|--------|----------|
| `match_requests` | INSERT, UPDATE | New requests appear in feed; matched/cancelled requests disappear |
| `matches` | INSERT, UPDATE | Incoming match proposals; status changes (confirmed, declined) |
| `match_participants` | INSERT, UPDATE | Co-player's response to an invitation |

### Subscribe to a table (channel payload)

Send this JSON after the WebSocket handshake to subscribe to a table:

```json
{
  "topic": "realtime:public:match_requests",
  "event": "phx_join",
  "payload": {
    "config": {
      "broadcast": { "self": false },
      "postgres_changes": [
        { "event": "INSERT", "schema": "public", "table": "match_requests" },
        { "event": "UPDATE", "schema": "public", "table": "match_requests" }
      ]
    }
  },
  "ref": "1"
}
```

### Incoming event shape

```json
{
  "topic": "realtime:public:match_requests",
  "event": "postgres_changes",
  "payload": {
    "data": {
      "schema": "public",
      "table": "match_requests",
      "commit_timestamp": "2026-04-20T10:01:00Z",
      "eventType": "INSERT",
      "new": {
        "id": "uuid",
        "creator_id": "uuid",
        "club_id": "uuid",
        "proposed_window": "[\"2026-04-20 09:00:00+00\",\"2026-04-20 11:00:00+00\")",
        "status": "open",
        "created_at": "2026-04-20T10:01:00Z"
      },
      "old": {}
    }
  }
}
```

For UPDATE events, `old` contains the previous column values and `new` contains the updated ones. RLS is respected — you only receive events for rows you are allowed to read.

---

## 7. Common HTTP Patterns

### PostgREST filter operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq` | equals | `?status=eq.open` |
| `neq` | not equals | `?creator_id=neq.<my_id>` |
| `in` | in list | `?club_id=in.(uuid1,uuid2)` |
| `gt` | greater than | `?scheduled_at=gt.2026-04-18T00:00:00Z` |
| `is` | null check | `?responded_at=is.null` |
| `order` | sort | `?order=created_at.desc` |
| `limit` | max rows | `?limit=20` |
| `offset` | pagination | `?offset=20` |

### Joining related tables

```
GET /rest/v1/match_requests?select=*,creator:public_profiles!creator_id(display_name,photo_url,calibrated_level)
```

### Single-row response

Add `Accept: application/vnd.pgrst.object+json` to get a JSON object instead of an array. Returns 406 if 0 or multiple rows match.

### Get the written row back

Add `Prefer: return=representation` to POST/PATCH requests to receive the row in the response.

### Data types

| Type | Format |
|------|--------|
| UUID | `"550e8400-e29b-41d4-a716-446655440000"` |
| Timestamps | ISO 8601 UTC `"2026-04-20T10:00:00Z"` |
| Arrays | JSON array `["Aggressive", "NetPlayer"]` |
| `proposed_window` | Range string `"[\"2026-04-20 09:00:00+00\",\"2026-04-20 11:00:00+00\")"` — parse the two timestamps from inside the brackets |

---

## 8. Error Responses

### PostgREST errors (REST API)

```json
{
  "code": "42501",
  "details": null,
  "hint": null,
  "message": "new row violates row-level security policy for table \"match_requests\""
}
```

Common status codes:

| HTTP | Meaning |
|------|---------|
| 200 | OK |
| 201 | Row created |
| 204 | Success, no body (DELETE) |
| 400 | Bad request / constraint violation |
| 401 | Missing or invalid JWT |
| 403 | JWT valid but RLS denies access |
| 404 | No rows matched (with `Accept: application/vnd.pgrst.object+json`) |
| 409 | Unique constraint violation |

### Edge function errors

```json
{
  "error": "Human-readable message"
}
```

Always a JSON object with a single `"error"` string key. See each function's error table in section 4.

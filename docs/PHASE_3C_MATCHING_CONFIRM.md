# Phase 3c — Matching: Propose & Confirm

**Duration:** Days 12–14
**Goal:** Two users can propose, accept, and end up with a confirmed match. Push notifications fire on both events.

**Prerequisites:** Phases 0–3b complete.

**Definition of done:** Two real users on different devices can install the app, sign up, complete profiles, see each other in the feed, and one taps "Propose" → the other gets a push → taps "Confirm" → both see the match in their "Upcoming" strip. **This is the MVP.**

---

## Task 3c.1 — Migration: matches table
**Label:** `supabase`

Migration: `0006_matches.sql`

- [ ] Create `matches` table per [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md)
- [ ] Status enum check constraint
- [ ] RLS:
  - SELECT: `auth.uid() IN (player_a, player_b)`
  - UPDATE: `auth.uid() IN (player_a, player_b)` with status transition rules enforced server-side
  - INSERT: only via the `propose_match` edge function (or a trigger that validates)

**Acceptance:** SQL tests verify only the two players can see and update a match.

---

## Task 3c.2 — `propose_match` Edge Function
**Label:** `supabase`

Location: `/supabase/functions/propose_match/index.ts`

**Input:** `{ request_id: string, scheduled_at: string }`

- [ ] Validate caller from JWT
- [ ] Load the `match_request`, verify status is `open`
- [ ] Verify `scheduled_at` falls inside the proposed window
- [ ] Verify caller is not the creator
- [ ] In a transaction:
  - Insert into `matches` with `status = 'pending'`, `player_a = caller`, `player_b = request.creator_id`
  - Update `match_requests.status = 'matched'`
- [ ] Return the new match id

**Acceptance:** Calling with an invalid request id, or proposing your own request, returns an error. Valid call creates a match and updates the request.

---

## Task 3c.3 — Implement `MatchRepository`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/data/match/MatchRepository.kt`

```kotlin
interface MatchRepository {
    suspend fun propose(requestId: String, scheduledAt: Instant): Result<Match>
    suspend fun confirm(matchId: String): Result<Match>
    suspend fun decline(matchId: String): Result<Match>
    suspend fun getUpcoming(): Result<List<Match>>
    fun observeUpcoming(): Flow<List<Match>>
}
```

- [ ] `propose` calls the edge function
- [ ] `confirm` and `decline` update `matches.status` directly
- [ ] `getUpcoming` returns matches with status `confirmed` and `scheduled_at` in future
- [ ] Realtime subscription on `matches` for the current user

**Acceptance:** Repository unit tests cover all methods.

---

## Task 3c.4 — Implement `MatchProposalViewModel`
**Label:** `app`

For the recipient screen showing an incoming proposal.

```kotlin
data class MatchProposalUiState(
    val isLoading: Boolean = false,
    val match: Match? = null,
    val proposer: PublicProfile? = null,
    val isResponding: Boolean = false,
    val error: String? = null,
    val result: ProposalResult? = null,
)

enum class ProposalResult { Confirmed, Declined }
```

- [ ] Load match + proposer profile on init
- [ ] Confirm and decline actions
- [ ] On result, navigate back

**Acceptance:** Unit tests cover load, confirm, decline, error.

---

## Task 3c.5 — Wire "Propose" button on feed cards
**Label:** `app`

- [ ] Tapping "Propose" opens a small sheet to pick a specific time inside the window
- [ ] Confirm in sheet → calls `MatchRepository.propose`
- [ ] Show loading state on the card
- [ ] On success, show toast "Proposal sent" and remove the card from the feed
- [ ] On error, show inline error

**Acceptance:** A successful propose creates a `matches` row and the recipient receives a push (Task 3c.8).

---

## Task 3c.6 — Build proposal detail screen (recipient)
**Label:** `app`

- [ ] Shown when the recipient taps a push or opens an incoming proposal
- [ ] Display: proposer photo, name, level, playstyle tags, club, scheduled time
- [ ] "Confirm" and "Decline" buttons
- [ ] Loading and error states
- [ ] On confirm, navigate to upcoming matches view

**Acceptance:** Recipient can confirm or decline; status updates appropriately.

---

## Task 3c.7 — Build "Upcoming matches" strip on feed
**Label:** `app`

- [ ] Horizontal strip above the feed list
- [ ] One card per upcoming match: opponent photo, name, club, scheduled time, "in 2 days" relative label
- [ ] Tap a card → match detail screen
- [ ] Hidden when no upcoming matches

**Acceptance:** Confirmed matches appear in the strip on both players' devices within 3 seconds.

---

## Task 3c.8 — Set up FCM (Android) and APNs (iOS)
**Label:** `app`

**Android:**
- [ ] Add Firebase project, download `google-services.json`
- [ ] Add FCM dependencies
- [ ] Register a `FirebaseMessagingService` that captures the token and uploads to `device_tokens`
- [ ] Handle incoming notifications

**iOS:**
- [ ] Enable Push Notifications capability in Xcode
- [ ] Create an APNs key in Apple Developer portal
- [ ] Upload the key to Supabase (or to your push service)
- [ ] Register for remote notifications and upload the token to `device_tokens`

**Acceptance:** A test push from the Supabase dashboard reaches both platforms.

---

## Task 3c.9 — Migration: device_tokens table
**Label:** `supabase`

Migration: `0009_device_tokens.sql`

- [ ] Create per data model
- [ ] RLS: users manage only their own tokens
- [ ] Unique constraint on (user_id, token)

**Acceptance:** Inserting a token from the app succeeds; cross-user inserts are rejected.

---

## Task 3c.10 — Push trigger: match proposed
**Label:** `supabase`

Migration: `0012_push_triggers.sql` + `/supabase/functions/send_match_proposal_notification/index.ts`

- [ ] Database trigger on `matches` INSERT calls the edge function
- [ ] Edge function looks up `player_b`'s device tokens
- [ ] Sends push via FCM (Android) and APNs (iOS) with payload:
  ```json
  {
    "title": "Match request",
    "body": "Marco wants to play Saturday 10am at Padelhuset",
    "data": { "type": "match_proposal", "match_id": "..." }
  }
  ```

**Acceptance:** Recipient gets a push within 5 seconds of a proposal being created.

---

## Task 3c.11 — Push trigger: match confirmed
**Label:** `supabase`

- [ ] Database trigger on `matches` UPDATE where new status is `confirmed`
- [ ] Edge function sends push to `player_a` (the proposer)
- [ ] Payload deep-links to the upcoming match

**Acceptance:** Proposer gets a push within 5 seconds of the recipient confirming.

---

## Task 3c.12 — Handle deep links from notifications
**Label:** `app`

- [ ] Android: intent handler in `MainActivity` that reads `match_id` from the notification data and navigates to the right screen
- [ ] iOS: notification delegate that does the same
- [ ] Cold-launch case: store the pending deep link and navigate after auth check completes
- [ ] Routes:
  - `match_proposal` → proposal detail screen
  - `match_confirmed` → upcoming match detail

**Acceptance:** Tapping a push (cold or warm) lands on the correct screen on both platforms.

---

## Phase 3c exit criteria — and MVP complete

- ✅ `matches` table deployed with RLS
- ✅ `propose_match` edge function works
- ✅ Two users can complete the full propose → push → confirm → upcoming flow
- ✅ Push notifications fire on both proposal and confirmation
- ✅ Deep links route correctly on both platforms
- ✅ All repository and ViewModel unit tests pass

**🎯 At the end of Phase 3c, the MVP is shippable. Two strangers can meet at a court because of this app.**

---

## What comes next (NOT in MVP)

These belong to Phase 4+ and should NOT be built before the matching loop is validated with real users:

- Post-match feedback (thumbs / level slider / reliability)
- Calibration loop (updating `calibrated_level` from feedback)
- Doubles matching
- In-app chat
- Court booking integration
- Stats and history pages
- Tennis support
- Multi-city

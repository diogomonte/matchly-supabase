# Phase 3a — Matching: Feed

**Duration:** Days 8–10
**Goal:** Users can post a match request and see other users' open requests in a live feed.

**Prerequisites:** Phases 0–2 complete.

**Definition of done:** Two users on different devices can each post a request and see each other's request appear in their feed without manual refresh.

---

## Task 3a.1 — Migration: match_requests table
**Label:** `supabase`

Migration: `0005_match_requests.sql`

- [ ] Create `match_requests` table per [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md)
- [ ] Indexes: `(club_id, status, proposed_window)` and `(creator_id, status)`
- [ ] Enable RLS with policies:
  - INSERT: `auth.uid() = creator_id`
  - UPDATE/DELETE own
  - SELECT open requests: any authenticated user where `status = 'open'`
  - SELECT own requests: any status

**Acceptance:** SQL tests verify a user can see other users' open requests but cannot modify them.

---

## Task 3a.2 — Implement `MatchRequestRepository`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/data/match/MatchRequestRepository.kt`

```kotlin
interface MatchRequestRepository {
    suspend fun createRequest(
        clubId: String,
        windowStart: Instant,
        windowEnd: Instant,
    ): Result<MatchRequest>

    suspend fun getFeed(filters: FeedFilters): Result<List<FeedItem>>

    suspend fun cancelRequest(requestId: String): Result<Unit>

    suspend fun getMyRequests(): Result<List<MatchRequest>>

    fun observeFeed(filters: FeedFilters): Flow<List<FeedItem>>
}
```

- [ ] `FeedItem` includes the request + the joined `public_profiles` data of the creator
- [ ] `FeedFilters`: optional day, time-of-day band, club id
- [ ] Implement using a Supabase RPC or a joined query against `match_requests` + `public_profiles`

**Acceptance:** Repository unit tests cover all methods.

---

## Task 3a.3 — Implement `FeedViewModel`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/presentation/feed/FeedViewModel.kt`

```kotlin
data class FeedUiState(
    val isLoading: Boolean = false,
    val items: List<FeedItem> = emptyList(),
    val filters: FeedFilters = FeedFilters(),
    val error: String? = null,
)
```

- [ ] Load feed on init using current filters
- [ ] Pull-to-refresh action
- [ ] Filter change action
- [ ] Empty state when no items
- [ ] Subscribe to realtime updates (Task 3a.6)

**Acceptance:** Unit tests cover load, filter change, refresh, and error.

---

## Task 3a.4 — Build "create match request" screen
**Label:** `app`

Three-field screen:

- [ ] Club picker: defaults to user's home clubs, single select
- [ ] Date picker: today + next 14 days
- [ ] Time window picker: morning / midday / afternoon / evening preset bands, plus custom
- [ ] Submit button
- [ ] Loading and error states
- [ ] On success, navigate back to feed and show a confirmation

**Acceptance:** A user can create a request in under 30 seconds.

---

## Task 3a.5 — Build feed screen with player cards
**Label:** `app`

- [ ] List of `FeedItemCard` widgets
- [ ] Each card shows: photo, display name, level (named), playstyle tag chips (top 2), club name, time window
- [ ] "Propose match" button on each card (wired in Phase 3c — Phase 3a leaves it as a placeholder)
- [ ] Empty state with a "Create your first request" CTA
- [ ] Loading skeleton
- [ ] Pull-to-refresh
- [ ] Filter bar at top: club, day

**Acceptance:** Feed renders correctly with 0, 1, and 20+ items on both platforms.

---

## Task 3a.6 — Realtime subscription for feed
**Label:** `supabase` + `app`

**Supabase side:**
- [ ] Enable Realtime on `match_requests` table for INSERT and UPDATE events
- [ ] Verify the realtime channel respects RLS

**App side:**
- [ ] In `MatchRequestRepository.observeFeed`, subscribe to the `match_requests` channel
- [ ] On insert: prepend to current list (after re-applying filters)
- [ ] On update (status change to non-open): remove from list
- [ ] Handle reconnect (network drop → reconnect → refetch)

**Acceptance:** A request created on Device A appears on Device B's feed within 3 seconds without manual refresh.

---

## Task 3a.7 — Cancel my request flow
**Label:** `app`

- [ ] "My requests" section visible at top of feed (if user has any open)
- [ ] Tap a request → bottom sheet with "Cancel request" action
- [ ] Confirmation dialog
- [ ] On cancel, request status → `cancelled`, removed from all feeds

**Acceptance:** A canceled request disappears from both the user's view and other users' feeds within 3 seconds.

---

## Phase 3a exit criteria

- ✅ `match_requests` table deployed with RLS
- ✅ Users can create, view, and cancel match requests
- ✅ Feed updates live across devices via Realtime
- ✅ Empty, loading, and error states handled
- ✅ All repository and ViewModel unit tests pass

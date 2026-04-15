# Phase 3b — Matching: Score

**Duration:** Days 10–12
**Goal:** The feed is ranked by a server-side compatibility score, not by recency.

**Prerequisites:** Phase 3a complete.

**Definition of done:** When a user opens the feed, the order reflects level + playstyle + reliability compatibility, computed by a Supabase Edge Function.

---

## Task 3b.1 — Migration: playstyle_pairings table + seed
**Label:** `supabase`

Migration: `0007_playstyle_pairings.sql`

- [ ] Create `playstyle_pairings` table per [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md)
- [ ] RLS: read-only for authenticated users
- [ ] Seed ~30 hand-coded entries in `/supabase/seed/playstyle_pairings.sql`. Examples:
  - (Aggressive, Consistent) → 90
  - (Aggressive, Defensive) → 85
  - (Aggressive, Aggressive) → 70
  - (Consistent, Consistent) → 75
  - (Defensive, Defensive) → 40
  - (Social, Competitive) → 20
  - (Competitive, Competitive) → 95
  - (NetPlayer, Defensive) → 80
  - (Lefty, anything) → +5 bonus or neutral
- [ ] Document the pairing logic in a comment at the top of the seed file
- [ ] Pairings are symmetric: insert both (A,B) and (B,A) for clarity, or query with a CASE

**Acceptance:** Table is populated. A query for any two playstyles returns a score.

---

## Task 3b.2 — Migration: soft_blocks table (forward-compat)
**Label:** `supabase`

Migration: `0008_soft_blocks.sql`

- [ ] Create `soft_blocks` table per data model
- [ ] RLS: users manage their own blocks
- [ ] Will remain empty in MVP (Phase 4 populates it from feedback)

**Acceptance:** Table exists; the matching function can query it without errors.

---

## Task 3b.3 — Build `score_feed` Edge Function
**Label:** `supabase`

Location: `/supabase/functions/score_feed/index.ts`

```typescript
// Pseudocode
serve(async (req) => {
  const { user_id } = await getUserFromJWT(req);
  const me = await loadProfile(user_id);

  const candidates = await loadOpenRequests({
    notCreatedBy: user_id,
    inClubs: me.home_club_ids,
    futureOnly: true,
    notSoftBlocked: user_id,
    intentCompatibleWith: me.intent,
  });

  const scored = candidates.map(c => {
    const levelScore = 100 - Math.min(100, Math.abs(me.calibrated_level - c.creator.calibrated_level) * 40);
    const playstyleScore = avgPairingScore(me.playstyle_tags, c.creator.playstyle_tags);
    const reliabilityScore = c.creator.reliability_score * 100;
    const total = 0.5 * levelScore + 0.25 * playstyleScore + 0.25 * reliabilityScore;
    return { ...c, score: total };
  });

  return scored.sort((a, b) => b.score - a.score).slice(0, 50);
});
```

- [ ] Validate caller from JWT (never trust a passed user_id)
- [ ] Apply hard filters before scoring (cheaper)
- [ ] Compute the weighted score
- [ ] Return top 50 sorted by score desc
- [ ] Log execution time for tuning

**Acceptance:** Function returns scored results in under 500ms for a feed of 100 candidates. Manual test with two seeded users shows clearly different scores.

---

## Task 3b.4 — Wire `FeedRepository` to call edge function
**Label:** `app`

- [ ] Add `getScoredFeed(filters: FeedFilters): Result<List<ScoredFeedItem>>` to repository
- [ ] `ScoredFeedItem` extends `FeedItem` with a `score: Double` field
- [ ] Replace the direct table query in `FeedViewModel` with the edge function call
- [ ] Fall back to unsorted feed query if the edge function errors (degraded mode, log the error)

**Acceptance:** The feed is sorted by score on both platforms. Manually verifying with seeded data shows the expected order.

---

## Task 3b.5 — Show subtle compatibility hint in feed cards
**Label:** `app`

Don't show the raw score (vanity metric), but give a soft signal:

- [ ] If `score >= 80`: green dot + "Great match"
- [ ] If `score >= 60`: yellow dot + "Good match"
- [ ] Else: no badge
- [ ] Keep it understated — this is meant as a nudge, not a leaderboard

**Acceptance:** Cards display the appropriate badge based on score.

---

## Task 3b.6 — Edge function deployment script
**Label:** `supabase`

- [ ] Add a `make deploy-functions` target or a script in `/supabase/scripts/deploy_functions.sh`
- [ ] Document deployment in `/supabase/README.md`
- [ ] Verify deployment with a test invocation

**Acceptance:** A single command deploys all edge functions to the live project.

---

## Phase 3b exit criteria

- ✅ Playstyle pairings seeded
- ✅ `score_feed` edge function deployed and returning sorted results
- ✅ Hard filters (club, time, blocks, intent) work correctly
- ✅ App calls the edge function and renders sorted feed
- ✅ Compatibility hint shown on cards
- ✅ Function execution stays under 500ms for realistic feed sizes

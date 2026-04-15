# Matchly — Product Definition

## Core product

A matchmaking app for padel players that learns what a good match looks like for you — right level, right style, right person who actually shows up — so your next game is the best one you've played this month.

The product is **not** a tracker, **not** a social network, and **not** a court booking tool. It is a trusted way to find your next good match.

## Why this exists

Existing apps solve adjacent problems but leave the core one open:

- **Playtomic** matches on level + availability. Produces a lot of mediocre matches: same "level," wrong style, frequent no-shows, casual doubles treated like Wimbledon.
- **WhatsApp club groups** are chaotic, slow, and exclude newcomers.
- **SwingVision and trackers** solve self-improvement, not match quality.

The unmet need is **compatibility**: level + playstyle + reliability + intent (competitive vs social). Matchly is built around that gap.

## Target user (launch)

**Padel players, ages 28–45, in one European city, intermediate level (Playtomic ~2.0–3.5), playing 1–3× per week, who have outgrown their immediate friend group.**

Geographic focus: **one padel-dense city** (Copenhagen for launch). Density matters more than market size — you need enough players within a 15-minute drive that liquidity is solvable club-by-club.

What they say today:
- "I booked a court but my partner bailed."
- "The guy was way better than his level said."
- "I don't know anyone who plays at 7am."
- "I want a regular hitting partner, not a different random every week."

Tennis comes later. Pick one sport, one city, one level band.

## Core value proposition

> *I open the app, I see people near me I'd actually enjoy playing, I book one, I show up.*

Everything in the MVP serves that moment. Anything that doesn't is cut.

## MVP scope (locked)

Three modules. Four features per module max. Two-week build target.

### 1. Login
Phone OTP. No passwords. Session persists.

### 2. Profile
60-second profile creation:
- Photo
- Display name
- Level (named picker, stored as numeric — see "Level system" below)
- Home club(s) — max 2, picked from a fixed seeded list
- Playstyle tags — max 3, from a fixed enum
- Intent — Competitive / Social / Both

### 3. Player Matching
- **Feed:** list of nearby open match requests, sorted by compatibility score
- **Create request:** pick club, date, time window — three fields, one screen
- **Propose & confirm:** one-tap proposal → push → one-tap accept
- **Upcoming strip:** confirmed matches at top of feed

### Out of MVP (do not build)
Post-match feedback, calibration loop, in-app chat, court booking, stats pages, doubles, tennis, public profiles, multi-city.

## Matchmaking logic (the edge)

Score = weighted sum, computed server-side in a Supabase Edge Function:

```
score = 0.5 * level_score
      + 0.25 * playstyle_score
      + 0.25 * reliability_score

level_score      = 100 - min(100, abs(my_level - their_level) * 40)
playstyle_score  = lookup in playstyle_pairings table
reliability_score = their_reliability * 100
```

**Hard filters before scoring:**
- Same club
- Time windows overlap
- Not soft-blocked
- Intent compatible (competitive↔competitive, social↔social, "both" matches anyone)

**Why server-side:** lets us tune the formula without shipping app updates. Also keeps the logic out of client tampering.

**Avoiding bad matches:**
- Soft-block on thumbs-down (60-day cooldown) — Phase 4
- Reliability score penalizes flakes — Phase 4
- First-match safety: prioritize safe pairings for new users until they have history

## Level system

**UI:** named picker with 8 levels.
**Storage:** numeric (2,1) field.

| Label | Numeric range | Stored midpoint |
|---|---|---|
| Beginner | 1.0–1.5 | 1.25 |
| Beginner+ | 1.5–2.0 | 1.75 |
| Intermediate | 2.0–2.5 | 2.25 |
| Intermediate+ | 2.5–3.0 | 2.75 |
| Advanced | 3.0–3.5 | 3.25 |
| Advanced+ | 3.5–4.0 | 3.75 |
| Competitive | 4.0–4.5 | 4.25 |
| Pro | 4.5–5.0 | 4.75 |

**Why both:** named labels are easier to self-select (people don't know if they're a 2.7), but numeric storage enables clean matching math, smooth calibration drift over time, and future compatibility with Playtomic / UTR / LTA imports. When the calibration loop ships in Phase 4, the system shifts the number invisibly until the user crosses a threshold — at which point you get a "You've leveled up to Advanced" moment that doubles as a retention hook.

## Playstyle tags (fixed enum)

Maximum 3 per user. Do not let this list grow:

- Aggressive
- Consistent
- Social
- Competitive
- Lefty
- PrefersDoubles
- Defensive
- NetPlayer

## Retention loop

The habit is the **weekly match cycle**, not the app itself. Users open the app 2–4× per week when planning sessions.

What pulls them back:
1. **A good first match.** 80% of retention. Over-engineer it. Hand-match the first 100 users if needed.
2. **Push notifications tied to real events only.** "Anna wants to play Saturday 10am at your club." Kill all vanity notifications.
3. **Regular partner nudge** (Phase 4+). After two good matches with the same person: "Want to make this weekly?"
4. **Visible liquidity at their club.** "12 players active at your club this week."

Explicitly **not** doing: streaks, gamification, leaderboards, achievements. Wrong genre.

## Competitive edge

- vs **Playtomic:** they're a booking platform that bolted on matching. Booking is their business; matching is a feature. Their revenue comes from court fees, so a mediocre match still books a court. Our whole product is match quality.
- vs **WhatsApp groups:** we solve cold-start for newcomers and reduce scheduling from a 40-message thread to one tap.
- vs **SwingVision and trackers:** different problem, different user moment. Not a competitor.

**Unfair advantage (compounds over 6+ months):** the reliability + playstyle dataset. Once we know which players are flaky, miscalibrated, and which pairings produce good matches, that data is not in Playtomic, not in any club system, and is hard to replicate because it requires both sides of a match to give feedback.

## Go-to-market (launch)

Forget digital ads. First 100 users come from the ground.

1. **One city, three clubs.** Copenhagen launch: Padel Club København, Padelhuset, Copenhagen Padel (or whichever 3 are densest within 15 minutes of each other).
2. **Walk in, talk to club managers.** Pitch as a partner-finding board for their members. Co-branded QR code at reception. Club managers care about court utilization, not apps.
3. **WhatsApp-to-app migration.** Get introduced to admins of the biggest player WhatsApp groups. Take the chaos off their hands.
4. **Two real events in month 1.** "Open Padel Night" — free, mixed levels, hand-matched on site using the app. Seeds the network with ~40 people per event.
5. **Anchor players.** Recruit 5–10 regulars per club (4+ sessions/week). Free premium, branded shirt. They generate match supply and make the feed feel alive.

**90-day goal:** 300 real users in one city with 60%+ week-4 retention. Not 10,000 users in 5 cities. If the loop doesn't work in one city, more cities won't save it.

## Risks (the ones that actually matter)

1. **Liquidity trap.** Empty feed → empty signups. Test before building: can you get 40+ active players in one club in 30 days?
2. **The first-match problem.** One bad match and the user is gone forever. Hand-match early users.
3. **Playtomic responds.** They could ship playstyle tags + reliability in a quarter. Mitigation: move fast, go deep in one market, build the dataset.
4. **Reliability feedback gets ignored.** If post-match completion is < 50%, the matching engine has nothing to learn from.
5. **Two-sided cold start.** MVP allows inviting by phone number with SMS fallback so a non-user can confirm without signing up first.
6. **Seasonality.** Northern Europe padel is seasonal. Don't launch in November. Aim for February–March.

**What to test before writing app code:** can you manually run the matching service via a single WhatsApp group for 30 days in one club, producing better matches than the club's current chaos? If yes, the product works and you're just automating it.

## Verdict on the original idea

The original idea was a tennis/padel performance tracking app. Research concluded that's a graveyard category — manual tracking has near-zero retention and the analytical players who would use it are already served by SwingVision or spreadsheets.

The pivot: **invert the product.** Lead with matchmaking (the social hook, the real pain point), let performance data accumulate as a byproduct in Phase 4. Tracking is the feature. Matching is the business.

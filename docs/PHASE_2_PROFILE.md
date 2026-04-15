# Phase 2 — Profile

**Duration:** Days 5–7
**Goal:** A user can create a complete profile in 60 seconds. Profile is the input to matching, so the schema and validation matter more than the visuals.

**Prerequisites:** Phase 1 complete.

**Definition of done:** A logged-in user fills out a profile (photo, name, level, club, playstyle, intent) and the data lands in Supabase with proper RLS protection. Other users see a limited public view.

---

## Task 2.1 — Migration: clubs table + seed
**Label:** `supabase`

Migration: `0002_clubs.sql`

- [ ] Create `clubs` table per [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md)
- [ ] Enable RLS, policy: any authenticated user can SELECT
- [ ] Seed 3 Copenhagen padel clubs in `/supabase/seed/clubs.sql`
- [ ] Apply seed via `psql` or Supabase CLI

**Acceptance:** `select * from clubs` returns 3 rows; unauthenticated requests are rejected.

---

## Task 2.2 — Migration: extend profiles with full schema
**Label:** `supabase`

Migration: `0003_profiles_extend.sql`

- [ ] ALTER TABLE `profiles` to add: `display_name`, `photo_url`, `home_club_ids` (uuid[]), `self_rated_level` (numeric(2,1)), `calibrated_level` (numeric(2,1)), `playstyle_tags` (text[]), `intent` (text), `reliability_score` (numeric(3,2) default 1.00)
- [ ] Add CHECK constraints from the data model doc
- [ ] Verify trigger from Phase 1 still works

**Acceptance:** Invalid data (level 6.0, 4 playstyle tags, intent='nonsense') is rejected by Postgres.

---

## Task 2.3 — Create `public_profiles` view
**Label:** `supabase`

Migration: `0004_public_profiles_view.sql`

- [ ] Create view per [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md)
- [ ] Grant SELECT to authenticated role
- [ ] Verify the view does NOT expose `phone`, `self_rated_level`, or `intent`

**Acceptance:** SQL test confirms phone is never returned by the view.

---

## Task 2.4 — Set up Storage bucket for profile photos
**Label:** `supabase`

Migration: `0010_storage_profile_photos.sql` (or set up via dashboard, then capture as SQL).

- [ ] Create `profile-photos` bucket
- [ ] Public read policy
- [ ] Authenticated upload policy: path must start with `{auth.uid()}/`
- [ ] Max file size: 2MB
- [ ] Allowed types: image/jpeg, image/png, image/webp

**Acceptance:** A test user can upload to their own folder but a forged path under another user's id is rejected.

---

## Task 2.5 — Define `Playstyle` enum in commonMain
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/domain/Playstyle.kt`

```kotlin
enum class Playstyle(val key: String, val displayName: String) {
    Aggressive("aggressive", "Aggressive"),
    Consistent("consistent", "Consistent"),
    Social("social", "Social"),
    Competitive("competitive", "Competitive"),
    Lefty("lefty", "Lefty"),
    PrefersDoubles("prefers_doubles", "Prefers doubles"),
    Defensive("defensive", "Defensive"),
    NetPlayer("net_player", "Net player"),
}
```

- [ ] Mapping helpers: `fromKey(String): Playstyle?`, `Set<Playstyle>.toKeys(): List<String>`
- [ ] Validation helper: `validate(tags: Set<Playstyle>)` enforces max 3

**Acceptance:** Unit tests cover mapping and validation.

---

## Task 2.6 — Define `Level` mapping in commonMain
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/domain/Level.kt`

```kotlin
enum class Level(
    val displayName: String,
    val numericMidpoint: Double,
    val range: ClosedFloatingPointRange<Double>,
) {
    Beginner("Beginner", 1.25, 1.0..1.5),
    BeginnerPlus("Beginner+", 1.75, 1.5..2.0),
    Intermediate("Intermediate", 2.25, 2.0..2.5),
    IntermediatePlus("Intermediate+", 2.75, 2.5..3.0),
    Advanced("Advanced", 3.25, 3.0..3.5),
    AdvancedPlus("Advanced+", 3.75, 3.5..4.0),
    Competitive("Competitive", 4.25, 4.0..4.5),
    Pro("Pro", 4.75, 4.5..5.0);

    companion object {
        fun fromNumeric(value: Double): Level =
            entries.first { value in it.range || (value == 5.0 && it == Pro) }
    }
}
```

- [ ] Helper to convert numeric ↔ named level
- [ ] Used by both UI (display) and persistence (numeric storage)

**Acceptance:** Unit tests verify round-trip mapping for all levels.

---

## Task 2.7 — Implement `ProfileRepository`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/data/profile/ProfileRepository.kt`

```kotlin
interface ProfileRepository {
    suspend fun getMyProfile(): Result<Profile>
    suspend fun updateProfile(update: ProfileUpdate): Result<Profile>
    suspend fun uploadPhoto(bytes: ByteArray, mimeType: String): Result<String>
    suspend fun getClubs(): Result<List<Club>>
}
```

- [ ] `Profile` and `ProfileUpdate` domain models
- [ ] DTO ↔ domain mappers
- [ ] Photo upload writes to `profile-photos/{userId}/avatar.jpg` and returns the public URL
- [ ] Wire into Koin

**Acceptance:** Repository unit tests with a fake Supabase client cover all methods.

---

## Task 2.8 — Implement `ProfileViewModel`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/presentation/profile/ProfileViewModel.kt`

States:
```kotlin
data class ProfileUiState(
    val isLoading: Boolean = false,
    val profile: ProfileFormState = ProfileFormState(),
    val clubs: List<Club> = emptyList(),
    val isSaving: Boolean = false,
    val error: String? = null,
    val savedSuccessfully: Boolean = false,
)

data class ProfileFormState(
    val displayName: String = "",
    val photoUrl: String? = null,
    val level: Level = Level.Intermediate,
    val homeClubIds: List<String> = emptyList(),
    val playstyleTags: Set<Playstyle> = emptySet(),
    val intent: Intent = Intent.Both,
)
```

- [ ] Load profile + clubs on init
- [ ] Field-level validation (name not blank, max 2 clubs, max 3 tags)
- [ ] Disable save button until valid
- [ ] Save action calls repository

**Acceptance:** Invalid input is blocked before reaching the network. Unit tests cover validation and save flow.

---

## Task 2.9 — Build profile edit screen (Android + iOS)
**Label:** `app`

Single scrollable screen with:

- [ ] Photo picker with current photo preview
- [ ] Display name text field
- [ ] Level: 8-button picker (Beginner → Pro), single select, shows current selection clearly
- [ ] Home clubs: multi-select chips (max 2)
- [ ] Playstyle: multi-select chips (max 3, disable others when 3 are picked)
- [ ] Intent: 3-button segmented control (Competitive / Social / Both)
- [ ] Save button at bottom

**Acceptance:** A new user can fill out and save a complete profile in under 60 seconds without confusion.

---

## Task 2.10 — Photo picker + upload integration
**Label:** `app`

- [ ] Android: use `ActivityResultContracts.PickVisualMedia`
- [ ] iOS: use `PhotosPicker` (SwiftUI)
- [ ] Compress to under 500KB on-device before upload
- [ ] Show upload progress overlay
- [ ] On success, update profile row with returned URL

**Acceptance:** Picking a photo on either platform uploads it and the photo persists across app restart.

---

## Task 2.11 — Profile completeness gate
**Label:** `app`

- [ ] After login, if the profile is missing required fields (display_name, level, at least 1 home_club, at least 1 playstyle, intent), force the user to the profile edit screen
- [ ] Once complete, route to the feed screen (placeholder until Phase 3a)

**Acceptance:** A new user cannot reach the feed until their profile is complete.

---

## Phase 2 exit criteria

- ✅ Profile schema deployed with constraints
- ✅ Public profiles view exposes only safe fields
- ✅ Storage bucket accepts uploads only to own folder
- ✅ A user can create a complete profile in under 60 seconds
- ✅ Profile completeness gates access to the feed
- ✅ All repository and ViewModel unit tests pass

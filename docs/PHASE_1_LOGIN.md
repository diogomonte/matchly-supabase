# Phase 1 — Login

**Duration:** Days 3–4
**Goal:** A user can sign in with their phone number in under 30 seconds, no password. Session persists across app restarts.

**Prerequisites:** Phase 0 complete.

**Definition of done:** Installing the app, entering a phone, getting a code via SMS, and verifying lands the user on an empty profile screen. Closing and reopening keeps them signed in.

---

## Task 1.1 — Enable phone OTP in Supabase
**Label:** `supabase`

- [ ] Enable Phone provider in Supabase Auth settings
- [ ] Configure SMS provider (MessageBird recommended for EU; Twilio also fine)
- [ ] Set OTP expiry to 5 minutes
- [ ] Test OTP delivery to a real phone via the Supabase dashboard
- [ ] Document SMS cost per message in `/supabase/README.md` for future budgeting

**Acceptance:** Triggering an OTP from the Supabase dashboard delivers an SMS to a real phone within 30 seconds.

---

## Task 1.2 — Create profiles table (minimal) + auto-create trigger
**Label:** `supabase`

Migration: `0003_profiles.sql` (note: `0002_clubs.sql` is in Phase 2 — that's fine, leave a gap or renumber later).

- [ ] Create `profiles` table with the columns from [`../product/DATA_MODEL.md`](../product/DATA_MODEL.md), but only `id`, `phone`, `created_at`, `updated_at` are required for Phase 1. The rest can be added in Phase 2's migration.
- [ ] Create `handle_new_user()` function and `on_auth_user_created` trigger
- [ ] Enable RLS on `profiles`
- [ ] Add policies:
  - SELECT own row: `auth.uid() = id`
  - UPDATE own row: `auth.uid() = id`

**Acceptance:** Signing up a new user via the Supabase dashboard auto-creates a row in `profiles`. Querying as another user returns empty.

---

## Task 1.3 — Implement `AuthRepository` in commonMain
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/data/auth/AuthRepository.kt`

```kotlin
interface AuthRepository {
    suspend fun sendOtp(phone: String): Result<Unit>
    suspend fun verifyOtp(phone: String, code: String): Result<Unit>
    suspend fun signOut(): Result<Unit>
    val sessionFlow: StateFlow<AuthSession?>
}
```

- [ ] Define `AuthSession` domain model (just `userId: String` for Phase 1)
- [ ] Implement using `supabase-kt` `auth` module
- [ ] Map errors to a sealed `AuthError` type: `InvalidPhone`, `InvalidCode`, `RateLimited`, `Network`, `Unknown`
- [ ] Wire into Koin module

**Acceptance:** Unit tests cover happy path and each error type.

---

## Task 1.4 — Implement `AuthViewModel`
**Label:** `app`

Location: `shared/src/commonMain/kotlin/com/matchly/presentation/auth/AuthViewModel.kt`

States:
```kotlin
sealed interface AuthUiState {
    object Idle : AuthUiState
    object SendingCode : AuthUiState
    data class CodeSent(val phone: String) : AuthUiState
    data class Verifying(val phone: String) : AuthUiState
    object Authenticated : AuthUiState
    data class Error(val error: AuthError, val previous: AuthUiState) : AuthUiState
}
```

- [ ] Expose `state: StateFlow<AuthUiState>`
- [ ] Actions: `sendCode(phone)`, `verifyCode(code)`, `resendCode()`, `dismissError()`
- [ ] Validation: phone must include country code
- [ ] Resend cooldown: 30 seconds

**Acceptance:** ViewModel unit tests cover all state transitions and the resend cooldown.

---

## Task 1.5 — Build phone entry screen (Android + iOS)
**Label:** `app`

- [ ] Compose screen for Android, SwiftUI for iOS
- [ ] Country code picker (default DK +45)
- [ ] Phone number input
- [ ] "Send code" button bound to ViewModel
- [ ] Loading spinner during `SendingCode` state
- [ ] Error alert on `Error` state with retry option

**Acceptance:** Entering a valid phone and tapping send transitions to the code entry screen.

---

## Task 1.6 — Build code verification screen (Android + iOS)
**Label:** `app`

- [ ] 6-digit code input (use OTP-friendly inputs on each platform)
- [ ] Auto-submit when 6 digits are entered
- [ ] "Resend code" button with 30s cooldown shown as countdown
- [ ] Error display
- [ ] On success, navigate to profile screen

**Acceptance:** Valid code authenticates and navigates. Invalid code shows error and lets user retry.

---

## Task 1.7 — Persist session across app restarts
**Label:** `app`

- [ ] Configure supabase-kt's session storage on Android (uses EncryptedSharedPreferences)
- [ ] Configure session storage on iOS (uses Keychain)
- [ ] On app launch, check `auth.currentSessionOrNull()` and route to Profile or Login accordingly
- [ ] Handle expired session: clear and route to Login

**Acceptance:** Logging in, force-quitting the app, and reopening lands directly on the profile screen.

---

## Task 1.8 — Auth-gated navigation
**Label:** `app`

- [ ] Replace Phase 0 debug toolbar with real navigation gating
- [ ] If `sessionFlow` is null → Login screen
- [ ] If `sessionFlow` is non-null → Profile screen (Phase 2 will replace this with the feed once a profile exists)
- [ ] Sign-out button on a placeholder profile screen for testing

**Acceptance:** Signing out returns the user to the login screen on both platforms.

---

## Phase 1 exit criteria

- ✅ Phone OTP works end-to-end on a real device
- ✅ Sessions persist across restarts
- ✅ A new auth signup auto-creates a profile row
- ✅ Auth state drives navigation
- ✅ All `AuthRepository` and `AuthViewModel` unit tests pass

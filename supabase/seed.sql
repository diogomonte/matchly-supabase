-- =============================================================================
-- Seed data for local development / E2E testing
-- Wiped and reapplied on every: npm run supabase:reset
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LOCAL DEV ONLY: disable RLS on all tables so the REST API is accessible
-- without a valid JWT. The anon key alone is sufficient.
-- seed.sql never runs on hosted Supabase, so this never affects production.
-- -----------------------------------------------------------------------------
ALTER TABLE public.clubs               DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles            DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_requests      DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches             DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_participants  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.playstyle_pairings  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.soft_blocks         DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens       DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 1. Auth users
--    Insert directly into auth.users; the on_auth_user_created trigger will
--    automatically create a matching row in public.profiles.
--
--    Test phones (use OTP at http://127.0.0.1:54324 to sign in):
--      Main tester  : +4511111111
--      Opponent     : +4522222222
--      Player C     : +4533333333
--      Player D     : +4544444444
--      Player E     : +4555555555
-- -----------------------------------------------------------------------------

INSERT INTO auth.users (
  id,
  instance_id,
  role,
  aud,
  phone,
  encrypted_password,
  phone_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin
) VALUES
  (
    'aaaaaaaa-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    '+4511111111', '', now(), now(), now(),
    '', '', '',
    '{"provider":"phone","providers":["phone"]}', '{}', false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    '+4522222222', '', now(), now(), now(),
    '', '', '',
    '{"provider":"phone","providers":["phone"]}', '{}', false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    '+4533333333', '', now(), now(), now(),
    '', '', '',
    '{"provider":"phone","providers":["phone"]}', '{}', false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    '+4544444444', '', now(), now(), now(),
    '', '', '',
    '{"provider":"phone","providers":["phone"]}', '{}', false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    '+4555555555', '', now(), now(), now(),
    '', '', '',
    '{"provider":"phone","providers":["phone"]}', '{}', false
  );

-- Also insert identity rows so PostgREST can resolve the provider
INSERT INTO auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '+4511111111', 'aaaaaaaa-0000-0000-0000-000000000001', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","phone":"+4511111111"}', 'phone', now(), now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000002', '+4522222222', 'aaaaaaaa-0000-0000-0000-000000000002', '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","phone":"+4522222222"}', 'phone', now(), now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000003', '+4533333333', 'aaaaaaaa-0000-0000-0000-000000000003', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003","phone":"+4533333333"}', 'phone', now(), now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000004', '+4544444444', 'aaaaaaaa-0000-0000-0000-000000000004', '{"sub":"aaaaaaaa-0000-0000-0000-000000000004","phone":"+4544444444"}', 'phone', now(), now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000005', '+4555555555', 'aaaaaaaa-0000-0000-0000-000000000005', '{"sub":"aaaaaaaa-0000-0000-0000-000000000005","phone":"+4555555555"}', 'phone', now(), now(), now());

-- -----------------------------------------------------------------------------
-- 2. Fill out profiles
--    Profiles were auto-created by the trigger with just id+phone.
--    Update them with realistic data.
-- -----------------------------------------------------------------------------

UPDATE public.profiles SET
  display_name      = 'Marco Rossi',
  self_rated_level  = 3.5,
  calibrated_level  = 3.5,
  playstyle_tags    = ARRAY['Aggressive', 'NetPlayer'],
  intent            = 'competitive',
  reliability_score = 1.00,
  home_club_ids     = ARRAY(SELECT id FROM public.clubs ORDER BY name LIMIT 2)
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000001';

UPDATE public.profiles SET
  display_name      = 'Anna Larsen',
  self_rated_level  = 3.5,
  calibrated_level  = 3.5,
  playstyle_tags    = ARRAY['Consistent', 'Defensive'],
  intent            = 'both',
  reliability_score = 0.98,
  home_club_ids     = ARRAY(SELECT id FROM public.clubs ORDER BY name LIMIT 1)
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000002';

UPDATE public.profiles SET
  display_name      = 'Lars Nielsen',
  self_rated_level  = 4.0,
  calibrated_level  = 4.0,
  playstyle_tags    = ARRAY['Competitive', 'Aggressive'],
  intent            = 'competitive',
  reliability_score = 0.95,
  home_club_ids     = ARRAY(SELECT id FROM public.clubs ORDER BY name LIMIT 2)
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000003';

UPDATE public.profiles SET
  display_name      = 'Sofie Andersen',
  self_rated_level  = 3.0,
  calibrated_level  = 3.0,
  playstyle_tags    = ARRAY['Social', 'Defensive'],
  intent            = 'social',
  reliability_score = 0.90,
  home_club_ids     = ARRAY(SELECT id FROM public.clubs ORDER BY name LIMIT 1 OFFSET 1)
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000004';

UPDATE public.profiles SET
  display_name      = 'Tobias Møller',
  self_rated_level  = 2.5,
  calibrated_level  = 2.5,
  playstyle_tags    = ARRAY['Social', 'Consistent'],
  intent            = 'social',
  reliability_score = 0.85,
  home_club_ids     = ARRAY(SELECT id FROM public.clubs ORDER BY name LIMIT 2 OFFSET 1)
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000005';

-- -----------------------------------------------------------------------------
-- 3. Open match requests
--    Several future windows so score_feed returns results when testing.
--    Using fixed UUIDs so they can be referenced in matches below.
-- -----------------------------------------------------------------------------

INSERT INTO public.match_requests (id, creator_id, club_id, proposed_window, status) VALUES
  -- Anna: tomorrow morning at Padel Club København
  (
    'bbbbbbbb-0000-0000-0000-000000000001',
    'aaaaaaaa-0000-0000-0000-000000000002',
    (SELECT id FROM public.clubs WHERE name = 'Padel Club København'),
    '[2026-04-19 09:00:00+00, 2026-04-19 11:00:00+00)',
    'open'
  ),
  -- Lars: Saturday at Padelhuset
  (
    'bbbbbbbb-0000-0000-0000-000000000002',
    'aaaaaaaa-0000-0000-0000-000000000003',
    (SELECT id FROM public.clubs WHERE name = 'Padelhuset'),
    '[2026-04-19 13:00:00+00, 2026-04-19 15:00:00+00)',
    'open'
  ),
  -- Sofie: Sunday afternoon at Copenhagen Padel Center
  (
    'bbbbbbbb-0000-0000-0000-000000000003',
    'aaaaaaaa-0000-0000-0000-000000000004',
    (SELECT id FROM public.clubs WHERE name = 'Copenhagen Padel Center'),
    '[2026-04-20 14:00:00+00, 2026-04-20 16:00:00+00)',
    'open'
  ),
  -- Tobias: Monday morning at Padelhuset
  (
    'bbbbbbbb-0000-0000-0000-000000000004',
    'aaaaaaaa-0000-0000-0000-000000000005',
    (SELECT id FROM public.clubs WHERE name = 'Padelhuset'),
    '[2026-04-21 08:00:00+00, 2026-04-21 10:00:00+00)',
    'open'
  ),
  -- Marco (main tester): also has an open request so others can see it
  (
    'bbbbbbbb-0000-0000-0000-000000000005',
    'aaaaaaaa-0000-0000-0000-000000000001',
    (SELECT id FROM public.clubs WHERE name = 'Padel Club København'),
    '[2026-04-22 10:00:00+00, 2026-04-22 12:00:00+00)',
    'open'
  );

-- -----------------------------------------------------------------------------
-- 4. A match in "pending" state
--    Lars proposed to Anna's request → Marco can see the outcome flow.
--    Anna's request (bbbb...001) is now "matched".
-- -----------------------------------------------------------------------------

INSERT INTO public.match_requests (id, creator_id, club_id, proposed_window, status) VALUES
  (
    'bbbbbbbb-0000-0000-0000-000000000006',
    'aaaaaaaa-0000-0000-0000-000000000002',
    (SELECT id FROM public.clubs WHERE name = 'Padel Club København'),
    '[2026-04-25 09:00:00+00, 2026-04-25 11:00:00+00)',
    'matched'
  );

INSERT INTO public.matches (id, request_id, host_id, club_id, scheduled_at, format, status) VALUES
  (
    'cccccccc-0000-0000-0000-000000000001',
    'bbbbbbbb-0000-0000-0000-000000000006',
    'aaaaaaaa-0000-0000-0000-000000000003',   -- Lars is host (he proposed)
    (SELECT id FROM public.clubs WHERE name = 'Padel Club København'),
    '2026-04-25 10:00:00+00',
    'singles',
    'pending'
  );

INSERT INTO public.match_participants (match_id, user_id, team, role, status) VALUES
  -- Lars (host): already confirmed
  ('cccccccc-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000003', 1, 'host',    'confirmed'),
  -- Anna (invited): still deciding
  ('cccccccc-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000002', 2, 'invited', 'pending');

-- -----------------------------------------------------------------------------
-- 5. A confirmed match (both players said yes)
-- -----------------------------------------------------------------------------

INSERT INTO public.match_requests (id, creator_id, club_id, proposed_window, status) VALUES
  (
    'bbbbbbbb-0000-0000-0000-000000000007',
    'aaaaaaaa-0000-0000-0000-000000000004',
    (SELECT id FROM public.clubs WHERE name = 'Padelhuset'),
    '[2026-04-27 13:00:00+00, 2026-04-27 15:00:00+00)',
    'matched'
  );

INSERT INTO public.matches (id, request_id, host_id, club_id, scheduled_at, format, status) VALUES
  (
    'cccccccc-0000-0000-0000-000000000002',
    'bbbbbbbb-0000-0000-0000-000000000007',
    'aaaaaaaa-0000-0000-0000-000000000005',   -- Tobias proposed
    (SELECT id FROM public.clubs WHERE name = 'Padelhuset'),
    '2026-04-27 14:00:00+00',
    'singles',
    'confirmed'
  );

INSERT INTO public.match_participants (match_id, user_id, team, role, status, responded_at) VALUES
  ('cccccccc-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000005', 1, 'host',    'confirmed', now()),
  ('cccccccc-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000004', 2, 'invited', 'confirmed', now());

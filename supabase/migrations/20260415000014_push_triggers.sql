-- Push notification triggers for the matching loop.
-- Uses pg_net (pre-installed in Supabase) to call edge functions via HTTP.
--
-- Required DB settings for production (set via Supabase Dashboard → Database → Settings,
-- or: ALTER DATABASE postgres SET app.settings.supabase_url = 'https://...';
--     ALTER DATABASE postgres SET app.settings.service_role_key = 'eyJ...';):
--
--   app.settings.supabase_url       — e.g. https://xyzproject.supabase.co
--   app.settings.service_role_key   — service role JWT
--
-- If either setting is absent the trigger silently no-ops, which is safe for
-- local development where push notifications are not wired up.

-- ── Trigger 1: match proposed (new invited participant) ───────────────────────

CREATE OR REPLACE FUNCTION public.handle_match_participant_invited()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _supabase_url      text;
  _service_role_key  text;
BEGIN
  _supabase_url     := current_setting('app.settings.supabase_url',    true);
  _service_role_key := current_setting('app.settings.service_role_key', true);

  IF _supabase_url IS NULL OR _service_role_key IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := _supabase_url || '/functions/v1/send_match_proposal_notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || _service_role_key
    ),
    body    := jsonb_build_object(
      'match_id',        NEW.match_id,
      'invited_user_id', NEW.user_id
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_match_participant_invited
  AFTER INSERT ON public.match_participants
  FOR EACH ROW
  WHEN (NEW.role = 'invited' AND NEW.status = 'pending')
  EXECUTE FUNCTION public.handle_match_participant_invited();

-- ── Trigger 2: match confirmed (status pending → confirmed) ───────────────────

CREATE OR REPLACE FUNCTION public.handle_match_status_confirmed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _supabase_url      text;
  _service_role_key  text;
BEGIN
  _supabase_url     := current_setting('app.settings.supabase_url',    true);
  _service_role_key := current_setting('app.settings.service_role_key', true);

  IF _supabase_url IS NULL OR _service_role_key IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := _supabase_url || '/functions/v1/send_match_confirmed_notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || _service_role_key
    ),
    body    := jsonb_build_object(
      'match_id', NEW.id
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_match_status_confirmed
  AFTER UPDATE ON public.matches
  FOR EACH ROW
  WHEN (OLD.status = 'pending' AND NEW.status = 'confirmed')
  EXECUTE FUNCTION public.handle_match_status_confirmed();

-- Migration: one match request per day trigger
-- Prevents a user from posting more than one match request per calendar day (UTC).
-- Raises SQLSTATE 23514 (check_violation) so PostgREST returns HTTP 409.

CREATE OR REPLACE FUNCTION public.check_one_match_request_per_day()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.match_requests
    WHERE creator_id = NEW.creator_id
      AND (created_at AT TIME ZONE 'UTC')::date = (now() AT TIME ZONE 'UTC')::date
  ) THEN
    RAISE EXCEPTION 'You can only post one match request per day'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER match_requests_one_per_day
  BEFORE INSERT ON public.match_requests
  FOR EACH ROW EXECUTE FUNCTION public.check_one_match_request_per_day();

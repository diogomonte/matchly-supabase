-- device_tokens: push notification routing for FCM (Android) and APNs (iOS).
-- One user can have multiple tokens (multiple devices / reinstalls).
-- Unique on (user_id, token) so upserts on reinstall don't create duplicates.

CREATE TABLE public.device_tokens (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  platform   text        NOT NULL,
  token      text        NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (user_id, token)
);

ALTER TABLE public.device_tokens
  ADD CONSTRAINT device_tokens_platform_values
    CHECK (platform IN ('android', 'ios'));

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens: select own"
  ON public.device_tokens
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "device_tokens: insert own"
  ON public.device_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens: update own"
  ON public.device_tokens
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens: delete own"
  ON public.device_tokens
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

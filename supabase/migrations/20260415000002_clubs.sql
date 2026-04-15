-- clubs: fixed seed list for Copenhagen launch. Read-only for users.

CREATE TABLE public.clubs (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  city       text NOT NULL,
  lat        numeric(9, 6) NOT NULL,
  lng        numeric(9, 6) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read clubs; no writes from clients
CREATE POLICY "clubs: authenticated read"
  ON public.clubs
  FOR SELECT
  TO authenticated
  USING (true);

-- Seed: 3 Copenhagen padel clubs
INSERT INTO public.clubs (id, name, city, lat, lng) VALUES
  (gen_random_uuid(), 'Padel Club København', 'Copenhagen', 55.706374, 12.577550),
  (gen_random_uuid(), 'Padelhuset',           'Copenhagen', 55.679706, 12.531920),
  (gen_random_uuid(), 'Copenhagen Padel Center', 'Copenhagen', 55.661890, 12.520740);

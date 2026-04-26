-- Migration: restrict public_profiles view to authenticated only

REVOKE SELECT ON public.public_profiles FROM anon;
REVOKE SELECT ON public.public_profiles FROM PUBLIC;

GRANT SELECT ON public.public_profiles TO authenticated;

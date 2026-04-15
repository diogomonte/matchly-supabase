-- Storage bucket for profile photos.
-- Public read; authenticated upload restricted to own folder ({uid}/*).

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Anyone can read profile photos (public bucket)
CREATE POLICY "profile-photos: public read"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile-photos');

-- Authenticated users may only upload to their own folder
CREATE POLICY "profile-photos: authenticated insert own folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Owners may update their own objects
CREATE POLICY "profile-photos: owner update"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Owners may delete their own objects
CREATE POLICY "profile-photos: owner delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

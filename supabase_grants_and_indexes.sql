-- Supabase RPC grants and performance indexes for TryMeYourPartner
-- Safe to run multiple times; IF NOT EXISTS guards used where supported.

-- 1) GRANT EXECUTE on SECURITY DEFINER RPCs used by the app
DO $$
BEGIN
  -- insert_shortlist(target_profile_id uuid)
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'insert_shortlist'
  ) THEN
    GRANT EXECUTE ON FUNCTION public.insert_shortlist(target_profile_id uuid)
    TO authenticated;
  END IF;

  -- insert_or_increment_view(target_profile_id uuid)
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'insert_or_increment_view'
  ) THEN
    GRANT EXECUTE ON FUNCTION public.insert_or_increment_view(target_profile_id uuid)
    TO authenticated;
  END IF;
END $$;

-- 2) Helpful indexes for common queries
-- matrimonial_profiles discovery queries
CREATE INDEX IF NOT EXISTS idx_mprofiles_last_active_at
  ON public.matrimonial_profiles (last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_mprofiles_created_at
  ON public.matrimonial_profiles (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mprofiles_state_id
  ON public.matrimonial_profiles (state_id);
CREATE INDEX IF NOT EXISTS idx_mprofiles_district_id
  ON public.matrimonial_profiles (district_id);
CREATE INDEX IF NOT EXISTS idx_mprofiles_caste_id
  ON public.matrimonial_profiles (caste_id);
CREATE INDEX IF NOT EXISTS idx_mprofiles_education
  ON public.matrimonial_profiles (education);
CREATE INDEX IF NOT EXISTS idx_mprofiles_occupation
  ON public.matrimonial_profiles (occupation);
CREATE INDEX IF NOT EXISTS idx_mprofiles_annual_income
  ON public.matrimonial_profiles (annual_income);
CREATE INDEX IF NOT EXISTS idx_mprofiles_date_of_birth
  ON public.matrimonial_profiles (date_of_birth);
CREATE INDEX IF NOT EXISTS idx_mprofiles_height_cm
  ON public.matrimonial_profiles (height_cm);

-- profile_views for viewers-of-me and my-viewed lists
CREATE INDEX IF NOT EXISTS idx_profile_views_viewer_last
  ON public.profile_views (viewer_profile_id, last_viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_profile_views_viewed_last
  ON public.profile_views (viewed_profile_id, last_viewed_at DESC);

-- shortlisted_profiles lookups
CREATE INDEX IF NOT EXISTS idx_shortlisted_profile
  ON public.shortlisted_profiles (profile_id);
CREATE INDEX IF NOT EXISTS idx_shortlisted_shortlisted
  ON public.shortlisted_profiles (shortlisted_profile_id);

-- Allow multiple messages between the same two profiles
-- Drops the old UNIQUE constraint on (from_profile_id, to_profile_id, interaction_type)
-- and replaces it with a partial UNIQUE index that excludes 'message' rows.

-- 1) Drop the auto-named unique constraint if it exists
ALTER TABLE public.profile_interactions
  DROP CONSTRAINT IF EXISTS profile_interactions_from_profile_id_to_profile_id_interact_key;

-- 2) Create a partial unique index for non-message interaction types only
CREATE UNIQUE INDEX IF NOT EXISTS uq_profile_interactions_non_message
  ON public.profile_interactions(from_profile_id, to_profile_id, interaction_type)
  WHERE interaction_type <> 'message';

-- 3) Optional: indexes to speed up message queries
CREATE INDEX IF NOT EXISTS idx_profile_interactions_msg_from
  ON public.profile_interactions(from_profile_id, created_at)
  WHERE interaction_type = 'message';

CREATE INDEX IF NOT EXISTS idx_profile_interactions_msg_to
  ON public.profile_interactions(to_profile_id, created_at)
  WHERE interaction_type = 'message';

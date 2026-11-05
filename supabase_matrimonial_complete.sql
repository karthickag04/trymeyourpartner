-- TryMeYourPartner - Complete Supabase SQL for Matrimonial App
-- Paste this into Supabase SQL Editor and run. Safe to re-run (uses IF NOT EXISTS and ON CONFLICT guards).

-- 1) Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2) Core reference tables
CREATE TABLE IF NOT EXISTS public.states (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.districts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  state_id UUID REFERENCES public.states(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(name, state_id)
);

CREATE TABLE IF NOT EXISTS public.castes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  religion VARCHAR(50),
  parent_id UUID REFERENCES public.castes(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3) Profiles and related tables
CREATE TABLE IF NOT EXISTS public.matrimonial_profiles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  profile_id VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  profile_image_url TEXT,
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female')),
  date_of_birth DATE NOT NULL,
  religion VARCHAR(50) NOT NULL,
  caste_id UUID REFERENCES public.castes(id),
  sub_caste_id UUID REFERENCES public.castes(id),
  state_id UUID REFERENCES public.states(id),
  district_id UUID REFERENCES public.districts(id),
  city VARCHAR(100),
  education VARCHAR(100),
  occupation VARCHAR(100),
  working_location VARCHAR(100),
  annual_income DECIMAL(12,2),
  marital_status VARCHAR(20) NOT NULL,
  about_me TEXT,
  family_details TEXT,
  partner_preferences TEXT,
  hobbies TEXT[],
  languages TEXT[],
  height_cm DECIMAL(5,2),
  weight_kg DECIMAL(5,2),
  physical_disability TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  is_profile_complete BOOLEAN DEFAULT FALSE,
  photo_urls TEXT[],
  total_views INTEGER DEFAULT 0,
  total_interests INTEGER DEFAULT 0,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.contact_info (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  phone_number VARCHAR(15),
  alternate_phone_number VARCHAR(15),
  whatsapp_number VARCHAR(15),
  current_address TEXT,
  permanent_address TEXT,
  show_phone BOOLEAN DEFAULT FALSE,
  show_address BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.family_info (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  father_name VARCHAR(100),
  father_occupation VARCHAR(100),
  mother_name VARCHAR(100),
  mother_occupation VARCHAR(100),
  number_of_brothers INTEGER DEFAULT 0,
  number_of_sisters INTEGER DEFAULT 0,
  family_type VARCHAR(20),
  family_values VARCHAR(20),
  family_status VARCHAR(30),
  family_details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.partner_preferences (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  min_age INTEGER,
  max_age INTEGER,
  min_height_cm DECIMAL(5,2),
  max_height_cm DECIMAL(5,2),
  preferred_states UUID[],
  preferred_districts UUID[],
  preferred_castes UUID[],
  preferred_education TEXT[],
  preferred_occupation TEXT[],
  min_income DECIMAL(12,2),
  max_income DECIMAL(12,2),
  preferred_marital_status TEXT[],
  other_preferences TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profile_interactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  from_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  to_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  interaction_type VARCHAR(20) NOT NULL CHECK (interaction_type IN ('interest', 'shortlist', 'contact', 'message', 'block')),
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_profile_id, to_profile_id, interaction_type)
);

CREATE TABLE IF NOT EXISTS public.profile_views (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  viewer_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  viewed_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  view_count INTEGER DEFAULT 1,
  last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(viewer_profile_id, viewed_profile_id)
);

CREATE TABLE IF NOT EXISTS public.shortlisted_profiles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  shortlisted_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_id, shortlisted_profile_id)
);

CREATE TABLE IF NOT EXISTS public.blocked_profiles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  blocked_profile_id UUID REFERENCES public.matrimonial_profiles(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_id, blocked_profile_id)
);

-- 4) RLS
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.castes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matrimonial_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shortlisted_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_profiles ENABLE ROW LEVEL SECURITY;

-- Locations public readable
DROP POLICY IF EXISTS "Public can read states" ON public.states;
CREATE POLICY "Public can read states" ON public.states FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read districts" ON public.districts;
CREATE POLICY "Public can read districts" ON public.districts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read castes" ON public.castes;
CREATE POLICY "Public can read castes" ON public.castes FOR SELECT USING (true);

-- Profiles: view active or own; insert/update/delete own
DROP POLICY IF EXISTS "Users can view profiles" ON public.matrimonial_profiles;
CREATE POLICY "Users can view profiles" ON public.matrimonial_profiles
  FOR SELECT USING (is_active = true OR auth.uid()::text = auth_user_id::text);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.matrimonial_profiles;
CREATE POLICY "Users can insert own profile" ON public.matrimonial_profiles
  FOR INSERT WITH CHECK (auth.uid()::text = auth_user_id::text);

DROP POLICY IF EXISTS "Users can update own profile" ON public.matrimonial_profiles;
CREATE POLICY "Users can update own profile" ON public.matrimonial_profiles
  FOR UPDATE USING (auth.uid()::text = auth_user_id::text) WITH CHECK (auth.uid()::text = auth_user_id::text);

DROP POLICY IF EXISTS "Users can delete own profile" ON public.matrimonial_profiles;
CREATE POLICY "Users can delete own profile" ON public.matrimonial_profiles
  FOR DELETE USING (auth.uid()::text = auth_user_id::text);

-- Contact info: owner only
DROP POLICY IF EXISTS "Users select own contact info" ON public.contact_info;
CREATE POLICY "Users select own contact info" ON public.contact_info
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = contact_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users insert own contact info" ON public.contact_info;
CREATE POLICY "Users insert own contact info" ON public.contact_info
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users update own contact info" ON public.contact_info;
CREATE POLICY "Users update own contact info" ON public.contact_info
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = contact_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users delete own contact info" ON public.contact_info;
CREATE POLICY "Users delete own contact info" ON public.contact_info
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = contact_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Family info: owner only
DROP POLICY IF EXISTS "Users select own family info" ON public.family_info;
CREATE POLICY "Users select own family info" ON public.family_info
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = family_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users insert own family info" ON public.family_info;
CREATE POLICY "Users insert own family info" ON public.family_info
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users update own family info" ON public.family_info;
CREATE POLICY "Users update own family info" ON public.family_info
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = family_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users delete own family info" ON public.family_info;
CREATE POLICY "Users delete own family info" ON public.family_info
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = family_info.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Partner preferences: owner only
DROP POLICY IF EXISTS "Users select own partner prefs" ON public.partner_preferences;
CREATE POLICY "Users select own partner prefs" ON public.partner_preferences
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = partner_preferences.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users insert own partner prefs" ON public.partner_preferences;
CREATE POLICY "Users insert own partner prefs" ON public.partner_preferences
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users update own partner prefs" ON public.partner_preferences;
CREATE POLICY "Users update own partner prefs" ON public.partner_preferences
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = partner_preferences.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Users delete own partner prefs" ON public.partner_preferences;
CREATE POLICY "Users delete own partner prefs" ON public.partner_preferences
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = partner_preferences.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Interactions: either participant can see/update/delete; only owner of from_profile can insert
DROP POLICY IF EXISTS "Interactions select by participants" ON public.profile_interactions;
CREATE POLICY "Interactions select by participants" ON public.profile_interactions
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
    WHERE (mp.id::text = profile_interactions.from_profile_id::text OR mp.id::text = profile_interactions.to_profile_id::text)
  AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Interactions insert by sender" ON public.profile_interactions;
CREATE POLICY "Interactions insert by sender" ON public.profile_interactions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matrimonial_profiles mp
      WHERE mp.id::text = from_profile_id::text
        AND mp.auth_user_id::text = auth.uid()::text
        AND mp.is_active = true
    )
    AND EXISTS (
      SELECT 1 FROM public.matrimonial_profiles tp
      WHERE tp.id::text = to_profile_id::text
        AND tp.is_active = true
    )
  );
DROP POLICY IF EXISTS "Interactions update by participants" ON public.profile_interactions;
CREATE POLICY "Interactions update by participants" ON public.profile_interactions
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
    WHERE (mp.id::text = profile_interactions.from_profile_id::text OR mp.id::text = profile_interactions.to_profile_id::text)
  AND mp.auth_user_id::text = auth.uid()::text
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
    WHERE (mp.id::text = from_profile_id::text OR mp.id::text = to_profile_id::text)
  AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Interactions delete by participants" ON public.profile_interactions;
CREATE POLICY "Interactions delete by participants" ON public.profile_interactions
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
    WHERE (mp.id::text = profile_interactions.from_profile_id::text OR mp.id::text = profile_interactions.to_profile_id::text)
  AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Views: viewer or viewed can select; viewer can insert/update/delete
DROP POLICY IF EXISTS "Views select by viewer or viewed" ON public.profile_views;
CREATE POLICY "Views select by viewer or viewed" ON public.profile_views
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
    WHERE (mp.id::text = profile_views.viewer_profile_id::text OR mp.id::text = profile_views.viewed_profile_id::text)
  AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Views insert by viewer" ON public.profile_views;
CREATE POLICY "Views insert by viewer" ON public.profile_views
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matrimonial_profiles mp
      WHERE mp.id::text = viewer_profile_id::text
        AND mp.auth_user_id::text = auth.uid()::text
        AND mp.is_active = true
    )
    AND EXISTS (
      SELECT 1 FROM public.matrimonial_profiles vp
      WHERE vp.id::text = viewed_profile_id::text
        AND vp.is_active = true
    )
  );
DROP POLICY IF EXISTS "Views update by viewer" ON public.profile_views;
CREATE POLICY "Views update by viewer" ON public.profile_views
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_views.viewer_profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = viewer_profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Views delete by viewer" ON public.profile_views;
CREATE POLICY "Views delete by viewer" ON public.profile_views
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_views.viewer_profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Shortlist: owner of profile_id
DROP POLICY IF EXISTS "Shortlist select by owner" ON public.shortlisted_profiles;
CREATE POLICY "Shortlist select by owner" ON public.shortlisted_profiles
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = shortlisted_profiles.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Shortlist insert by owner" ON public.shortlisted_profiles;
CREATE POLICY "Shortlist insert by owner" ON public.shortlisted_profiles
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matrimonial_profiles mp
      WHERE mp.id::text = profile_id::text
        AND mp.auth_user_id::text = auth.uid()::text
        AND mp.is_active = true
    )
    AND EXISTS (
      SELECT 1 FROM public.matrimonial_profiles sp
      WHERE sp.id::text = shortlisted_profile_id::text
        AND sp.is_active = true
    )
  );
DROP POLICY IF EXISTS "Shortlist delete by owner" ON public.shortlisted_profiles;
CREATE POLICY "Shortlist delete by owner" ON public.shortlisted_profiles
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = shortlisted_profiles.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- Blocks: owner of profile_id
DROP POLICY IF EXISTS "Blocks select by owner" ON public.blocked_profiles;
CREATE POLICY "Blocks select by owner" ON public.blocked_profiles
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = blocked_profiles.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Blocks insert by owner" ON public.blocked_profiles;
CREATE POLICY "Blocks insert by owner" ON public.blocked_profiles
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));
DROP POLICY IF EXISTS "Blocks delete by owner" ON public.blocked_profiles;
CREATE POLICY "Blocks delete by owner" ON public.blocked_profiles
  FOR DELETE USING (EXISTS (
    SELECT 1 FROM public.matrimonial_profiles mp
  WHERE mp.id::text = blocked_profiles.profile_id::text AND mp.auth_user_id::text = auth.uid()::text
  ));

-- 5) Indexes
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_gender ON public.matrimonial_profiles(gender);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_state ON public.matrimonial_profiles(state_id);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_district ON public.matrimonial_profiles(district_id);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_caste ON public.matrimonial_profiles(caste_id);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_age ON public.matrimonial_profiles(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_active ON public.matrimonial_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_districts_state ON public.districts(state_id);
CREATE INDEX IF NOT EXISTS idx_castes_religion ON public.castes(religion);
CREATE INDEX IF NOT EXISTS idx_profile_interactions_from ON public.profile_interactions(from_profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_interactions_to ON public.profile_interactions(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_views_viewer ON public.profile_views(viewer_profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_views_viewed ON public.profile_views(viewed_profile_id);
-- Ensure one profile per authenticated user
CREATE UNIQUE INDEX IF NOT EXISTS uniq_matrimonial_profiles_auth_user ON public.matrimonial_profiles(auth_user_id);

-- 6) Triggers and functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_states_updated_at ON public.states;
CREATE TRIGGER update_states_updated_at BEFORE UPDATE ON public.states FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_districts_updated_at ON public.districts;
CREATE TRIGGER update_districts_updated_at BEFORE UPDATE ON public.districts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_castes_updated_at ON public.castes;
CREATE TRIGGER update_castes_updated_at BEFORE UPDATE ON public.castes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_matrimonial_profiles_updated_at ON public.matrimonial_profiles;
CREATE TRIGGER update_matrimonial_profiles_updated_at BEFORE UPDATE ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_contact_info_updated_at ON public.contact_info;
CREATE TRIGGER update_contact_info_updated_at BEFORE UPDATE ON public.contact_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_family_info_updated_at ON public.family_info;
CREATE TRIGGER update_family_info_updated_at BEFORE UPDATE ON public.family_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_partner_preferences_updated_at ON public.partner_preferences;
CREATE TRIGGER update_partner_preferences_updated_at BEFORE UPDATE ON public.partner_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_profile_interactions_updated_at ON public.profile_interactions;
CREATE TRIGGER update_profile_interactions_updated_at BEFORE UPDATE ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enforce: don't allow interactions/messages to be created/updated targeting an inactive profile
-- This trigger runs as security definer so it can check the target profile state regardless of RLS
CREATE OR REPLACE FUNCTION enforce_target_profile_active()
RETURNS TRIGGER AS $$
BEGIN
  -- If there's a target profile set, ensure it exists and is active
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF (NEW.to_profile_id IS NOT NULL) THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.matrimonial_profiles mp
        WHERE mp.id = NEW.to_profile_id AND mp.is_active = true
      ) THEN
        RAISE EXCEPTION 'target profile is not active or does not exist';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS enforce_target_profile_active_trigger ON public.profile_interactions;
CREATE TRIGGER enforce_target_profile_active_trigger
  BEFORE INSERT OR UPDATE ON public.profile_interactions
  FOR EACH ROW EXECUTE FUNCTION enforce_target_profile_active();

-- NOTE: The trigger function is created with SECURITY DEFINER so it can validate target profile state
-- even when row-level security would normally prevent the current role from reading the profiles table.
-- Ensure the function owner is a trusted DB role (e.g., the DB owner) and audit privileges accordingly.

-- Unique profile id generator
CREATE OR REPLACE FUNCTION generate_profile_id()
RETURNS VARCHAR(20) AS $$
DECLARE
  new_id VARCHAR(20);
  id_exists BOOLEAN;
BEGIN
  LOOP
    new_id := 'MP' || LPAD((RANDOM() * 999999)::INT::TEXT, 6, '0');
    SELECT EXISTS(SELECT 1 FROM public.matrimonial_profiles WHERE profile_id = new_id) INTO id_exists;
    IF NOT id_exists THEN EXIT; END IF;
  END LOOP;
  RETURN new_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_profile_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.profile_id IS NULL OR NEW.profile_id = '' THEN
    NEW.profile_id := generate_profile_id();
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profile_id_trigger ON public.matrimonial_profiles;
CREATE TRIGGER set_profile_id_trigger BEFORE INSERT ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION set_profile_id();

-- Counters
CREATE OR REPLACE FUNCTION update_profile_views()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.matrimonial_profiles SET total_views = total_views + 1 WHERE id = NEW.viewed_profile_id;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profile_views_trigger ON public.profile_views;
CREATE TRIGGER update_profile_views_trigger AFTER INSERT ON public.profile_views FOR EACH ROW EXECUTE FUNCTION update_profile_views();

CREATE OR REPLACE FUNCTION update_interest_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.interaction_type = 'interest' THEN
    UPDATE public.matrimonial_profiles SET total_interests = total_interests + 1 WHERE id = NEW.to_profile_id;
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_interest_count_trigger ON public.profile_interactions;
CREATE TRIGGER update_interest_count_trigger AFTER INSERT ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION update_interest_count();

-- 7) Seed data (TN-first)
INSERT INTO public.states (name) VALUES 
('Tamil Nadu'),('Karnataka'),('Kerala'),('Andhra Pradesh'),('Telangana'),('Maharashtra'),('Gujarat'),('West Bengal'),('Delhi'),('Punjab')
ON CONFLICT (name) DO NOTHING;

WITH tn_state AS (SELECT id FROM public.states WHERE name = 'Tamil Nadu')
INSERT INTO public.districts (name, state_id)
SELECT district_name, tn_state.id FROM tn_state, (VALUES
('Chennai'),('Coimbatore'),('Madurai'),('Tiruchirappalli'),('Salem'),('Tirunelveli'),('Thanjavur'),('Vellore'),('Erode'),('Dindigul'),
('Cuddalore'),('Kanchipuram'),('Karur'),('Nagapattinam'),('Namakkal'),('Perambalur'),('Pudukkottai'),('Ramanathapuram'),('Sivaganga'),('Tenkasi'),
('Theni'),('Thiruvallur'),('Thiruvannamalai'),('Thiruvarur'),('Thoothukudi'),('Tiruppur'),('Viluppuram'),('Virudhunagar'),('Nilgiris'),('Krishnagiri'),
('Dharmapuri'),('Tirupathur'),('Ranipet'),('Kallakurichi'),('Chengalpattu'),('Mayiladuthurai'),('Ariyalur')
) AS districts(district_name)
ON CONFLICT (name, state_id) DO NOTHING;

INSERT INTO public.castes (name, religion) VALUES
('Brahmin','Hindu'),('Chettiar','Hindu'),('Mudaliar','Hindu'),('Pillai','Hindu'),('Reddy','Hindu'),('Naidu','Hindu'),('Thevar','Hindu'),('Gounder','Hindu'),('Vanniyar','Hindu'),('Yadav','Hindu'),
('Naicker','Hindu'),('Asari','Hindu'),('Achari','Hindu'),('Other','Hindu'),('Christian','Christian'),('Muslim','Muslim'),('Sikh','Sikh'),('Jain','Jain'),('Buddhist','Buddhist')
ON CONFLICT DO NOTHING;

-- 8) Views
CREATE OR REPLACE VIEW public.profile_summary AS
SELECT 
  mp.id,
  mp.profile_id,
  mp.name,
  mp.gender,
  EXTRACT(YEAR FROM AGE(mp.date_of_birth)) AS age,
  mp.education,
  mp.occupation,
  mp.annual_income,
  mp.height_cm,
  s.name AS state_name,
  d.name AS district_name,
  c.name AS caste_name,
  mp.profile_image_url,
  mp.is_verified,
  mp.total_views,
  mp.total_interests,
  mp.last_active_at
FROM public.matrimonial_profiles mp
LEFT JOIN public.states s ON mp.state_id = s.id
LEFT JOIN public.districts d ON mp.district_id = d.id
LEFT JOIN public.castes c ON mp.caste_id = c.id
WHERE mp.is_active = true;

CREATE OR REPLACE VIEW public.profile_matches AS
SELECT 
  p1.id AS profile_id,
  p2.id AS matched_profile_id,
  p2.profile_id AS matched_profile_code,
  p2.name AS matched_name,
  EXTRACT(YEAR FROM AGE(p2.date_of_birth)) AS matched_age,
  p2.education AS matched_education,
  p2.occupation AS matched_occupation,
  s.name AS matched_state,
  d.name AS matched_district,
  c.name AS matched_caste,
  p2.profile_image_url AS matched_image,
  CASE WHEN p1.district_id = p2.district_id THEN 1 WHEN p1.state_id = p2.state_id THEN 2 ELSE 3 END AS match_priority
FROM public.matrimonial_profiles p1
JOIN public.matrimonial_profiles p2 ON p1.id != p2.id
LEFT JOIN public.states s ON p2.state_id = s.id
LEFT JOIN public.districts d ON p2.district_id = d.id
LEFT JOIN public.castes c ON p2.caste_id = c.id
WHERE p1.is_active = true AND p2.is_active = true AND p1.gender != p2.gender AND p1.caste_id = p2.caste_id;

-- Idempotent helper to add a table to a publication only if it's not already a member
CREATE OR REPLACE FUNCTION public._add_table_to_publication_if_missing(
  pub_name TEXT,
  schema_name TEXT,
  table_name TEXT
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check membership using pg_publication_tables (available in Postgres >= 10)
  PERFORM 1 FROM pg_publication_tables
   WHERE pubname = pub_name
     AND schemaname = schema_name
     AND tablename = table_name;
  IF NOT FOUND THEN
    EXECUTE format('ALTER PUBLICATION %I ADD TABLE %I.%I', pub_name, schema_name, table_name);
  END IF;
EXCEPTION WHEN duplicate_object THEN
  -- Safe if a concurrent session added it just now
  NULL;
END;
$$;

-- Add realtime tables idempotently (safe to re-run)
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','states');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','districts');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','castes');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','matrimonial_profiles');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','contact_info');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','family_info');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','partner_preferences');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','profile_interactions');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','profile_views');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','shortlisted_profiles');
SELECT public._add_table_to_publication_if_missing('supabase_realtime','public','blocked_profiles');

-- 10) Storage buckets and basic policies (run once)
-- Buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars','avatars', true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos','profile-photos', true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('gallery','gallery', true)
ON CONFLICT (id) DO NOTHING;

-- Public read for the above buckets
DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;
CREATE POLICY "Public read avatars" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');
DROP POLICY IF EXISTS "Public read profile-photos" ON storage.objects;
CREATE POLICY "Public read profile-photos" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-photos');
DROP POLICY IF EXISTS "Public read gallery" ON storage.objects;
CREATE POLICY "Public read gallery" ON storage.objects
  FOR SELECT USING (bucket_id = 'gallery');

-- Authenticated can manage uploads in these buckets
DROP POLICY IF EXISTS "Auth write avatars" ON storage.objects;
CREATE POLICY "Auth write avatars" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars');
DROP POLICY IF EXISTS "Auth update avatars" ON storage.objects;
CREATE POLICY "Auth update avatars" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');
DROP POLICY IF EXISTS "Auth delete avatars" ON storage.objects;
CREATE POLICY "Auth delete avatars" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Auth write profile-photos" ON storage.objects;
CREATE POLICY "Auth write profile-photos" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-photos');
DROP POLICY IF EXISTS "Auth update profile-photos" ON storage.objects;
CREATE POLICY "Auth update profile-photos" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'profile-photos') WITH CHECK (bucket_id = 'profile-photos');
DROP POLICY IF EXISTS "Auth delete profile-photos" ON storage.objects;
CREATE POLICY "Auth delete profile-photos" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'profile-photos');

DROP POLICY IF EXISTS "Auth write gallery" ON storage.objects;
CREATE POLICY "Auth write gallery" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'gallery');
DROP POLICY IF EXISTS "Auth update gallery" ON storage.objects;
CREATE POLICY "Auth update gallery" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'gallery') WITH CHECK (bucket_id = 'gallery');
DROP POLICY IF EXISTS "Auth delete gallery" ON storage.objects;
CREATE POLICY "Auth delete gallery" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'gallery');

-- 11) Done
SELECT 'Supabase matrimonial schema setup complete' AS status;

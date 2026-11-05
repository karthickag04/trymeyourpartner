-- ADD MULTICASTE SUPPORT TO MATRIMONIAL PROFILES
-- This script adds multicaste preference support to the existing schema
-- Run this AFTER the main matrimonial schema is already set up

-- Step 1: Add multicaste columns to matrimonial_profiles table
DO $$
BEGIN
	-- Add multicaste preference column
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns 
		WHERE table_name = 'matrimonial_profiles' 
		AND column_name = 'accepts_other_castes'
	) THEN
		ALTER TABLE public.matrimonial_profiles 
		ADD COLUMN accepts_other_castes BOOLEAN DEFAULT FALSE;
		RAISE NOTICE 'Added accepts_other_castes column to matrimonial_profiles';
	ELSE
		RAISE NOTICE 'accepts_other_castes column already exists';
	END IF;

	-- Add preferred caste list (array of caste IDs they're open to)
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns 
		WHERE table_name = 'matrimonial_profiles' 
		AND column_name = 'preferred_other_castes'
	) THEN
		ALTER TABLE public.matrimonial_profiles 
		ADD COLUMN preferred_other_castes UUID[];
		RAISE NOTICE 'Added preferred_other_castes column to matrimonial_profiles';
	ELSE
		RAISE NOTICE 'preferred_other_castes column already exists';
	END IF;

	-- Add caste preference strictness level
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns 
		WHERE table_name = 'matrimonial_profiles' 
		AND column_name = 'caste_preference'
	) THEN
		ALTER TABLE public.matrimonial_profiles 
		ADD COLUMN caste_preference VARCHAR(20) DEFAULT 'same_caste' 
		CHECK (caste_preference IN ('same_caste', 'same_religion', 'no_preference'));
		RAISE NOTICE 'Added caste_preference column to matrimonial_profiles';
	ELSE
		RAISE NOTICE 'caste_preference column already exists';
	END IF;
END $$;

-- Step 2: Update existing profiles with realistic multicaste preferences
DO $$
DECLARE
	profile_record RECORD;
	caste_count INTEGER;
	same_religion_castes UUID[];
BEGIN
	RAISE NOTICE 'Updating existing profiles with multicaste preferences...';

	FOR profile_record IN 
		SELECT id, religion, caste_id FROM public.matrimonial_profiles 
	LOOP
		-- Get castes of the same religion
		SELECT ARRAY(
			SELECT id FROM public.castes 
			WHERE religion = profile_record.religion 
			AND id != profile_record.caste_id
			LIMIT 3
		) INTO same_religion_castes;

		-- Set multicaste preferences based on profile characteristics
		UPDATE public.matrimonial_profiles SET
			accepts_other_castes = CASE 
				WHEN EXTRACT(epoch FROM created_at)::integer % 3 = 0 THEN TRUE 
				ELSE FALSE 
			END,
			preferred_other_castes = CASE 
				WHEN EXTRACT(epoch FROM created_at)::integer % 3 = 0 THEN same_religion_castes
				ELSE NULL 
			END,
			caste_preference = CASE 
				WHEN EXTRACT(epoch FROM created_at)::integer % 4 = 0 THEN 'no_preference'
				WHEN EXTRACT(epoch FROM created_at)::integer % 4 = 1 THEN 'same_religion'
				ELSE 'same_caste'
			END
		WHERE id = profile_record.id;
	END LOOP;

	GET DIAGNOSTICS caste_count = ROW_COUNT;
	RAISE NOTICE 'Updated % profiles with multicaste preferences', caste_count;
END $$;

-- Step 3: Create improved matching views for gender and caste filtering
CREATE OR REPLACE VIEW public.profile_matches_improved AS
SELECT 
	p1.id AS profile_id,
	p1.name AS profile_name,
	p1.gender AS profile_gender,
	p2.id AS matched_profile_id,
	p2.profile_id AS matched_profile_code,
	p2.name AS matched_name,
	p2.gender AS matched_gender,
	EXTRACT(YEAR FROM AGE(p2.date_of_birth)) AS matched_age,
	p2.education AS matched_education,
	p2.occupation AS matched_occupation,
	p2.annual_income AS matched_income,
	p2.height_cm AS matched_height,
	s.name AS matched_state,
	d.name AS matched_district,
	c.name AS matched_caste,
	p2.religion AS matched_religion,
	p2.profile_image_url AS matched_image,
	p2.is_verified AS matched_verified,
	p2.last_active_at AS matched_last_active,
    
	-- Match scoring
	CASE 
		WHEN p1.district_id = p2.district_id THEN 3 -- Same district = highest priority
		WHEN p1.state_id = p2.state_id THEN 2       -- Same state = medium priority
		ELSE 1                                      -- Different state = low priority
	END AS location_match_score,
    
	-- Caste compatibility scoring
	CASE 
		WHEN p1.caste_id = p2.caste_id THEN 3                                    -- Same caste = highest
		WHEN p1.religion = p2.religion AND p1.caste_preference = 'same_religion' THEN 2  -- Same religion allowed
		WHEN p1.caste_preference = 'no_preference' THEN 1                        -- No caste preference
		WHEN p1.accepts_other_castes = TRUE AND p2.caste_id = ANY(p1.preferred_other_castes) THEN 2  -- Specific other castes allowed
		ELSE 0                                                                    -- Not compatible
	END AS caste_match_score,
    
	-- Overall match priority (higher = better match)
	(CASE 
		WHEN p1.district_id = p2.district_id THEN 3 
		WHEN p1.state_id = p2.state_id THEN 2 
		ELSE 1 
	END) +
	(CASE 
		WHEN p1.caste_id = p2.caste_id THEN 3                                    
		WHEN p1.religion = p2.religion AND p1.caste_preference = 'same_religion' THEN 2  
		WHEN p1.caste_preference = 'no_preference' THEN 1                        
		WHEN p1.accepts_other_castes = TRUE AND p2.caste_id = ANY(p1.preferred_other_castes) THEN 2  
		ELSE 0                                                                   
	END) AS total_match_score

FROM public.matrimonial_profiles p1
JOIN public.matrimonial_profiles p2 ON p1.id != p2.id
LEFT JOIN public.states s ON p2.state_id = s.id
LEFT JOIN public.districts d ON p2.district_id = d.id
LEFT JOIN public.castes c ON p2.caste_id = c.id
WHERE 
	p1.is_active = true 
	AND p2.is_active = true 
	AND p1.gender != p2.gender  -- Only opposite gender
	AND (
		-- Caste compatibility check
		p1.caste_id = p2.caste_id  -- Same caste always OK
		OR (p1.religion = p2.religion AND p1.caste_preference = 'same_religion')  -- Same religion if allowed
		OR p1.caste_preference = 'no_preference'  -- No caste restriction
		OR (p1.accepts_other_castes = TRUE AND p2.caste_id = ANY(p1.preferred_other_castes))  -- Specific other castes
	);

-- Step 4: Create district-wise caste grouping view for home screen
CREATE OR REPLACE VIEW public.home_matches_by_caste AS
SELECT 
	profile_id,
	profile_name,
	profile_gender,
	matched_district,
	matched_caste,
	caste_match_score,
	COUNT(*) as profiles_in_group,
	ARRAY_AGG(
		JSON_BUILD_OBJECT(
			'id', matched_profile_id,
			'name', matched_name,
			'age', matched_age,
			'occupation', matched_occupation,
			'education', matched_education,
			'income', matched_income,
			'height', matched_height,
			'image', matched_image,
			'verified', matched_verified,
			'last_active', matched_last_active
		) ORDER BY total_match_score DESC, matched_last_active DESC
	) as profiles_data
FROM public.profile_matches_improved
WHERE total_match_score > 0  -- Only show compatible matches
GROUP BY 
	profile_id, profile_name, profile_gender, matched_district, matched_caste, caste_match_score
ORDER BY 
	caste_match_score DESC,  -- Own caste first, then other compatible castes
	profiles_in_group DESC;  -- More profiles = better variety

-- Step 5: Update the simple profiles seed to include multicaste data
UPDATE public.matrimonial_profiles SET
	accepts_other_castes = CASE 
		WHEN EXTRACT(epoch FROM created_at)::integer % 3 = 0 THEN TRUE 
		ELSE FALSE 
	END,
	caste_preference = CASE 
		WHEN EXTRACT(epoch FROM created_at)::integer % 4 = 0 THEN 'no_preference'
		WHEN EXTRACT(epoch FROM created_at)::integer % 4 = 1 THEN 'same_religion'
		ELSE 'same_caste'
	END
WHERE email LIKE '%@example.com';

-- Step 6: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_caste_preference ON public.matrimonial_profiles(caste_preference);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_accepts_other_castes ON public.matrimonial_profiles(accepts_other_castes);
CREATE INDEX IF NOT EXISTS idx_matrimonial_profiles_gender_active ON public.matrimonial_profiles(gender, is_active);

-- Verification queries
SELECT 'MULTICASTE SUPPORT ADDED' as status;

SELECT 
	'Caste Preference Distribution' as info,
	caste_preference,
	COUNT(*) as count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM public.matrimonial_profiles 
WHERE is_active = true
GROUP BY caste_preference
ORDER BY count DESC;

SELECT 
	'Multicaste Acceptance' as info,
	accepts_other_castes,
	COUNT(*) as count
FROM public.matrimonial_profiles 
WHERE is_active = true
GROUP BY accepts_other_castes;

-- Sample of improved matching for first profile
SELECT 
	'Sample Improved Matches' as info,
	matched_name,
	matched_caste,
	matched_district,
	caste_match_score,
	location_match_score,
	total_match_score
FROM public.profile_matches_improved 
WHERE profile_id = (SELECT id FROM public.matrimonial_profiles WHERE is_active = true LIMIT 1)
ORDER BY total_match_score DESC, matched_name
LIMIT 10;

SELECT 'SUCCESS: Multicaste support added! Profiles now filter by gender and caste preferences.' as final_status;

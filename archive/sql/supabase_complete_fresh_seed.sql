-- COMPLETE FRESH SEED: Create auth users and matrimonial profiles from scratch
-- This script will:
-- 1. Clean all existing matrimonial data
-- 2. Create demo auth users in auth.users table
-- 3. Insert 50 matrimonial profiles with proper foreign key relationships
-- 4. Ensure all RLS policies are satisfied
-- Date: August 24, 2025

-- Step 1: Clean up all existing matrimonial data
DO $$
BEGIN
	RAISE NOTICE 'Starting complete cleanup of matrimonial data...';
    
	-- Delete all partner preferences
	DELETE FROM public.partner_preferences;
	RAISE NOTICE 'Deleted all partner preferences';
    
	-- Delete all family info
	DELETE FROM public.family_info;
	RAISE NOTICE 'Deleted all family info';
    
	-- Delete all contact info
	DELETE FROM public.contact_info;
	RAISE NOTICE 'Deleted all contact info';
    
	-- Delete all matrimonial profiles
	DELETE FROM public.matrimonial_profiles;
	RAISE NOTICE 'Deleted all matrimonial profiles';
    
	-- Note: We're not deleting from auth.users as that might affect the current user
	-- Instead, we'll create new demo users
    
	RAISE NOTICE 'Cleanup completed successfully';
END $$;

-- Step 2: Create demo auth users in auth.users table
-- This ensures the foreign key constraint is satisfied
DO $$
DECLARE
	demo_user_count INTEGER := 0;
	current_auth_id uuid := 'abea781f-77a6-424e-8a0f-663d1e2ee602'::uuid; -- Keep existing user
BEGIN
	RAISE NOTICE 'Creating 50 demo auth users...';
    
	-- Insert demo users into auth.users (if they don't already exist)
	-- Only include essential columns, avoiding generated columns
	INSERT INTO auth.users (
		id,
		instance_id,
		aud,
		role,
		email,
		encrypted_password,
		email_confirmed_at,
		created_at,
		updated_at,
		raw_app_meta_data,
		raw_user_meta_data,
		is_super_admin,
		last_sign_in_at
	)
	SELECT
		('00000000-0000-0000-0000-0000000000' || LPAD(i::text, 2, '0'))::uuid as id,
		'00000000-0000-0000-0000-000000000000'::uuid as instance_id,
		'authenticated' as aud,
		'authenticated' as role,
		('demouser' || i || '@matrimonial.demo') as email,
		crypt('demopassword123', gen_salt('bf')) as encrypted_password,
		NOW() as email_confirmed_at,
		NOW() as created_at,
		NOW() as updated_at,
		'{"provider": "email", "providers": ["email"]}' as raw_app_meta_data,
		'{}' as raw_user_meta_data,
		false as is_super_admin,
		NOW() as last_sign_in_at
	FROM generate_series(1, 50) AS s(i)
	ON CONFLICT (id) DO NOTHING; -- Don't insert if already exists
    
	GET DIAGNOSTICS demo_user_count = ROW_COUNT;
	RAISE NOTICE 'Created % new demo auth users', demo_user_count;
    
END $$;

-- Step 3: Insert matrimonial profiles with proper auth_user_id references
DO $$
DECLARE
	profile_count INTEGER := 0;
	contact_count INTEGER := 0;
	family_count INTEGER := 0;
	preference_count INTEGER := 0;
BEGIN
	RAISE NOTICE 'Starting matrimonial profile insertion...';
    
	-- Insert 50 matrimonial profiles with proper auth_user_id
	WITH tn AS (
		SELECT id AS state_id FROM public.states WHERE name = 'Tamil Nadu' LIMIT 1
	), tn_districts AS (
		SELECT d.id, ROW_NUMBER() OVER (ORDER BY d.name) AS rn
		FROM public.districts d
		JOIN tn ON tn.state_id = d.state_id
	), new_profiles AS (
		INSERT INTO public.matrimonial_profiles (
			auth_user_id,
			name,
			email,
			gender,
			date_of_birth,
			religion,
			caste_id,
			state_id,
			district_id,
			city,
			education,
			occupation,
			working_location,
			annual_income,
			marital_status,
			about_me,
			hobbies,
			languages,
			height_cm,
			weight_kg,
			is_active,
			is_verified,
			is_profile_complete,
			last_active_at
		)
		SELECT
			('00000000-0000-0000-0000-0000000000' || LPAD(i::text, 2, '0'))::uuid as auth_user_id,
			CASE WHEN (i % 2) = 1 THEN 'Arun Kumar ' || i ELSE 'Priya Sharma ' || i END as name,
			('demouser' || i || '@matrimonial.demo') as email,
			CASE WHEN (i % 2) = 1 THEN 'Male' ELSE 'Female' END as gender,
			(CURRENT_DATE - ((22 + (i % 15)) || ' years')::interval - ((i % 365) || ' days')::interval)::date as date_of_birth,
			CASE WHEN (i % 3) = 0 THEN 'Hindu' WHEN (i % 3) = 1 THEN 'Christian' ELSE 'Muslim' END as religion,
			COALESCE(
				CASE 
					WHEN (i % 3) = 0 THEN (
						SELECT id FROM public.castes 
						WHERE name IN ('Brahmin','Gounder','Vanniyar','Naidu','Pillai','Thevar','Yadav')
						ORDER BY name 
						LIMIT 1 OFFSET (i % 7)
					)
					WHEN (i % 3) = 1 THEN (SELECT id FROM public.castes WHERE name = 'Christian' LIMIT 1)
					ELSE (SELECT id FROM public.castes WHERE name = 'Muslim' LIMIT 1)
				END,
				(SELECT id FROM public.castes LIMIT 1) -- Fallback to first caste if none found
			) as caste_id,
			(SELECT state_id FROM tn) as state_id,
			COALESCE(
				(SELECT id FROM tn_districts WHERE rn = ((i % GREATEST((SELECT COUNT(*) FROM tn_districts), 1)) + 1)),
				(SELECT id FROM public.districts LIMIT 1) -- Fallback to first district
			) as district_id,
			CASE 
				WHEN (i % 6) = 0 THEN 'Chennai' 
				WHEN (i % 6) = 1 THEN 'Coimbatore' 
				WHEN (i % 6) = 2 THEN 'Madurai' 
				WHEN (i % 6) = 3 THEN 'Salem' 
				WHEN (i % 6) = 4 THEN 'Trichy'
				ELSE 'Erode'
			END as city,
			CASE 
				WHEN (i % 5) = 0 THEN 'B.E Computer Science' 
				WHEN (i % 5) = 1 THEN 'B.Com' 
				WHEN (i % 5) = 2 THEN 'MBA' 
				WHEN (i % 5) = 3 THEN 'MCA'
				ELSE 'B.Tech'
			END as education,
			CASE 
				WHEN (i % 5) = 0 THEN 'Software Engineer' 
				WHEN (i % 5) = 1 THEN 'Accountant' 
				WHEN (i % 5) = 2 THEN 'Manager' 
				WHEN (i % 5) = 3 THEN 'Designer'
				ELSE 'Teacher'
			END as occupation,
			CASE 
				WHEN (i % 4) = 0 THEN 'Bengaluru' 
				WHEN (i % 4) = 1 THEN 'Chennai' 
				WHEN (i % 4) = 2 THEN 'Hyderabad'
				ELSE 'Pune'
			END as working_location,
			(400000 + (i * 50000) + (i % 10) * 100000)::decimal(10,2) as annual_income, -- 4L to 15L range
			CASE 
				WHEN (i % 8) = 0 THEN 'Divorced' 
				WHEN (i % 8) = 1 THEN 'Widowed' 
				ELSE 'Never Married' 
			END as marital_status,
			CASE 
				WHEN (i % 3) = 0 THEN 'Simple, family-oriented person looking for a life partner who values relationships and traditions.'
				WHEN (i % 3) = 1 THEN 'Career-focused individual seeking a understanding partner for a happy married life.'
				ELSE 'Friendly and caring person with strong family values and modern outlook.'
			END as about_me,
			CASE 
				WHEN (i % 4) = 0 THEN ARRAY['Reading','Travel','Music','Cooking']
				WHEN (i % 4) = 1 THEN ARRAY['Sports','Movies','Photography','Dancing']
				WHEN (i % 4) = 2 THEN ARRAY['Art','Gardening','Yoga','Swimming']
				ELSE ARRAY['Technology','Books','Nature','Meditation']
			END::text[] as hobbies,
			ARRAY['Tamil','English','Hindi']::text[] as languages,
			CASE WHEN (i % 2) = 1 THEN (170 + (i % 20))::decimal(5,2) ELSE (155 + (i % 25))::decimal(5,2) END as height_cm,
			CASE WHEN (i % 2) = 1 THEN (65 + (i % 25))::decimal(5,2) ELSE (50 + (i % 30))::decimal(5,2) END as weight_kg,
			true as is_active,
			CASE WHEN (i % 5) = 0 THEN true ELSE false END as is_verified,
			true as is_profile_complete,
			NOW() - ((i % 30) || ' days')::interval as last_active_at
		FROM generate_series(1, 50) AS s(i)
		RETURNING id, auth_user_id, email, name
	)
	SELECT COUNT(*) INTO profile_count FROM new_profiles;
    
	RAISE NOTICE 'Inserted % matrimonial profiles', profile_count;
    
	-- Insert contact_info for all new profiles
	INSERT INTO public.contact_info (profile_id, show_phone, show_address)
	SELECT p.id, 
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 3 = 0 THEN true ELSE false END, -- Some show phone
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 0 THEN true ELSE false END  -- Some show address
	FROM public.matrimonial_profiles p
	WHERE p.email LIKE '%@matrimonial.demo';
    
	GET DIAGNOSTICS contact_count = ROW_COUNT;
	RAISE NOTICE 'Inserted % contact info records', contact_count;
    
	-- Insert family_info for all new profiles
	INSERT INTO public.family_info (
		profile_id, 
		family_type, 
		family_values, 
		family_status,
		father_occupation,
		mother_occupation,
		number_of_brothers,
		number_of_sisters
	)
	SELECT p.id,
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 3 = 0 THEN 'Nuclear' WHEN EXTRACT(epoch FROM p.created_at)::integer % 3 = 1 THEN 'Joint' ELSE 'Extended' END,
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 3 = 0 THEN 'Traditional' WHEN EXTRACT(epoch FROM p.created_at)::integer % 3 = 1 THEN 'Moderate' ELSE 'Liberal' END,
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 0 THEN 'Upper Middle Class' WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 1 THEN 'Middle Class' 
				WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 2 THEN 'Upper Class' ELSE 'Lower Middle Class' END,
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 5 = 0 THEN 'Business' WHEN EXTRACT(epoch FROM p.created_at)::integer % 5 = 1 THEN 'Government Service' 
				WHEN EXTRACT(epoch FROM p.created_at)::integer % 5 = 2 THEN 'Private Job' WHEN EXTRACT(epoch FROM p.created_at)::integer % 5 = 3 THEN 'Retired' ELSE 'Professional' END,
		   CASE WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 0 THEN 'Homemaker' WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 1 THEN 'Teacher' 
				WHEN EXTRACT(epoch FROM p.created_at)::integer % 4 = 2 THEN 'Government Service' ELSE 'Private Job' END,
		   (EXTRACT(epoch FROM p.created_at)::integer % 3)::integer, -- 0-2 brothers
		   (EXTRACT(epoch FROM p.created_at)::integer % 4)::integer  -- 0-3 sisters
	FROM public.matrimonial_profiles p
	WHERE p.email LIKE '%@matrimonial.demo';
    
	GET DIAGNOSTICS family_count = ROW_COUNT;
	RAISE NOTICE 'Inserted % family info records', family_count;
    
	-- Insert partner_preferences for all new profiles
	INSERT INTO public.partner_preferences (
		profile_id, 
		min_age, 
		max_age, 
		min_height_cm, 
		max_height_cm,
		preferred_education,
		preferred_occupation,
		preferred_marital_status,
		preferred_states,
		preferred_castes,
		min_income,
		max_income
	)
	SELECT p.id,
		   (21 + (EXTRACT(epoch FROM p.created_at)::integer % 5))::integer as min_age, -- 21-25
		   (28 + (EXTRACT(epoch FROM p.created_at)::integer % 7))::integer as max_age, -- 28-34
		   CASE WHEN p.gender = 'Male' THEN 150.0 ELSE 165.0 END as min_height_cm,
		   CASE WHEN p.gender = 'Male' THEN 190.0 ELSE 175.0 END as max_height_cm,
		   ARRAY['B.E','B.Tech','MBA','MCA','B.Com','M.Com']::text[],
		   ARRAY['Software Engineer','Manager','Teacher','Doctor','Accountant']::text[],
		   ARRAY['Never Married','Divorced']::text[],
		   ARRAY[p.state_id]::uuid[], -- Same state preference
		   ARRAY[p.caste_id]::uuid[], -- Same caste preference
		   400000.00::decimal(12,2) as min_income, -- 4L minimum
		   1500000.00::decimal(12,2) as max_income -- 15L maximum
	FROM public.matrimonial_profiles p
	WHERE p.email LIKE '%@matrimonial.demo';
    
	GET DIAGNOSTICS preference_count = ROW_COUNT;
	RAISE NOTICE 'Inserted % partner preference records', preference_count;
    
	RAISE NOTICE 'Successfully completed fresh seed with:';
	RAISE NOTICE '- % matrimonial profiles', profile_count;
	RAISE NOTICE '- % contact info records', contact_count;
	RAISE NOTICE '- % family info records', family_count;
	RAISE NOTICE '- % partner preference records', preference_count;
    
END $$;

-- Step 4: Verification queries
SELECT 'VERIFICATION RESULTS' as status;

-- Check auth users
SELECT 
	'Auth Users' as table_name,
	COUNT(*) as total_count,
	COUNT(CASE WHEN email LIKE '%@matrimonial.demo' THEN 1 END) as demo_users
FROM auth.users;

-- Check matrimonial profiles
SELECT 
	'Matrimonial Profiles' as table_name,
	COUNT(*) as total_count,
	COUNT(CASE WHEN auth_user_id IS NOT NULL THEN 1 END) as with_auth_id,
	COUNT(DISTINCT auth_user_id) as unique_auth_ids,
	COUNT(CASE WHEN is_profile_complete = true THEN 1 END) as complete_profiles
FROM public.matrimonial_profiles;

-- Check related tables
SELECT 'Contact Info' as table_name, COUNT(*) as record_count
FROM public.contact_info
UNION ALL
SELECT 'Family Info' as table_name, COUNT(*) as record_count
FROM public.family_info
UNION ALL
SELECT 'Partner Preferences' as table_name, COUNT(*) as record_count
FROM public.partner_preferences;

-- Show sample data
SELECT 
	'Sample Profiles' as info,
	p.name,
	p.email,
	p.gender,
	p.city,
	p.occupation,
	p.auth_user_id
FROM public.matrimonial_profiles p
WHERE p.email LIKE '%@matrimonial.demo'
ORDER BY p.email
LIMIT 5;

-- Final success message
SELECT 'SUCCESS: Complete fresh seed completed with 50 demo users and profiles' as final_status;

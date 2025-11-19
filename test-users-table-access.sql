-- Test users table access after fixes
-- Run this in your Supabase SQL Editor

-- Test if we can access users table
SELECT COUNT(*) as user_count FROM public.users;

-- Test if we can access a specific user
SELECT id, email, name, role, profile_image, avatar_url 
FROM public.users 
LIMIT 5;

-- Test if we can access jobs table
SELECT COUNT(*) as job_count FROM public.jobs;

-- Test if we can access jobs_with_admin view
SELECT COUNT(*) as jobs_with_admin_count FROM public.jobs_with_admin;

-- Check if all required columns exist in users table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY column_name;














-- Clean up all users table policies and create only necessary ones
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP ALL EXISTING POLICIES ON USERS TABLE
-- ==============================================

-- Drop all existing policies (comprehensive list)
DROP POLICY IF EXISTS "Allow all authenticated users to select users" ON public.users;
DROP POLICY IF EXISTS "Allow all authenticated users to insert users" ON public.users;
DROP POLICY IF EXISTS "Allow all authenticated users to update users" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.users;
DROP POLICY IF EXISTS "Drivers can view all users" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON public.users;
DROP POLICY IF EXISTS "Allow users to view their own data" ON public.users;
DROP POLICY IF EXISTS "Allow users to update their own data" ON public.users;
DROP POLICY IF EXISTS "Allow admins to view all users" ON public.users;
DROP POLICY IF EXISTS "Allow admins to update all users" ON public.users;
DROP POLICY IF EXISTS "Allow drivers to view all users" ON public.users;

-- ==============================================
-- CREATE CLEAN, MINIMAL POLICIES
-- ==============================================

-- Create only the essential policies
CREATE POLICY "users_select_policy"
    ON public.users FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "users_insert_policy"
    ON public.users FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "users_update_policy"
    ON public.users FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ==============================================
-- VERIFY CLEAN POLICIES
-- ==============================================

-- Check current policies (should only show 3 policies)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;

-- Test access
SELECT COUNT(*) as user_count FROM public.users;














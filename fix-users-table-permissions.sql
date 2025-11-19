-- Fix users table permissions and create missing RPC functions
-- Run this in your Supabase SQL Editor

-- ==============================================
-- FIX USERS TABLE PERMISSIONS
-- ==============================================

-- Check current RLS status on users table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Check current policies on users table
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

-- ==============================================
-- CREATE MISSING RPC FUNCTIONS
-- ==============================================

-- Create upsert_user_status function
CREATE OR REPLACE FUNCTION public.upsert_user_status(
    p_user_id uuid,
    p_is_online boolean,
    p_platform text DEFAULT NULL,
    p_platform_version text DEFAULT NULL,
    p_device_token text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert or update user status
    INSERT INTO public.user_status (
        user_id,
        is_online,
        platform,
        platform_version,
        device_token,
        last_seen,
        updated_at
    )
    VALUES (
        p_user_id,
        p_is_online,
        p_platform,
        p_platform_version,
        p_device_token,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        platform_version = EXCLUDED.platform_version,
        device_token = EXCLUDED.device_token,
        last_seen = NOW(),
        updated_at = NOW();
END;
$$;

-- Create compatible version for backward compatibility
CREATE OR REPLACE FUNCTION public.upsert_user_status_compat(
    p_user_id uuid,
    p_online boolean,
    p_platform text DEFAULT NULL,
    p_platform_version text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Call the main function with p_is_online parameter
    PERFORM public.upsert_user_status(
        p_user_id,
        p_online,
        p_platform,
        p_platform_version,
        NULL
    );
END;
$$;

-- Grant execute permissions on RPC functions
GRANT EXECUTE ON FUNCTION public.upsert_user_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_user_status_compat TO authenticated;

-- ==============================================
-- FIX USERS TABLE RLS POLICIES
-- ==============================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON public.users;
DROP POLICY IF EXISTS "Allow users to view their own data" ON public.users;
DROP POLICY IF EXISTS "Allow users to update their own data" ON public.users;
DROP POLICY IF EXISTS "Allow admins to view all users" ON public.users;
DROP POLICY IF EXISTS "Allow admins to update all users" ON public.users;
DROP POLICY IF EXISTS "Allow drivers to view all users" ON public.users;

-- Create comprehensive RLS policies for users table
CREATE POLICY "Users can view their own data"
    ON public.users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
    ON public.users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all users"
    ON public.users FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE public.users.id = auth.uid()
            AND public.users.role = 'admin'
        )
    );

CREATE POLICY "Admins can update all users"
    ON public.users FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE public.users.id = auth.uid()
            AND public.users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE public.users.id = auth.uid()
            AND public.users.role = 'admin'
        )
    );

CREATE POLICY "Drivers can view all users"
    ON public.users FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE public.users.id = auth.uid()
            AND public.users.role = 'driver'
        )
    );

-- ==============================================
-- VERIFY FIXES
-- ==============================================

-- Check RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Check policies
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

-- Check RPC functions
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%upsert_user_status%'
ORDER BY routine_name;
-- Fix users table access and add missing columns
-- Run this in your Supabase SQL Editor

-- ==============================================
-- ADD MISSING COLUMNS TO USERS TABLE
-- ==============================================

-- Add profile_image column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'profile_image'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.users ADD COLUMN profile_image text;
    END IF;
END $$;

-- Add other potentially missing columns
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'avatar_url'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.users ADD COLUMN avatar_url text;
    END IF;
END $$;

-- ==============================================
-- FIX USERS TABLE RLS POLICIES
-- ==============================================

-- Drop ALL existing policies on users table
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

-- Create very permissive policies to allow access
CREATE POLICY "Allow all authenticated users to select users"
    ON public.users FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow all authenticated users to insert users"
    ON public.users FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow all authenticated users to update users"
    ON public.users FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ==============================================
-- VERIFY FIXES
-- ==============================================

-- Check if profile_image column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
AND column_name IN ('profile_image', 'avatar_url')
ORDER BY column_name;

-- Check RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Check current policies
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














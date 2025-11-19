-- Fix signup by making the RLS policy more permissive for initial user creation
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP EXISTING POLICIES
-- ==============================================

DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated user to insert their own profile" ON users;

-- ==============================================
-- CREATE PERMISSIVE POLICIES FOR REGISTRATION
-- ==============================================

-- Allow users to view their own profile
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- More permissive INSERT policy for registration
-- This allows any authenticated user to insert, which should work after signup
CREATE POLICY "Allow authenticated users to insert"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ==============================================
-- VERIFY POLICIES
-- ==============================================

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
WHERE tablename = 'users' 
ORDER BY policyname;














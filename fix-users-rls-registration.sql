-- Fix users table RLS policies for registration
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP EXISTING POLICIES
-- ==============================================

DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON users;
DROP POLICY IF EXISTS "Allow any authenticated user to insert" ON users;

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

-- Allow authenticated users to insert their own profile (for registration)
CREATE POLICY "Allow authenticated users to insert own profile"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- ==============================================
-- VERIFY POLICIES
-- ==============================================

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
WHERE tablename = 'users' 
ORDER BY policyname;














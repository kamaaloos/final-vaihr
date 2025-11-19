-- Fix users table SELECT policy for fetchUserData
-- Run this in your Supabase SQL Editor

-- ==============================================
-- CHECK CURRENT POLICIES
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

-- ==============================================
-- DROP AND RECREATE SELECT POLICY
-- ==============================================

-- Drop existing SELECT policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON users;
DROP POLICY IF EXISTS "Authenticated users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;

-- Create a permissive SELECT policy for authenticated users
CREATE POLICY "Allow authenticated users to select"
    ON users FOR SELECT
    TO authenticated
    USING (true);

-- ==============================================
-- VERIFY POLICIES
-- ==============================================

-- Check updated policies
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














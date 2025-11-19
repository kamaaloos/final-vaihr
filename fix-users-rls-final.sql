-- Final fix for users table RLS policies to allow registration
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP ALL EXISTING POLICIES
-- ==============================================

DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Allow authenticated user to insert their own profile" ON users;
DROP POLICY IF EXISTS "Admins can insert all profiles" ON users;
DROP POLICY IF EXISTS "Admins can update all profiles" ON users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON users;
DROP POLICY IF EXISTS "Authenticated users can update own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can view own profile" ON users;
DROP POLICY IF EXISTS "Service role can update push token" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;

-- ==============================================
-- CREATE FINAL PERMISSIVE POLICIES
-- ==============================================

-- Allow any authenticated user to insert (for registration)
CREATE POLICY "Allow authenticated users to insert"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (true);

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














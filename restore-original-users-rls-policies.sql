-- Restore original users table RLS policies from old database
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP ALL EXISTING POLICIES
-- ==============================================

DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON users;
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
-- CREATE ORIGINAL POLICIES FROM OLD DATABASE
-- ==============================================

-- Admins can insert all profiles
CREATE POLICY "Admins can insert all profiles"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users users_1
            WHERE users_1.id = auth.uid()
            AND users_1.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles"
    ON users FOR UPDATE
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM auth.users users_1
            WHERE users_1.id = auth.uid()
            AND users_1.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Allow authenticated users access
CREATE POLICY "Allow authenticated users access"
    ON users FOR ALL
    TO public
    USING (auth.role() = 'authenticated');

-- Allow authenticated users to insert
CREATE POLICY "Allow authenticated users to insert"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow authenticated users to select
CREATE POLICY "Allow authenticated users to select"
    ON users FOR SELECT
    TO authenticated
    USING (true);

-- Allow authenticated users to update
CREATE POLICY "Allow authenticated users to update"
    ON users FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Authenticated users can update own profile
CREATE POLICY "Authenticated users can update own profile"
    ON users FOR UPDATE
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND id::uuid = auth.uid()
    );

-- Authenticated users can view own profile
CREATE POLICY "Authenticated users can view own profile"
    ON users FOR SELECT
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND id::uuid = auth.uid()
    );

-- Service role can update push token
CREATE POLICY "Service role can update push token"
    ON users FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Users can view own data
CREATE POLICY "Users can view own data"
    ON users FOR SELECT
    TO public
    USING (auth.uid() = id::uuid);

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














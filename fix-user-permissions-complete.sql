-- Complete fix for user permissions
-- This script ensures all authenticated users can access their data

-- First, let's disable RLS temporarily to fix the policies
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_status DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Admins can update all profiles" ON users;
DROP POLICY IF EXISTS "Admins can insert all profiles" ON users;
DROP POLICY IF EXISTS "Admins can view all statuses" ON user_status;
DROP POLICY IF EXISTS "Admins can update all statuses" ON user_status;
DROP POLICY IF EXISTS "Admins can insert all statuses" ON user_status;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;

-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Create policies that allow all authenticated users to access their own data
-- This is more permissive and should work for all users

-- Users table policies
CREATE POLICY "Authenticated users can view own profile" ON users
    FOR SELECT USING (auth.uid() IS NOT NULL AND id::uuid = auth.uid());

CREATE POLICY "Authenticated users can update own profile" ON users
    FOR UPDATE USING (auth.uid() IS NOT NULL AND id::uuid = auth.uid());

CREATE POLICY "Authenticated users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND id::uuid = auth.uid());

-- User_status table policies
CREATE POLICY "Authenticated users can view own status" ON user_status
    FOR SELECT USING (auth.uid() IS NOT NULL AND user_id::uuid = auth.uid());

CREATE POLICY "Authenticated users can update own status" ON user_status
    FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id::uuid = auth.uid());

CREATE POLICY "Authenticated users can insert own status" ON user_status
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id::uuid = auth.uid());

-- Admin policies (for admin users)
CREATE POLICY "Admins can view all profiles" ON users
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update all profiles" ON users
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can insert all profiles" ON users
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can view all statuses" ON user_status
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update all statuses" ON user_status
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can insert all statuses" ON user_status
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

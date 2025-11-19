-- Simple fix for database permissions
-- This script creates clean RLS policies

-- Drop all existing policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Admins can manage all statuses" ON user_status;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;

-- Create admin policies
CREATE POLICY "Admins can view all profiles" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can manage all statuses" ON user_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create user policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (id = auth.uid()::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid()::text);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (id = auth.uid()::text);

-- Create user policies for user_status table
CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (user_id = auth.uid()::text);

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

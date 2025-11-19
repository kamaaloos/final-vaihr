-- Complete database permissions fix
-- This script fixes RLS policies for both users and user_status tables

-- ==============================================
-- FIX USERS TABLE PERMISSIONS
-- ==============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Create new policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- FIX USER_STATUS TABLE PERMISSIONS
-- ==============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;

-- Create new policies for user_status table
CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, UPDATE, INSERT ON users TO authenticated;
GRANT SELECT, UPDATE, INSERT ON user_status TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Check if policies were created successfully
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status');

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

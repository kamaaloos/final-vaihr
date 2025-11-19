-- Simple and direct RLS policy fix
-- This approach uses simpler policies that should work reliably

-- ==============================================
-- DISABLE RLS TEMPORARILY TO CLEAN UP
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_status DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;
DROP POLICY IF EXISTS "Admins can view all user status" ON user_status;
DROP POLICY IF EXISTS "Admins can update all user status" ON user_status;

-- ==============================================
-- CREATE SIMPLE POLICIES
-- ==============================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Simple policy: Allow all authenticated users to access users table
CREATE POLICY "Allow authenticated users access" ON users
    FOR ALL USING (auth.role() = 'authenticated');

-- Simple policy: Allow all authenticated users to access user_status table  
CREATE POLICY "Allow authenticated users access" ON user_status
    FOR ALL USING (auth.role() = 'authenticated');

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, UPDATE, INSERT ON users TO authenticated;
GRANT SELECT, UPDATE, INSERT ON user_status TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- ==============================================
-- VERIFICATION
-- ==============================================

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status');

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

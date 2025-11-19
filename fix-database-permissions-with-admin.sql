-- Complete database permissions fix with admin support
-- This script fixes RLS policies for both users and user_status tables
-- Includes proper admin access while maintaining user security

-- ==============================================
-- FIX USERS TABLE PERMISSIONS (WITH ADMIN SUPPORT)
-- ==============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Create policies for users table
-- Regular users can only access their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id);

-- Admins can access all user data
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid()::text 
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- FIX USER_STATUS TABLE PERMISSIONS (WITH ADMIN SUPPORT)
-- ==============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;
DROP POLICY IF EXISTS "Admins can view all user status" ON user_status;
DROP POLICY IF EXISTS "Admins can update all user status" ON user_status;

-- Create policies for user_status table
-- Regular users can only access their own status
CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Admins can access all user status data
CREATE POLICY "Admins can view all user status" ON user_status
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid()::text 
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update all user status" ON user_status
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid()::text 
            AND role = 'admin'
        )
    );

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
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

-- Test admin check function (optional)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid()::text 
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

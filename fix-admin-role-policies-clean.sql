-- Clean fix for admin role policies
-- This script fixes the RLS policies to check admin role from the correct location

-- ==============================================
-- DROP EXISTING PROBLEMATIC POLICIES
-- ==============================================

-- Drop admin policies that check users.role (incorrect location)
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Admins can manage all statuses" ON user_status;

-- Drop user policies to recreate them cleanly
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;

-- ==============================================
-- CREATE CORRECT ADMIN POLICIES
-- ==============================================

-- Admin policies that check auth.users for admin role
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

-- ==============================================
-- CREATE USER POLICIES
-- ==============================================

-- User policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id);

-- User policies for user_status table
CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- ==============================================
-- VERIFICATION
-- ==============================================

-- Check that policies were created correctly
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

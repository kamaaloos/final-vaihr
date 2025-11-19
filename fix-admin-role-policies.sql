-- Fix admin role policies to check the correct location
-- This preserves all existing functionality while fixing the permission issues

-- ==============================================
-- UPDATE EXISTING POLICIES TO CHECK CORRECT ADMIN ROLE
-- ==============================================

-- Drop the problematic admin policies that check users.role
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Admins can manage all statuses" ON user_status;

-- Create new admin policies that check auth.users for admin role
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
-- ENSURE BASIC USER POLICIES EXIST
-- ==============================================

-- Drop existing user policies first, then recreate them
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own status" ON user_status;
DROP POLICY IF EXISTS "Users can update own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert own status" ON user_status;

-- Create basic user policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id);

CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- ==============================================
-- VERIFICATION
-- ==============================================

-- Check final policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

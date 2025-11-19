-- Clean up all conflicting RLS policies and create simple working ones

-- ==============================================
-- DISABLE RLS AND DROP ALL POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_status DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies for users table
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role can update push token" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON users;

-- Drop ALL existing policies for user_status table
DROP POLICY IF EXISTS "Admins can create user status records" ON user_status;
DROP POLICY IF EXISTS "Admins can manage all statuses" ON user_status;
DROP POLICY IF EXISTS "Users can insert their own status" ON user_status;
DROP POLICY IF EXISTS "Users can update their own status" ON user_status;
DROP POLICY IF EXISTS "user_status_insert_policy" ON user_status;
DROP POLICY IF EXISTS "Users can view their own status" ON user_status;
DROP POLICY IF EXISTS "user_status_select_policy" ON user_status;
DROP POLICY IF EXISTS "user_status_update_policy" ON user_status;
DROP POLICY IF EXISTS "Allow authenticated users access" ON user_status;

-- ==============================================
-- ENABLE RLS AND CREATE SIMPLE POLICIES
-- ==============================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Create simple policies for users table
CREATE POLICY "users_all_access" ON users
    FOR ALL USING (auth.role() = 'authenticated');

-- Create simple policies for user_status table
CREATE POLICY "user_status_all_access" ON user_status
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

-- Check final policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

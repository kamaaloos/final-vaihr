-- Minimal fix for database permissions
-- Drop all existing policies first
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

CREATE POLICY "Admins can view all statuses" ON user_status
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update all statuses" ON user_status
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can insert all statuses" ON user_status
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create user policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (id::uuid = auth.uid());

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id::uuid = auth.uid());

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (id::uuid = auth.uid());

-- Create user policies for user_status table
CREATE POLICY "Users can view own status" ON user_status
    FOR SELECT USING (user_id::uuid = auth.uid());

CREATE POLICY "Users can update own status" ON user_status
    FOR UPDATE USING (user_id::uuid = auth.uid());

CREATE POLICY "Users can insert own status" ON user_status
    FOR INSERT WITH CHECK (user_id::uuid = auth.uid());

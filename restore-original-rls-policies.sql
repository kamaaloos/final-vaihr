-- Restore original working RLS policies
-- This will restore the policies that were working before OTP changes

-- Enable RLS on both tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies (clean slate)
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view their own status" ON user_status;
DROP POLICY IF EXISTS "Users can update their own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert their own status" ON user_status;
DROP POLICY IF EXISTS "Admins can view all statuses" ON user_status;
DROP POLICY IF EXISTS "Admins can manage all statuses" ON user_status;
DROP POLICY IF EXISTS "user_status_select_policy" ON user_status;
DROP POLICY IF EXISTS "user_status_update_policy" ON user_status;
DROP POLICY IF EXISTS "user_status_insert_policy" ON user_status;

-- Restore original users table policies
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    TO authenticated
    USING (id::text = auth.uid()::text);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (id::text = auth.uid()::text)
    WITH CHECK (id::text = auth.uid()::text);

CREATE POLICY "Admins can view all profiles"
    ON users FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Service role has full access to users"
    ON users
    FOR ALL
    USING (true);

-- Restore original user_status table policies
CREATE POLICY "Users can view their own status"
    ON user_status FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own status"
    ON user_status FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own status"
    ON user_status FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all statuses"
    ON user_status FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Verify the policies are restored
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

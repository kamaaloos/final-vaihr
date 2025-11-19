-- Remove OTP system from database
-- This will clean up all OTP-related tables and policies

-- Drop OTP-related policies
DROP POLICY IF EXISTS "OTP users can access users table" ON users;
DROP POLICY IF EXISTS "OTP users can access user_status table" ON user_status;
DROP POLICY IF EXISTS "OTP users can access jobs table" ON jobs;
DROP POLICY IF EXISTS "OTP verified users can access their data" ON users;
DROP POLICY IF EXISTS "OTP verified users can access their status" ON user_status;

-- Drop OTP table
DROP TABLE IF EXISTS otp_codes CASCADE;

-- Drop OTP-related functions
DROP FUNCTION IF EXISTS is_otp_verified(TEXT);
DROP FUNCTION IF EXISTS cleanup_expired_otps();

-- Restore original working policies (from the migration files)
-- Drop all existing policies first
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view their own status" ON user_status;
DROP POLICY IF EXISTS "Users can update their own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert their own status" ON user_status;
DROP POLICY IF EXISTS "Admins can view all statuses" ON user_status;
DROP POLICY IF EXISTS "Allow authenticated users access" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Authenticated users can view own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can update own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can view own status" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can update own status" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can insert own status" ON user_status;
DROP POLICY IF EXISTS "Admins can create user status records" ON user_status;
DROP POLICY IF EXISTS "Admins can insert all statuses" ON user_status;
DROP POLICY IF EXISTS "Admins can update all statuses" ON user_status;

-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Create original working policies
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

-- Verify the cleanup
SELECT 'OTP cleanup completed' as status;

-- Fix RLS policies for user_status table
-- This allows authenticated users to manage their own online status

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

-- Grant necessary permissions
GRANT SELECT, UPDATE, INSERT ON user_status TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Restore database permissions for authenticated users
-- This ensures all authenticated users can access their data

-- Disable RLS temporarily to clean up
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_status DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Allow authenticated users access" ON users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON user_status;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Create simple policies that allow all authenticated users
CREATE POLICY "Allow authenticated users access" ON users
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users access" ON user_status
    FOR ALL USING (auth.role() = 'authenticated');

-- Grant necessary permissions
GRANT SELECT, UPDATE, INSERT ON users TO authenticated;
GRANT SELECT, UPDATE, INSERT ON user_status TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Verify policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status');

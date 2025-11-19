-- Fix user registration by making INSERT policy more permissive
-- This allows new users to be created during registration

-- Drop existing restrictive INSERT policies
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can insert all profiles" ON users;

-- Create a more permissive INSERT policy for user registration
CREATE POLICY "Allow user registration"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Also ensure service role can insert (for system operations)
CREATE POLICY "Service role can insert users"
    ON users FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Verify the new policies
SELECT 
    policyname,
    cmd,
    roles,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND cmd = 'INSERT';

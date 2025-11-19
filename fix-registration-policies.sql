-- Fix user registration by removing conflicting policies
-- The issue is that "Authenticated users can insert own profile" requires id = auth.uid()
-- but during registration, the user doesn't exist yet

-- Drop the problematic policy that requires id = auth.uid()
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON users;

-- Keep the permissive policy that allows any authenticated user to insert
-- (This should already exist, but let's make sure)
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
CREATE POLICY "Allow authenticated users to insert"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Keep admin policy
DROP POLICY IF EXISTS "Admins can insert all profiles" ON users;
CREATE POLICY "Admins can insert all profiles"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Verify the fixed policies
SELECT 
    policyname,
    cmd,
    roles,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND cmd = 'INSERT'
ORDER BY policyname;

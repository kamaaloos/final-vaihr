-- Check current RLS policies on users table
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Check if RLS is enabled on users table
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users';

-- Check what roles can access the users table
SELECT 
    policyname,
    roles,
    cmd as operation,
    qual as condition
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY cmd, policyname;

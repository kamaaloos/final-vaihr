-- Debug authentication status
-- This will help us understand why RLS policies are failing

-- Check current authenticated user
SELECT 
    'Current auth.uid()' as check_type,
    auth.uid() as value;

-- Check current auth role
SELECT 
    'Current auth.role()' as check_type,
    auth.role() as value;

-- Check if user exists in auth.users
SELECT 
    'User in auth.users' as check_type,
    id,
    email,
    raw_user_meta_data->>'role' as role,
    created_at
FROM auth.users 
WHERE id = auth.uid();

-- Check if user exists in public.users table
SELECT 
    'User in public.users' as check_type,
    id,
    email,
    name,
    role,
    created_at
FROM users 
WHERE id::uuid = auth.uid();

-- Test a simple query to see what happens
SELECT 
    'Test query result' as check_type,
    COUNT(*) as user_count
FROM users;

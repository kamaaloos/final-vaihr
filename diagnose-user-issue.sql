-- Diagnose the user permission issue
-- Check if the user exists in both auth.users and users tables

-- Check user in auth.users
SELECT 
    id, 
    email, 
    raw_user_meta_data->>'role' as role,
    created_at
FROM auth.users 
WHERE id = '617e7a07-9a4d-4b92-9465-f8f6f52e910b';

-- Check user in users table
SELECT 
    id, 
    email, 
    name,
    role,
    created_at
FROM users 
WHERE id = '617e7a07-9a4d-4b92-9465-f8f6f52e910b';

-- Check user_status table
SELECT 
    user_id, 
    is_online, 
    last_seen,
    created_at
FROM user_status 
WHERE user_id = '617e7a07-9a4d-4b92-9465-f8f6f52e910b';

-- Check current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

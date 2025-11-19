-- Check current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_status')
ORDER BY tablename, policyname;

-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

-- Check user role in auth.users
SELECT id, email, raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE id = '617e7a07-9a4d-4b92-9465-f8f6f52e910b';

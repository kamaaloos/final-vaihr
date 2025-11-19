-- Workaround for the users_phone_key constraint issue
-- Since we can't modify auth.users directly, let's try a different approach

-- Check if we can create a function to handle user creation
-- This is a workaround since we can't modify the auth.users table directly

-- First, let's see what we're working with
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'auth'
AND column_name = 'phone'
ORDER BY ordinal_position;

-- Check the current constraint
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' 
AND tc.table_schema = 'auth'
AND tc.constraint_name = 'users_phone_key';

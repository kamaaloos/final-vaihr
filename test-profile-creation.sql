-- Test profile creation with current user
-- Run this in your Supabase SQL Editor

-- ==============================================
-- TEST CURRENT USER CONTEXT
-- ==============================================

-- Check if we have an authenticated user
SELECT 
    'Current Auth Context' as test_type,
    auth.uid() as current_user_id,
    auth.role() as current_role;

-- ==============================================
-- TEST PROFILE CREATION
-- ==============================================

-- Try to insert a test profile (this will fail if RLS blocks it)
-- Note: This will only work if you're authenticated
INSERT INTO users (
    id,
    email,
    name,
    role,
    email_verified,
    created_at,
    updated_at
) VALUES (
    auth.uid(),
    'test@example.com',
    'Test User',
    'driver',
    false,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- CHECK IF PROFILE WAS CREATED
-- ==============================================

SELECT 
    'Profile Creation Test' as test_type,
    id,
    email,
    name,
    role,
    created_at
FROM users 
WHERE id = auth.uid();














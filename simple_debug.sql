-- Simple Debug Script for Notification System
-- This script checks the basics without complex PL/pgSQL

-- 1. Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    'Trigger exists' as status
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- 2. Check if functions exist
SELECT 
    routine_name,
    routine_type,
    'Function exists' as status
FROM information_schema.routines 
WHERE routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 3. Check notifications table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- 4. Check users table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_online', 'expo_push_token', 'role', 'name', 'avatar_url')
ORDER BY column_name;

-- 5. Check if admin users exist and have push tokens
SELECT 
    id,
    name,
    email,
    expo_push_token,
    is_online,
    role
FROM users
WHERE role = 'admin'
LIMIT 5;

-- 6. Check recent jobs
SELECT 
    id,
    title,
    status,
    admin_id,
    driver_id,
    created_at,
    updated_at
FROM jobs
ORDER BY updated_at DESC
LIMIT 5;

-- 7. Check current notification count
SELECT 
    'total_notifications' as check_type,
    COUNT(*) as count,
    'Total notifications in table' as description
FROM notifications
UNION ALL
SELECT 
    'job_status_notifications' as check_type,
    COUNT(*) as count,
    'Job status notifications' as description
FROM notifications
WHERE type = 'job_status';

-- 8. Check if there are any completed jobs
SELECT 
    'completed_jobs' as check_type,
    COUNT(*) as count,
    'Jobs with completed status' as description
FROM jobs
WHERE status = 'completed'
UNION ALL
SELECT 
    'recent_updates' as check_type,
    COUNT(*) as count,
    'Jobs updated in last hour' as description
FROM jobs
WHERE updated_at > NOW() - INTERVAL '1 hour';

-- 9. Show recent notifications
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 5; 
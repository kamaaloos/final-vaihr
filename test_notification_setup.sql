-- Test script to verify notification setup
-- Run this in your Supabase SQL editor to check if everything is set up correctly

-- 1. Check if the notifications table exists
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- 2. Check if the triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- 3. Check if the functions exist
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 4. Check if users table has the correct columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_online', 'expo_push_token', 'role', 'name', 'avatar_url')
ORDER BY column_name;

-- 5. Check if there are any users with expo_push_token
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN expo_push_token IS NOT NULL THEN 1 END) as users_with_tokens,
    COUNT(CASE WHEN role = 'driver' THEN 1 END) as drivers,
    COUNT(CASE WHEN role = 'driver' AND expo_push_token IS NOT NULL THEN 1 END) as drivers_with_tokens,
    COUNT(CASE WHEN role = 'driver' AND expo_push_token IS NOT NULL AND is_online = true THEN 1 END) as online_drivers_with_tokens
FROM users;

-- 6. Check if there are any existing notifications
SELECT 
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN type = 'job_creation' THEN 1 END) as job_creation_notifications,
    COUNT(CASE WHEN type = 'job_status' THEN 1 END) as job_status_notifications,
    COUNT(CASE WHEN type = 'invoice_creation' THEN 1 END) as invoice_creation_notifications,
    COUNT(CASE WHEN type = 'invoice_payment' THEN 1 END) as invoice_payment_notifications
FROM notifications;

-- 7. Test the should_notify_driver function
SELECT 
    should_notify_driver(NULL, 'Dublin', '25') as should_notify_no_preferences,
    should_notify_driver('{"excludedLocations": ["Cork"]}'::jsonb, 'Dublin', '25') as should_notify_different_location,
    should_notify_driver('{"excludedLocations": ["Dublin"]}'::jsonb, 'Dublin', '25') as should_notify_excluded_location,
    should_notify_driver('{"minRate": "30"}'::jsonb, 'Dublin', '25') as should_notify_low_rate,
    should_notify_driver('{"minRate": "20"}'::jsonb, 'Dublin', '25') as should_notify_high_rate; 
-- Test script to verify presence system fix
-- This script helps identify if the presence system is working correctly

-- Check current online status for both users
SELECT 
    'Current Online Status' as test_type,
    u.id,
    u.email,
    u.role,
    u.online as users_online,
    us.is_online as user_status_online,
    us.last_seen as user_status_last_seen
FROM users u
LEFT JOIN user_status us ON u.id = us.user_id
WHERE u.id IN (
    'bc9b2d58-65a2-4492-9f5b-cdc242e479fa', -- admin
    '617e7a07-9a4d-4b92-9465-f8f6f52e910b'  -- driver
)
ORDER BY u.role;

-- Check recent presence notifications
SELECT 
    'Recent Presence Notifications' as test_type,
    pn.*,
    c.driver_id,
    c.admin_id
FROM presence_notifications pn
JOIN chats c ON pn.chat_id = c.id
WHERE pn.created_at > NOW() - INTERVAL '1 hour'
ORDER BY pn.created_at DESC
LIMIT 10;

-- Check for any stale presence data
SELECT 
    'Stale Presence Data' as test_type,
    us.user_id,
    us.is_online,
    us.last_seen,
    EXTRACT(EPOCH FROM (NOW() - us.last_seen::timestamp)) / 60 as minutes_ago
FROM user_status us
WHERE us.last_seen < NOW() - INTERVAL '5 minutes'
    AND us.is_online = true;

-- Manual cleanup of stale presence data (if needed)
-- UPDATE user_status 
-- SET is_online = false 
-- WHERE last_seen < NOW() - INTERVAL '5 minutes' 
--     AND is_online = true;

-- Check chat connections
SELECT 
    'Active Chat Connections' as test_type,
    c.id as chat_id,
    c.driver_id,
    c.admin_id,
    u1.email as driver_email,
    u2.email as admin_email,
    c.created_at,
    c.updated_at
FROM chats c
JOIN users u1 ON c.driver_id = u1.id
JOIN users u2 ON c.admin_id = u2.id
WHERE c.updated_at > NOW() - INTERVAL '1 hour'
ORDER BY c.updated_at DESC; 
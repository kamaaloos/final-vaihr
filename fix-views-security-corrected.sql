-- Fix security for views by recreating them with proper security (Corrected names)
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP AND RECREATE VIEWS WITH PROPER SECURITY
-- ==============================================

-- Drop existing views
DROP VIEW IF EXISTS chat_list;
DROP VIEW IF EXISTS chat_relationships;

-- Recreate chat_list view with security
CREATE VIEW chat_list 
WITH (security_invoker = true) AS
SELECT 
    c.id,
    c.driver_id,
    c.admin_id,
    c.last_message,
    c.last_message_at,
    c.created_at,
    c.updated_at,
    u1.name as driver_name,
    u1.email as driver_email,
    u2.name as admin_name,
    u2.email as admin_email
FROM chats c
LEFT JOIN users u1 ON c.driver_id = u1.id
LEFT JOIN users u2 ON c.admin_id = u2.id
WHERE c.driver_id = auth.uid() OR c.admin_id = auth.uid();

-- Recreate chat_relationships view with security (corrected name)
CREATE VIEW chat_relationships 
WITH (security_invoker = true) AS
SELECT 
    c.id as chat_id,
    c.driver_id,
    c.admin_id,
    c.created_at,
    c.updated_at,
    u1.name as driver_name,
    u2.name as admin_name,
    CASE 
        WHEN c.driver_id = auth.uid() THEN 'driver'
        WHEN c.admin_id = auth.uid() THEN 'admin'
        ELSE 'unknown'
    END as user_role
FROM chats c
LEFT JOIN users u1 ON c.driver_id = u1.id
LEFT JOIN users u2 ON c.admin_id = u2.id
WHERE c.driver_id = auth.uid() OR c.admin_id = auth.uid();

-- ==============================================
-- ENABLE RLS ON VIEWS
-- ==============================================

-- Enable RLS on the views
ALTER VIEW chat_list ENABLE ROW LEVEL SECURITY;
ALTER VIEW chat_relationships ENABLE ROW LEVEL SECURITY;














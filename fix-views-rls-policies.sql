-- Fix RLS policies for views
-- Run this in your Supabase SQL Editor

-- ==============================================
-- ENABLE RLS ON VIEWS
-- ==============================================

-- Enable RLS on chat_list view
ALTER VIEW chat_list SET (security_invoker = true);

-- Enable RLS on chat_relationship view  
ALTER VIEW chat_relationship SET (security_invoker = true);

-- ==============================================
-- CREATE RLS POLICIES FOR VIEWS
-- ==============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own chat list" ON chat_list;
DROP POLICY IF EXISTS "Users can view their own chat relationships" ON chat_relationship;

-- Create chat_list policy
CREATE POLICY "Users can view their own chat list"
    ON chat_list FOR SELECT
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id);

-- Create chat_relationship policy
CREATE POLICY "Users can view their own chat relationships"
    ON chat_relationship FOR SELECT
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id);














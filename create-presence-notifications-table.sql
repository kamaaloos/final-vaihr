-- Create presence_notifications table
-- Run this in your Supabase SQL Editor

-- ==============================================
-- CREATE PRESENCE_NOTIFICATIONS TABLE
-- ==============================================

-- Drop existing table if it exists
DROP TABLE IF EXISTS presence_notifications CASCADE;

-- Create presence_notifications table
CREATE TABLE presence_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    notification_type TEXT DEFAULT 'presence_join',
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- ENABLE RLS
-- ==============================================

ALTER TABLE presence_notifications ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- CREATE RLS POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own presence notifications" ON presence_notifications;
DROP POLICY IF EXISTS "Users can create presence notifications" ON presence_notifications;
DROP POLICY IF EXISTS "Users can delete their own presence notifications" ON presence_notifications;

-- Create policies
CREATE POLICY "Users can view their own presence notifications"
    ON presence_notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create presence notifications"
    ON presence_notifications FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own presence notifications"
    ON presence_notifications FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ==============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ==============================================

CREATE INDEX idx_presence_notifications_user_id ON presence_notifications(user_id);
CREATE INDEX idx_presence_notifications_chat_id ON presence_notifications(chat_id);
CREATE INDEX idx_presence_notifications_created_at ON presence_notifications(created_at);














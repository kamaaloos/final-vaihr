-- Fix database schema issues for chat functionality
-- Run this in your Supabase SQL Editor

-- ==============================================
-- 1. FIX USERS TABLE - Add missing 'online' column
-- ==============================================

-- Check current users table structure
SELECT 
    'Current users table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add online column to users table if it doesn't exist
DO $$
BEGIN
    -- Check if online column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'online'
        AND table_schema = 'public'
    ) THEN
        -- Add online column
        ALTER TABLE public.users ADD COLUMN online BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Added online column to users table';
    ELSE
        RAISE NOTICE 'ℹ️ online column already exists in users table';
    END IF;
END $$;

-- ==============================================
-- 2. FIX MESSAGES TABLE - Add missing 'text' column
-- ==============================================

-- Check current messages table structure
SELECT 
    'Current messages table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add text column to messages table if it doesn't exist
DO $$
BEGIN
    -- Check if text column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'text'
        AND table_schema = 'public'
    ) THEN
        -- Add text column
        ALTER TABLE public.messages ADD COLUMN text TEXT;
        RAISE NOTICE '✅ Added text column to messages table';
        
        -- If content column exists, copy data from content to text
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'messages' 
            AND column_name = 'content'
            AND table_schema = 'public'
        ) THEN
            UPDATE public.messages SET text = content WHERE text IS NULL;
            RAISE NOTICE '✅ Copied content to text column for existing messages';
        END IF;
    ELSE
        RAISE NOTICE 'ℹ️ text column already exists in messages table';
    END IF;
END $$;

-- ==============================================
-- 3. CREATE TRIGGER TO SYNC USER_STATUS.IS_ONLINE WITH USERS.ONLINE
-- ==============================================

-- Create or replace function to sync online status
CREATE OR REPLACE FUNCTION sync_user_online_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update users.online when user_status.is_online changes
    UPDATE public.users 
    SET online = NEW.is_online 
    WHERE id = NEW.user_id;
    
    RAISE NOTICE 'Synced online status: user_id=%, is_online=%, users.online updated to %', 
        NEW.user_id, NEW.is_online, NEW.is_online;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS sync_user_online_status_trigger ON public.user_status;

-- Create trigger
CREATE TRIGGER sync_user_online_status_trigger
    AFTER INSERT OR UPDATE OF is_online ON public.user_status
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_online_status();

-- ==============================================
-- 4. INITIAL SYNC - Update users.online to match user_status.is_online
-- ==============================================

-- Sync existing data
UPDATE public.users 
SET online = COALESCE(
    (SELECT is_online FROM public.user_status WHERE user_id = users.id),
    false
);

-- ==============================================
-- 5. VERIFICATION
-- ==============================================

-- Show updated users table structure
SELECT 
    'Updated users table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show updated messages table structure
SELECT 
    'Updated messages table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test the sync by checking a few users
SELECT 
    'Online status sync verification:' as info,
    u.id,
    u.email,
    u.online as users_online,
    us.is_online as user_status_online,
    us.last_seen
FROM public.users u
LEFT JOIN public.user_status us ON u.id = us.user_id
LIMIT 5;

-- Check messages table
SELECT 
    'Messages table verification:' as info,
    COUNT(*) as total_messages,
    COUNT(text) as messages_with_text,
    COUNT(content) as messages_with_content
FROM public.messages;

RAISE NOTICE '🎉 Database schema fixes completed successfully!';


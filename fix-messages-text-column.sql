-- Fix messages table - Add missing 'text' column
-- Run this in your Supabase SQL Editor

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

-- Check messages table data
SELECT 
    'Messages table verification:' as info,
    COUNT(*) as total_messages,
    COUNT(text) as messages_with_text,
    COUNT(content) as messages_with_content
FROM public.messages;

RAISE NOTICE '🎉 Messages table fix completed successfully!';

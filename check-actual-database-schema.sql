-- Check actual current database schema
-- Run this in your Supabase SQL Editor to see what columns actually exist

-- Check messages table structure
SELECT 
    'Messages table actual structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check users table structure  
SELECT 
    'Users table actual structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there are any messages in the table
SELECT 
    'Messages count:' as info,
    COUNT(*) as total_messages
FROM public.messages;

-- Try to select from messages to see what columns are available
SELECT 
    'Sample message data:' as info,
    *
FROM public.messages 
LIMIT 1;

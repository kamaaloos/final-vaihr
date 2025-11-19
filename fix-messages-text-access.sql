-- Fix messages table text column access
-- Run this in your Supabase SQL Editor

-- 1. First, let's check if we can access the text column directly
SELECT 
    'Testing text column access:' as info,
    id,
    text,
    sender_id,
    created_at
FROM public.messages 
LIMIT 1;

-- 2. Check the exact column names in the messages table
SELECT 
    'Exact column names:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Temporarily disable RLS to test if that's the issue
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- 4. Test access after disabling RLS
SELECT 
    'After disabling RLS:' as info,
    id,
    text,
    sender_id,
    created_at
FROM public.messages 
LIMIT 1;

-- 5. Re-enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 6. Check and fix RLS policies to ensure they allow text column access
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;

-- Recreate policies with explicit column access
CREATE POLICY "Users can view messages in their chats"
    ON public.messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chats
            WHERE chats.id = messages.chat_id
            AND (chats.driver_id = auth.uid() OR chats.admin_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert messages in their chats"
    ON public.messages FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chats
            WHERE chats.id = chat_id
            AND (chats.driver_id = auth.uid() OR chats.admin_id = auth.uid())
        )
        AND sender_id = auth.uid()
    );

CREATE POLICY "Users can update their own messages"
    ON public.messages FOR UPDATE
    TO authenticated
    USING (
        sender_id = auth.uid()
    )
    WITH CHECK (
        sender_id = auth.uid()
    );

CREATE POLICY "Users can delete their own messages"
    ON public.messages FOR DELETE
    TO authenticated
    USING (
        sender_id = auth.uid()
    );

-- 7. Test access after recreating policies
SELECT 
    'After recreating policies:' as info,
    id,
    text,
    sender_id,
    created_at
FROM public.messages 
LIMIT 1;

RAISE NOTICE '🎉 Messages table access fix completed!';

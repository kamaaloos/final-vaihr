-- Fix RLS policies for users table
-- Run this in your Supabase SQL Editor

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;

-- Create more permissive policies
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- More permissive insert policy
CREATE POLICY "Allow authenticated users to insert own profile"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Alternative: Allow any authenticated user to insert (for initial setup)
CREATE POLICY "Allow any authenticated user to insert"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);














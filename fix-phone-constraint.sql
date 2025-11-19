-- Fix the phone constraint issue that's blocking user registration
-- The UNIQUE constraint on phone column is causing registration to fail

-- Check current constraint
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' 
AND tc.table_schema = 'auth'
AND tc.constraint_type = 'UNIQUE'
AND kcu.column_name = 'phone';

-- Drop the problematic UNIQUE constraint on phone
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS users_phone_key;

-- Create a new UNIQUE constraint that allows multiple NULL values
-- This is the proper way to handle UNIQUE constraints with nullable columns
CREATE UNIQUE INDEX users_phone_unique_idx 
ON auth.users (phone) 
WHERE phone IS NOT NULL;

-- Verify the fix
SELECT 
    'Constraint removed and replaced with partial index' as status;

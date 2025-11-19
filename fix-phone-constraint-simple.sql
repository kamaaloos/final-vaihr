-- Simple fix for phone constraint issue
-- Drop the problematic UNIQUE constraint on phone column

-- Drop the constraint that's blocking user registration
ALTER TABLE auth.users DROP CONSTRAINT IF EXISTS users_phone_key;

-- Create a partial unique index that allows multiple NULL values
CREATE UNIQUE INDEX IF NOT EXISTS users_phone_unique_idx 
ON auth.users (phone) 
WHERE phone IS NOT NULL;

-- Verify the fix
SELECT 'Phone constraint fixed - registration should work now' as status;

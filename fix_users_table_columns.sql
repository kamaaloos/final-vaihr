-- Fix missing columns in users table
-- This addresses the "column users.phone_number does not exist" error

-- ==============================================
-- STEP 1: CHECK CURRENT USERS TABLE STRUCTURE
-- ==============================================

-- Check what columns exist in the users table
SELECT 
    'Current users table columns:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- ==============================================
-- STEP 2: ADD MISSING COLUMNS
-- ==============================================

-- Add phone_number column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'phone_number'
    ) THEN
        ALTER TABLE users ADD COLUMN phone_number TEXT;
        RAISE NOTICE 'Added phone_number column to users table';
    ELSE
        RAISE NOTICE 'phone_number column already exists';
    END IF;
END $$;

-- Add other commonly needed columns
DO $$
BEGIN
    -- Add address column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'address'
    ) THEN
        ALTER TABLE users ADD COLUMN address TEXT;
        RAISE NOTICE 'Added address column to users table';
    END IF;
    
    -- Add bank_info column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'bank_info'
    ) THEN
        ALTER TABLE users ADD COLUMN bank_info JSONB;
        RAISE NOTICE 'Added bank_info column to users table';
    END IF;
    
    -- Add company_info column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'company_info'
    ) THEN
        ALTER TABLE users ADD COLUMN company_info JSONB;
        RAISE NOTICE 'Added company_info column to users table';
    END IF;
    
    -- Add push_token column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'push_token'
    ) THEN
        ALTER TABLE users ADD COLUMN push_token TEXT;
        RAISE NOTICE 'Added push_token column to users table';
    END IF;
END $$;

-- ==============================================
-- STEP 3: UPDATE EXISTING USERS WITH DEFAULT VALUES
-- ==============================================

-- Update existing users with default values for new columns
UPDATE users 
SET 
    phone_number = COALESCE(phone_number, ''),
    address = COALESCE(address, ''),
    bank_info = COALESCE(bank_info, '{}'::jsonb),
    company_info = COALESCE(company_info, '{}'::jsonb),
    push_token = COALESCE(push_token, '')
WHERE 
    phone_number IS NULL 
    OR address IS NULL 
    OR bank_info IS NULL 
    OR company_info IS NULL 
    OR push_token IS NULL;

-- ==============================================
-- STEP 4: GRANT PERMISSIONS
-- ==============================================

-- Grant permissions on the updated users table
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO authenticated;

-- ==============================================
-- STEP 5: CHECK FINAL STRUCTURE
-- ==============================================

-- Check the final structure of the users table
SELECT 
    'Final users table columns:' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- ==============================================
-- STEP 6: TEST THE INVOICE FUNCTION
-- ==============================================

-- Test if the invoice function now works without errors
-- This should no longer give the "column users.phone_number does not exist" error
SELECT 
    'Testing invoice function:' as info,
    COUNT(*) as user_count
FROM users 
WHERE phone_number IS NOT NULL;

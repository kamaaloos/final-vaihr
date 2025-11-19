-- Check for existing users with phone numbers
-- This will help us understand if there are phone number conflicts

-- Check auth.users table for existing phone numbers
SELECT 
    id,
    email,
    phone,
    created_at
FROM auth.users 
WHERE phone IS NOT NULL 
ORDER BY created_at DESC;

-- Check if there are any duplicate phone numbers
SELECT 
    phone,
    COUNT(*) as count
FROM auth.users 
WHERE phone IS NOT NULL 
GROUP BY phone 
HAVING COUNT(*) > 1;

-- Check the specific phone number we're trying to use
SELECT 
    id,
    email,
    phone,
    created_at
FROM auth.users 
WHERE phone = '+358400797848';


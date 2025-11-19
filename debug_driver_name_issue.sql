-- Debug why driver_name is still null
-- This will check the driver information in the users table

-- ==============================================
-- STEP 1: CHECK DRIVER INFORMATION
-- ==============================================

-- Check if the driver exists in the users table
SELECT 
    'Driver information:' as info,
    id,
    email,
    name,
    role,
    created_at
FROM users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 2: CHECK AUTH USER
-- ==============================================

-- Check if the driver exists in auth.users
SELECT 
    'Auth user information:' as info,
    id,
    email,
    raw_user_meta_data->>'name' as name,
    created_at
FROM auth.users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 3: CHECK JOB WITH DRIVER JOIN
-- ==============================================

-- Test the job query with driver join
SELECT 
    'Job with driver join:' as info,
    j.id,
    j.title,
    j.status,
    j.driver_id,
    u.name as driver_name,
    u.email as driver_email
FROM jobs j
LEFT JOIN users u ON j.driver_id = u.id
WHERE j.driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 4: UPDATE DRIVER NAME IF MISSING
-- ==============================================

-- Update the driver name if it's missing
UPDATE users 
SET name = COALESCE(name, email, 'Driver')
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid
AND (name IS NULL OR name = '');

-- ==============================================
-- STEP 5: CHECK FINAL RESULT
-- ==============================================

-- Check the updated driver information
SELECT 
    'Updated driver information:' as info,
    id,
    email,
    name,
    role
FROM users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- Test the job query again
SELECT 
    'Final job with driver:' as info,
    j.id,
    j.title,
    j.status,
    j.driver_id,
    u.name as driver_name,
    u.email as driver_email
FROM jobs j
LEFT JOIN users u ON j.driver_id = u.id
WHERE j.driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

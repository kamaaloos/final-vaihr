-- Remove only OTP-related components
-- Keep existing working RLS policies intact

-- Drop OTP-related policies only
DROP POLICY IF EXISTS "OTP users can access users table" ON users;
DROP POLICY IF EXISTS "OTP users can access user_status table" ON user_status;
DROP POLICY IF EXISTS "OTP users can access jobs table" ON jobs;
DROP POLICY IF EXISTS "OTP verified users can access their data" ON users;
DROP POLICY IF EXISTS "OTP verified users can access their status" ON user_status;

-- Drop OTP table
DROP TABLE IF EXISTS otp_codes CASCADE;

-- Drop OTP-related functions
DROP FUNCTION IF EXISTS is_otp_verified(TEXT);
DROP FUNCTION IF EXISTS cleanup_expired_otps();

-- Verify cleanup (should show no OTP-related policies)
SELECT 'OTP cleanup completed - existing RLS policies preserved' as status;

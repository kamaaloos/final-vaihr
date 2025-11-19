# OTP Email Implementation Guide

This guide explains how to implement and use the OTP (One-Time Password) email system in your React Native Expo app.

## 🚀 Features

- **6-digit OTP generation** with 10-minute expiry
- **Rate limiting** (max 3 attempts per OTP)
- **Email templates** with professional design
- **Multiple login methods** (Password + OTP)
- **Secure verification** with attempt tracking
- **Automatic cleanup** of expired OTPs

## 📁 Files Created/Modified

### New Files:
- `src/services/otpService.ts` - Core OTP service
- `src/screens/OTPVerificationScreen.tsx` - OTP verification UI
- `src/migrations/091_create_otp_codes_table.sql` - Database migration
- `src/templates/otpEmailTemplate.html` - Email template
- `functions/src/send-otp-email.ts` - Supabase Edge Function
- `scripts/run-otp-migration.ts` - Migration runner

### Modified Files:
- `src/components/auth/AuthProvider.tsx` - Added OTP methods
- `src/components/auth/AuthContext.tsx` - Updated context interface
- `src/screens/LoginScreen.tsx` - Added OTP login option
- `src/types/index.ts` - Added OTP screen types

## 🛠 Setup Instructions

### 1. Database Migration

Run the migration to create the OTP codes table:

```bash
# Using the migration script
npx ts-node scripts/run-otp-migration.ts

# Or manually in Supabase SQL editor
# Copy and paste the contents of src/migrations/091_create_otp_codes_table.sql
```

### 2. Environment Variables

Add these to your `.env` file:

```env
# Email Service (choose one)
RESEND_API_KEY=your_resend_api_key
# OR
SENDGRID_API_KEY=your_sendgrid_api_key

# Supabase (already configured)
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
EXPO_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_key
```

### 3. Deploy Edge Function

Deploy the OTP email function to Supabase:

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Deploy the function
supabase functions deploy send-otp-email
```

### 4. Email Service Setup

Choose one of these email services:

#### Option A: Mailgun (Recommended)
1. Sign up at [mailgun.com](https://mailgun.com)
2. Get your API key and domain
3. Add `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` to your environment variables
4. Verify your domain (or use sandbox domain for testing)

#### Option B: Resend
1. Sign up at [resend.com](https://resend.com)
2. Get your API key
3. Add `RESEND_API_KEY` to your environment variables
4. Verify your domain

#### Option C: Development Mode
For development, the system will log OTP codes to the console instead of sending emails.

## 📱 Usage

### 1. OTP Login Flow

```typescript
// In your login screen
const { sendOTP, signInWithOTP } = useAuth();

// Send OTP
const handleSendOTP = async () => {
  const result = await sendOTP(email);
  if (result.success) {
    // Navigate to OTP verification screen
    navigation.navigate('OTPVerification', {
      email: email,
      purpose: 'login'
    });
  }
};

// Verify OTP and login
const handleVerifyOTP = async (otpCode: string) => {
  const result = await signInWithOTP(email, otpCode);
  if (result.success) {
    // User is logged in
  }
};
```

### 2. OTP Verification Screen

The `OTPVerificationScreen` handles:
- OTP input with 6-digit validation
- Resend functionality with countdown timer
- Attempt tracking and error messages
- Automatic navigation after successful verification

### 3. Service Methods

```typescript
import { otpService } from '../services/otpService';

// Send OTP
const result = await otpService.sendOTP('user@example.com');

// Verify OTP
const verification = await otpService.verifyOTP('user@example.com', '123456');

// Check OTP status
const status = await otpService.getOTPStatus('user@example.com');
```

## 🔒 Security Features

### Rate Limiting
- Maximum 3 attempts per OTP
- 10-minute expiry time
- Cooldown period between OTP requests

### Data Protection
- OTPs are hashed in the database
- Automatic cleanup of expired codes
- Row Level Security (RLS) enabled

### Email Security
- Professional email templates
- Security warnings in emails
- No sensitive data in email content

## 🎨 Customization

### Email Template
Edit `src/templates/otpEmailTemplate.html` to customize:
- Brand colors and logo
- Email content and styling
- Security messages

### OTP Settings
Modify `src/services/otpService.ts`:
```typescript
private readonly OTP_LENGTH = 6;           // Change OTP length
private readonly OTP_EXPIRY_MINUTES = 10;  // Change expiry time
private readonly MAX_ATTEMPTS = 3;         // Change max attempts
```

### UI Customization
Update `src/screens/OTPVerificationScreen.tsx`:
- Colors and styling
- Text content
- Button layouts
- Error messages

## 🧪 Testing

### Development Testing
1. Use the development mode (no email service required)
2. Check console logs for OTP codes
3. Test the complete flow

### Production Testing
1. Set up email service
2. Test with real email addresses
3. Verify email delivery and formatting

## 🐛 Troubleshooting

### Common Issues

#### OTP Not Sending
- Check email service API keys
- Verify domain authentication
- Check Supabase Edge Function logs

#### Database Errors
- Ensure migration ran successfully
- Check RLS policies
- Verify user permissions

#### UI Issues
- Check navigation types
- Verify component imports
- Test on different screen sizes

### Debug Mode
Enable debug logging in `otpService.ts`:
```typescript
console.log('🔐 OTP Service: Debug mode enabled');
```

## 📊 Monitoring

### Database Queries
Monitor OTP usage:
```sql
-- Check active OTPs
SELECT * FROM otp_codes WHERE expires_at > NOW();

-- Check failed attempts
SELECT email, attempts, created_at 
FROM otp_codes 
WHERE attempts >= 3;
```

### Edge Function Logs
Check Supabase Edge Function logs for email delivery issues.

## 🔄 Maintenance

### Cleanup Expired OTPs
The system automatically cleans up expired OTPs, but you can also run manual cleanup:

```typescript
await otpService.cleanupExpiredOTPs();
```

### Database Maintenance
Regular cleanup of old OTP records:
```sql
DELETE FROM otp_codes 
WHERE created_at < NOW() - INTERVAL '7 days';
```

## 🚀 Production Deployment

1. **Set up email service** with verified domain
2. **Deploy Edge Function** to Supabase
3. **Run database migration** in production
4. **Test complete flow** with real emails
5. **Monitor logs** for any issues
6. **Set up alerts** for failed email deliveries

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review console logs
3. Test in development mode first
4. Verify all environment variables are set

---

**Note**: This implementation provides a solid foundation for OTP-based authentication. For production use, consider additional security measures like IP rate limiting, device fingerprinting, and advanced threat detection.

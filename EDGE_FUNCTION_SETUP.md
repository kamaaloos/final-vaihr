# Edge Function Setup Guide

## 🚀 Quick Setup for OTP Email Function

### Option 1: Deploy Simple Development Function

1. **Deploy the simple function**:
   ```bash
   # Copy the simple function to the main index
   cp functions/src/send-otp-email-simple.ts functions/src/index.ts
   
   # Deploy to Supabase
   supabase functions deploy send-otp-email
   ```

2. **Test the function**:
   ```bash
   # Test locally (optional)
   supabase functions serve send-otp-email
   ```

### Option 2: Manual SQL Setup (No Edge Function)

If you don't want to use Edge Functions, the OTP service will automatically fall back to development mode and log OTP codes to the console.

### Option 3: Production Email Service Setup

1. **Choose an email service**:
   - **Mailgun** (Recommended): Get API key and domain from [mailgun.com](https://mailgun.com)
   - **Resend**: Get API key from [resend.com](https://resend.com)

2. **Add environment variables**:
   ```bash
   # Add to your .env file
   MAILGUN_API_KEY=your_mailgun_api_key
   MAILGUN_DOMAIN=your_mailgun_domain
   # OR
   RESEND_API_KEY=your_resend_api_key
   ```

3. **Deploy the full function**:
   ```bash
   supabase functions deploy send-otp-email
   ```

## 🧪 Testing

### Development Mode (Current)
- OTP codes are logged to console
- No email service required
- Perfect for testing the complete flow

### Production Mode
- Real emails sent via your chosen service
- Professional email templates
- Full email delivery tracking

## 🔧 Troubleshooting

### Edge Function Not Found
- Make sure you've deployed the function: `supabase functions deploy send-otp-email`
- Check function name matches exactly: `send-otp-email`

### CORS Issues
- The function includes proper CORS headers
- Should work with React Native apps

### Email Service Issues
- Check API keys are correct
- Verify domain authentication
- Check service quotas/limits

## 📱 Current Status

Your app is currently working in **development mode**:
- ✅ OTP generation works
- ✅ Database storage works  
- ✅ Verification works
- ✅ OTP codes logged to console
- ⚠️ Edge Function needs deployment (optional)

The OTP system is fully functional for testing! 🎉

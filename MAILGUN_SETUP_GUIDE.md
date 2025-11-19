# Mailgun Setup Guide for OTP Emails

## 🚀 Complete Mailgun Integration

### Step 1: Create Mailgun Account

1. **Sign up** at [mailgun.com](https://mailgun.com)
2. **Choose a plan** (free tier includes 5,000 emails/month)
3. **Verify your account** via email

### Step 2: Add Your Domain

1. **Go to Domains** in your Mailgun dashboard
2. **Click "Add New Domain"**
3. **Choose your domain type**:
   - **Sandbox Domain** (for testing): `sandbox-xxx.mailgun.org`
   - **Custom Domain** (for production): `yourdomain.com`

4. **For Sandbox Domain** (recommended for testing):
   - Use the provided sandbox domain
   - No DNS configuration needed
   - Emails will be sent but may go to spam

5. **For Custom Domain** (production):
   - Add DNS records to your domain
   - Follow Mailgun's DNS setup guide
   - Verify domain ownership

### Step 3: Get Your Credentials

1. **API Key**: Go to Settings → API Keys
2. **Domain**: Copy your domain name from the Domains section
3. **Example**:
   ```
   API Key: key-1234567890abcdef1234567890abcdef
   Domain: sandbox-abc123.mailgun.org
   ```

### Step 4: Configure Environment Variables

Add to your `.env` file:
```bash
# Mailgun Configuration
MAILGUN_API_KEY=key-1234567890abcdef1234567890abcdef
MAILGUN_DOMAIN=sandbox-abc123.mailgun.org

# Supabase Configuration (already configured)
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
EXPO_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_key
```

### Step 5: Deploy Edge Function

```bash
# Deploy the function with Mailgun support
supabase functions deploy send-otp-email
```

### Step 6: Test the Integration

1. **Try the OTP signup flow**
2. **Check your email** (including spam folder)
3. **Verify the email format** and content

## 📧 Email Configuration

### From Address
The Edge Function uses: `noreply@yourdomain.com`

For sandbox domains, use: `noreply@sandbox-abc123.mailgun.org`

### Email Template
The system uses a professional HTML template with:
- ✅ Branded header with logo
- ✅ Large, clear OTP code display
- ✅ Security warnings
- ✅ Responsive design
- ✅ Professional styling

## 🔧 Troubleshooting

### Common Issues

#### 1. "Forbidden" Error
- Check your API key is correct
- Verify domain is properly configured
- Ensure you're using the right domain format

#### 2. Emails Not Received
- Check spam/junk folder
- Verify recipient email address
- Test with a different email provider

#### 3. "Domain not found" Error
- Double-check domain spelling
- Ensure domain is verified in Mailgun
- Wait a few minutes after domain creation

#### 4. Rate Limiting
- Free tier: 5,000 emails/month
- Check your usage in Mailgun dashboard
- Upgrade plan if needed

### Testing Commands

```bash
# Test Edge Function locally
supabase functions serve send-otp-email

# Check function logs
supabase functions logs send-otp-email

# Test with curl
curl -X POST 'https://your-project.supabase.co/functions/v1/send-otp-email' \
  -H 'Authorization: Bearer your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","otpCode":"123456"}'
```

## 📊 Monitoring

### Mailgun Dashboard
- **Statistics**: Email delivery rates
- **Logs**: Detailed sending logs
- **Webhooks**: Delivery status updates

### Supabase Logs
- **Function Logs**: Edge Function execution
- **Database Logs**: OTP storage and verification

## 🚀 Production Checklist

- [ ] Custom domain configured
- [ ] DNS records added
- [ ] Domain verified
- [ ] API key secured
- [ ] Email templates tested
- [ ] Delivery rates monitored
- [ ] Spam score checked
- [ ] Backup email service configured

## 💡 Pro Tips

1. **Use Custom Domain**: Better deliverability than sandbox
2. **Monitor Spam Score**: Keep it low for better delivery
3. **Set up Webhooks**: Track email delivery status
4. **Test Regularly**: Verify emails are being sent
5. **Backup Service**: Consider Resend as fallback

## 🔒 Security

- **API Key**: Keep it secret, never commit to git
- **Domain Verification**: Prevents spoofing
- **Rate Limiting**: Prevents abuse
- **HTTPS**: All communications encrypted

---

Your Mailgun integration is now ready! 🎉

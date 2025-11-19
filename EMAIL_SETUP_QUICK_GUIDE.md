# 🚀 Quick Email Setup Guide

## The Problem
Your OTP emails aren't being sent because no email service is configured. The Edge Function is running in development mode.

## 🎯 Quick Solutions

### Option 1: Resend (Easiest - 5 minutes)

1. **Sign up at [resend.com](https://resend.com)**
2. **Get API Key**:
   - Go to API Keys section
   - Create new API key
   - Copy the key

3. **Add to Supabase**:
   - Go to your Supabase Dashboard
   - Settings → Edge Functions → Environment Variables
   - Add: `RESEND_API_KEY` = `your_api_key_here`

4. **Deploy Function**:
   ```bash
   supabase functions deploy send-otp-email
   ```

### Option 2: Mailgun (More Professional)

1. **Sign up at [mailgun.com](https://mailgun.com)**
2. **Get API Key**:
   - Dashboard → Settings → API Keys
   - Copy Private API Key

3. **Get Domain**:
   - Use sandbox domain for testing: `sandbox-xxx.mailgun.org`
   - Or add your own domain

4. **Add to Supabase**:
   - `MAILGUN_API_KEY` = `your_api_key`
   - `MAILGUN_DOMAIN` = `your_domain`

5. **Deploy Function**:
   ```bash
   supabase functions deploy send-otp-email
   ```

## 🧪 Test After Setup

1. Try sending OTP again
2. Check your email inbox
3. Check Supabase Edge Function logs for errors

## 🔍 Current Status
- ✅ OTP generation works
- ✅ Edge Function deployed
- ❌ Email service not configured
- ❌ No actual emails sent

## 📱 For Now (Development)
The OTP code is logged to console. Check your terminal/logs for the 6-digit code to test the verification flow.

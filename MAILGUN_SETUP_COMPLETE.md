# 🚀 Complete Mailgun Setup Guide

## 🎯 **Current Status**
- ✅ Edge Function code is ready for Mailgun
- ✅ Mailgun integration is implemented
- ❌ Environment variables not configured
- ❌ Edge Function not deployed with Mailgun

## 📋 **Step-by-Step Setup**

### **Step 1: Get Mailgun Credentials**

1. **Go to [mailgun.com](https://mailgun.com)**
2. **Sign up for free account** (10,000 emails/month free)
3. **Verify your account**

### **Step 2: Get API Key and Domain**

1. **Go to Mailgun Dashboard**
2. **Navigate to Settings → API Keys**
3. **Copy your Private API Key** (starts with `key-`)

4. **Go to Domains section**
5. **Use Sandbox Domain for testing** (e.g., `sandbox-xxx.mailgun.org`)
   - OR add your own domain and verify it

### **Step 3: Configure Supabase Environment Variables**

1. **Go to your Supabase Dashboard**
2. **Navigate to Settings → Edge Functions → Environment Variables**
3. **Add these variables:**

```
MAILGUN_API_KEY = your_mailgun_private_api_key_here
MAILGUN_DOMAIN = your_mailgun_domain_here
```

**Example:**
```
MAILGUN_API_KEY = key-1234567890abcdef1234567890abcdef
MAILGUN_DOMAIN = sandbox-1234567890abcdef.mailgun.org
```

### **Step 4: Deploy Edge Function**

1. **Go to Supabase Dashboard → Edge Functions**
2. **Create/Update the `send-otp-email` function**
3. **Copy the code from `functions/send-otp-email/index.ts`**
4. **Deploy the function**

### **Step 5: Test Email Sending**

1. **Try sending an OTP in your app**
2. **Check your email inbox**
3. **Check Supabase Edge Function logs for any errors**

## 🔧 **Troubleshooting**

### **If emails still don't send:**

1. **Check Edge Function logs** in Supabase Dashboard
2. **Verify environment variables** are set correctly
3. **Test with sandbox domain** first
4. **Check Mailgun dashboard** for delivery status

### **Common Issues:**

- **Wrong API key**: Make sure you're using the Private API key
- **Wrong domain**: Use the exact domain from Mailgun dashboard
- **Sandbox restrictions**: Sandbox domains can only send to authorized recipients

## 📧 **Sandbox Domain Setup**

If using sandbox domain:
1. **Go to Mailgun Dashboard → Domains**
2. **Click on your sandbox domain**
3. **Add authorized recipients** (your email address)
4. **Only authorized emails can receive emails from sandbox**

## 🎉 **Expected Result**

After setup, you should see:
- ✅ OTP emails delivered to your inbox
- ✅ No more console log fallbacks
- ✅ Professional email templates

## 📱 **Test Flow**

1. **Send OTP** → Should receive email
2. **Enter OTP code** → Should verify successfully
3. **Complete login/signup** → Should work perfectly

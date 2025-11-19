# Notification Flow Documentation

## Overview
This document explains how notifications are created, stored, and displayed in the app.

## 1. Where Notifications Are Stored

**Database Table: `notifications`**
- **Location**: Supabase PostgreSQL database
- **Schema**: `public.notifications`
- **Structure**:
  ```sql
  CREATE TABLE notifications (
      id UUID PRIMARY KEY,
      user_id UUID REFERENCES auth.users(id),
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      type TEXT NOT NULL,  -- 'job_creation', 'job_status', 'system', etc.
      read BOOLEAN DEFAULT false,
      data JSONB,  -- Optional: stores additional data like jobId, jobTitle, etc.
      created_at TIMESTAMP WITH TIME ZONE,
      updated_at TIMESTAMP WITH TIME ZONE
  );
  ```

## 2. How Notifications Are Created When Admin Creates a Job

### Database Trigger Flow

1. **Admin creates a new job** → Insert into `jobs` table
2. **Database trigger fires** → `job_creation_notification_trigger`
3. **Trigger function executes** → `notify_drivers_on_job_creation()`

### Trigger Function Logic (`notify_drivers_on_job_creation()`)

Located in: `src/migrations/108_fix_job_creation_notifications_for_online_drivers.sql`

**Steps:**
1. Gets admin details from `auth.users` table
2. Queries for **all online drivers**:
   ```sql
   SELECT u.id, u.expo_push_token, u.name, u.preferences, us.is_online
   FROM users u
   JOIN auth.users au ON u.id = au.id
   LEFT JOIN user_status us ON u.id = us.user_id
   WHERE u.role = 'driver'
   AND us.is_online = true  -- Only online drivers
   ```
3. For each online driver:
   - Checks driver preferences (location, rate filters)
   - Creates a notification record in `notifications` table:
     ```sql
     INSERT INTO notifications (
         user_id,
         title,
         message,
         type,
         data,  -- Optional: contains jobId, jobTitle, etc.
         created_at
     ) VALUES (
         driver_id,
         'New Job Available',
         'Admin posted a new job: [job title]',
         'job_creation',
         jsonb_build_object('jobId', ..., 'jobTitle', ...),
         NOW()
     );
     ```

**Key Points:**
- ✅ Only **online drivers** receive notifications (`us.is_online = true`)
- ✅ Notifications are stored in the `notifications` table
- ✅ Each driver gets their own notification record (one per driver)
- ✅ Trigger runs automatically when a job is created

## 3. How DriverHomeScreen Fetches Notification Count

### Initial Load
**Location**: `src/screens/DriverHomeScreen.tsx` (lines 312-348)

```typescript
// Fetch initial unread notification count
const fetchUnreadCount = async () => {
  const { count } = await supabase
    .from('notifications')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .eq('read', false);  // Only count unread notifications
  
  setUnreadNotifications(count || 0);
};
```

### Real-Time Updates
**Location**: `src/screens/DriverHomeScreen.tsx` (lines 243-267)

```typescript
// Subscribe to real-time notification changes
const notificationsChannel = supabase
  .channel('notifications_' + user.id)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${user.id}`,
  }, (payload) => {
    // Increment count when new notification is created
    setUnreadNotifications(prev => prev + 1);
  })
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${user.id}`,
  }, (payload) => {
    // Decrement count when notification is marked as read
    if (payload.new.read === true && payload.old.read === false) {
      setUnreadNotifications(prev => Math.max(0, prev - 1));
    }
  })
  .subscribe();
```

## 4. How NotificationsScreen Displays Notifications

**Location**: `src/screens/NotificationsScreen.tsx`

### Fetching Notifications
```typescript
const fetchNotifications = async () => {
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false });
  
  setNotifications(data || []);
};
```

### Real-Time Subscription
```typescript
const subscription = supabase
  .channel(`notifications-${user.id}`)
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${user.id}`
  }, (payload) => {
    // Refresh notifications when any change occurs
    fetchNotifications();
  })
  .subscribe();
```

## 5. Complete Flow Diagram

```
Admin Creates Job
       ↓
Insert into `jobs` table
       ↓
Database Trigger Fires
       ↓
notify_drivers_on_job_creation() function
       ↓
Query: Get all online drivers (user_status.is_online = true)
       ↓
For each online driver:
  ├─ Check driver preferences (location, rate)
  ├─ Create notification in `notifications` table
  └─ Store: user_id, title, message, type='job_creation', data={jobId, ...}
       ↓
Real-Time Subscription (DriverHomeScreen)
       ↓
Postgres Changes Event: INSERT into notifications
       ↓
Update unread notification count badge
       ↓
User clicks bell icon
       ↓
Navigate to NotificationsScreen
       ↓
Display all notifications for user
```

## 6. Key Files

### Database Migrations
- `src/migrations/009_create_notifications_table.sql` - Creates notifications table
- `src/migrations/108_fix_job_creation_notifications_for_online_drivers.sql` - Trigger function
- `src/migrations/118_fix_notifications_rls_policies.sql` - RLS policies

### React Native Screens
- `src/screens/DriverHomeScreen.tsx` - Shows notification badge count
- `src/screens/NotificationsScreen.tsx` - Displays all notifications

### Services
- `src/services/notificationService.ts` - Handles push notifications

## 7. Important Notes

1. **Online Status Required**: Only drivers with `is_online = true` in `user_status` table receive notifications
2. **One Notification Per Driver**: Each driver gets their own notification record
3. **Real-Time Updates**: Both DriverHomeScreen and NotificationsScreen subscribe to real-time changes
4. **RLS Policies**: Users can only see their own notifications (`user_id = auth.uid()`)
5. **Trigger Security**: Trigger runs with `SECURITY DEFINER` to bypass RLS for inserts

## 8. Testing

To test the notification flow:
1. Ensure driver is online (`user_status.is_online = true`)
2. Admin creates a new job
3. Check `notifications` table for new records
4. Verify notification appears in DriverHomeScreen badge
5. Open NotificationsScreen to see full notification



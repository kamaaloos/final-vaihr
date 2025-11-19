# Job Status Change Notifications for Admins

## Overview

This implementation provides automatic notifications to admins whenever a job status changes. The system uses a database trigger to ensure reliable notification delivery regardless of how the status change occurs.

## Features

### Automatic Notifications
- **Job Accepted**: When a driver accepts an open job (status: open → assigned)
- **Job Started**: When a driver starts working on an assigned job (status: assigned → in_progress)
- **Job Completed**: When a driver completes a job (status: in_progress → completed)
- **Job Cancelled**: When a job is cancelled (status: any → cancelled)
- **Generic Updates**: For any other status changes

### Smart Content
- Includes driver name when available
- Provides context about the status change
- Links to the specific job for easy access

## Implementation Details

### 1. Database Trigger (`src/migrations/082_add_job_status_notification_trigger.sql`)

The trigger automatically creates notification records in the database whenever a job status changes:

```sql
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_on_job_status_change();
```

**Key Features:**
- Only triggers when status actually changes
- Handles all status transitions
- Includes driver information when available
- Graceful error handling (doesn't break job updates)
- Logs notifications for debugging

### 2. Notification Service (`src/services/notificationService.ts`)

A centralized service for handling push notifications:

```typescript
export class NotificationService {
  // Send push notification for a job status change
  static async sendJobStatusNotification(notification: JobStatusNotification): Promise<void>
  
  // Subscribe to new job notifications and send push notifications automatically
  static subscribeToJobNotifications(): () => void
  
  // Get unread notification count for a user
  static async getUnreadNotificationCount(userId: string): Promise<number>
  
  // Mark all notifications as read for a user
  static async markAllNotificationsAsRead(userId: string): Promise<void>
}
```

### 3. Updated AdminHomeScreen (`src/screens/AdminHomeScreen.tsx`)

Enhanced to use the new notification service:

- Imports `NotificationService`
- Uses centralized notification subscription
- Automatically marks notifications as read when viewing
- Improved notification count handling

### 4. Cleaned Up DriverHomeScreen (`src/screens/DriverHomeScreen.tsx`)

Removed duplicate notification logic since the database trigger now handles this automatically:

- Removed manual notification sending from `acceptJob()`
- Removed manual notification sending from `completeJob()`
- Cleaner, more maintainable code

## Notification Flow

1. **Job Status Change**: Driver or admin updates job status
2. **Database Trigger**: Automatically creates notification record
3. **Real-time Subscription**: AdminHomeScreen subscribes to new notifications
4. **Push Notification**: NotificationService sends push notification
5. **UI Update**: Notification badge updates in real-time

## Database Schema

### Notifications Table
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'job', 'chat', 'system'
    data JSONB, -- Additional data like jobId, oldStatus, newStatus
    push_token TEXT,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Usage

### For Admins
1. Ensure push notifications are enabled in the app
2. Notifications will appear automatically when job status changes
3. Tap the notification bell to view all notifications
4. Notifications are automatically marked as read when viewed

### For Developers
1. Run the migration: `run_migration.sql`
2. The system works automatically - no additional code needed
3. All job status changes will trigger notifications
4. Check logs for debugging information

## Benefits

### Reliability
- Database-level trigger ensures notifications are always created
- No dependency on client-side code execution
- Works regardless of how the status change occurs

### Performance
- Minimal overhead on job updates
- Efficient notification delivery
- Real-time updates without polling

### Maintainability
- Centralized notification logic
- Clean separation of concerns
- Easy to extend for new notification types

### User Experience
- Immediate feedback for admins
- Rich notification content
- Seamless integration with existing UI

## Testing

To test the notification system:

1. **Create a job** as an admin
2. **Accept the job** as a driver
3. **Start the job** as a driver
4. **Complete the job** as a driver
5. **Check admin notifications** for each status change

Each step should trigger an appropriate notification to the admin.

## Troubleshooting

### Common Issues

1. **No notifications received**
   - Check if admin has push token in database
   - Verify notification permissions are granted
   - Check database logs for trigger execution

2. **Duplicate notifications**
   - Ensure old notification code is removed
   - Check for multiple trigger subscriptions

3. **Missing driver names**
   - Verify driver has name in user metadata
   - Check auth.users table for driver information

### Debug Information

The trigger logs detailed information:
- Notification creation success/failure
- Driver name resolution
- Push token availability
- Error details if any

Check database logs for these messages when troubleshooting. 
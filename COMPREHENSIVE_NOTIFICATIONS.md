# Comprehensive Notification System

## Overview

This implementation provides a complete notification system that automatically notifies users about all important events in the application. The system uses database triggers to ensure reliable notification delivery regardless of how events occur.

## Notification Types

### 1. Job Creation Notifications (`job_creation`)
**Triggered when:** An admin creates a new job
**Recipients:** All active drivers with push tokens
**Content:** 
- Title: "New Job Available"
- Message: "{Admin Name} posted a new job: {Job Title}"
- Data: Job details, admin info, location, rate

**Smart Filtering:**
- Only notifies online drivers
- Respects driver preferences (excluded locations, minimum rates)
- Only sends to drivers with valid push tokens

### 2. Job Status Change Notifications (`job_status`)
**Triggered when:** Job status changes (open → assigned → in_progress → completed)
**Recipients:** Admin who created the job
**Content:**
- **Job Accepted:** "Job '{title}' has been accepted by {driver_name}"
- **Job Started:** "Job '{title}' has been started by {driver_name}"
- **Job Completed:** "Job '{title}' has been completed by {driver_name}"
- **Job Cancelled:** "Job '{title}' has been cancelled by {driver_name}"
- **Generic:** "Job '{title}' status changed from {old_status} to {new_status}"

### 3. Invoice Creation Notifications (`invoice_creation`)
**Triggered when:** A job is completed and an invoice is automatically generated
**Recipients:** Admin who created the job
**Content:**
- Title: "Invoice Generated"
- Message: "Invoice {number} generated for job '{title}' completed by {driver_name} (€{amount})"
- Data: Invoice details, job info, driver info, amount

### 4. Invoice Payment Notifications (`invoice_payment`)
**Triggered when:** Invoice status changes from 'pending' to 'paid'
**Recipients:** Both admin and driver
**Content:**
- **Admin:** "Payment received for invoice {number} (€{amount}) - Job: {title}"
- **Driver:** "Payment confirmed for invoice {number} (€{amount}) - Job: {title}"

## Database Implementation

### Triggers Created

1. **`job_creation_notification_trigger`** (AFTER INSERT ON jobs)
   - Notifies drivers about new jobs
   - Filters based on driver preferences
   - Only notifies online drivers

2. **`job_status_notification_trigger`** (AFTER UPDATE ON jobs)
   - Notifies admin about job status changes
   - Includes driver information when available
   - Handles all status transitions

3. **`invoice_creation_notification_trigger`** (AFTER INSERT ON invoices)
   - Notifies admin when invoices are created
   - Includes job and driver details
   - Shows invoice amount

4. **`invoice_status_notification_trigger`** (AFTER UPDATE ON invoices)
   - Notifies both admin and driver about payments
   - Only triggers on status change to 'paid'

### Helper Functions

- **`should_notify_driver()`**: Determines if a driver should be notified based on preferences
- **`notify_drivers_on_job_creation()`**: Handles job creation notifications
- **`notify_admin_on_job_status_change()`**: Handles job status change notifications
- **`notify_admin_on_invoice_creation()`**: Handles invoice creation notifications
- **`notify_on_invoice_status_change()`**: Handles invoice payment notifications

## Frontend Integration

### NotificationService

The enhanced `NotificationService` provides:

```typescript
// Subscribe to all notifications
NotificationService.subscribeToNotifications()

// Subscribe to specific notification types
NotificationService.subscribeToJobNotifications()
NotificationService.subscribeToInvoiceNotifications()

// Get notification counts
NotificationService.getUnreadNotificationCount(userId)
NotificationService.getUnreadNotificationCountByType(userId, type)

// Mark notifications as read
NotificationService.markAllNotificationsAsRead(userId)
NotificationService.markNotificationsAsReadByType(userId, type)

// Get notifications with filtering
NotificationService.getNotifications(userId, options)
```

### Notification Types

```typescript
interface JobStatusNotification {
  type: 'job_status';
  data: { jobId, oldStatus, newStatus, driverId, driverName, driverEmail };
}

interface JobCreationNotification {
  type: 'job_creation';
  data: { jobId, jobTitle, jobLocation, jobRate, adminName, adminEmail };
}

interface InvoiceCreationNotification {
  type: 'invoice_creation';
  data: { invoiceId, invoiceNumber, jobId, jobTitle, driverId, driverName, amount };
}

interface InvoicePaymentNotification {
  type: 'invoice_payment';
  data: { invoiceId, invoiceNumber, jobId, jobTitle, amount, oldStatus, newStatus };
}
```

## User Experience

### For Admins
1. **Job Creation:** No action needed - notifications are automatic
2. **Job Status Changes:** Receive notifications when drivers accept, start, or complete jobs
3. **Invoice Creation:** Automatically notified when invoices are generated
4. **Payment Notifications:** Notified when drivers mark invoices as paid

### For Drivers
1. **New Jobs:** Receive notifications for new jobs that match their preferences
2. **Payment Confirmations:** Notified when their invoices are marked as paid

### Smart Features
- **Preference-based filtering:** Drivers only get notified about relevant jobs
- **Online status:** Only online drivers receive job creation notifications
- **Rate filtering:** Drivers can set minimum rates
- **Location filtering:** Drivers can exclude specific locations
- **Automatic cleanup:** Old read notifications are automatically deleted

## Benefits

### Reliability
- Database-level triggers ensure notifications are always created
- No dependency on client-side code execution
- Works regardless of how events occur (API, direct DB, etc.)

### Performance
- Minimal overhead on database operations
- Efficient notification delivery
- Real-time updates without polling

### User Experience
- Immediate feedback for all important events
- Rich notification content with relevant details
- Smart filtering reduces notification noise
- Seamless integration with existing UI

### Maintainability
- Centralized notification logic
- Clean separation of concerns
- Easy to extend for new notification types
- Comprehensive logging for debugging

## Testing Scenarios

### Job Creation Flow
1. Admin creates a new job
2. System automatically notifies relevant drivers
3. Drivers receive push notifications
4. Notification records are created in database

### Job Status Flow
1. Driver accepts a job (open → assigned)
2. Admin receives notification
3. Driver starts job (assigned → in_progress)
4. Admin receives notification
5. Driver completes job (in_progress → completed)
6. Admin receives notification

### Invoice Flow
1. Job completion triggers invoice creation
2. Admin receives invoice creation notification
3. Admin marks invoice as paid
4. Both admin and driver receive payment notifications

## Troubleshooting

### Common Issues

1. **No notifications received**
   - Check if user has push token in database
   - Verify notification permissions are granted
   - Check database logs for trigger execution

2. **Drivers not receiving job notifications**
   - Verify driver is online
   - Check driver preferences (excluded locations, minimum rates)
   - Ensure driver has valid push token

3. **Duplicate notifications**
   - Ensure old notification code is removed
   - Check for multiple trigger subscriptions

4. **Missing user names**
   - Verify user has name in user metadata
   - Check auth.users table for user information

### Debug Information

All triggers log detailed information:
- Notification creation success/failure
- User name resolution
- Push token availability
- Preference filtering results
- Error details if any

Check database logs for these messages when troubleshooting.

## Migration

To apply the comprehensive notification system:

1. Run the migration: `src/migrations/083_comprehensive_notification_triggers.sql`
2. Update frontend code to use the enhanced `NotificationService`
3. Remove any duplicate notification logic from screens
4. Test all notification flows

The system works automatically once the migration is applied - no additional code needed for basic functionality. 
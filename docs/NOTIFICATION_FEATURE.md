# Notification Feature Documentation

## Overview

The notification system in the mobile app allows students to receive and manage important messages from staff members. The system is designed to track read/unread status and display important notifications separately.

## Features

### For Students:
- View all notifications sent to them
- See unread notifications in a dedicated tab
- View important notifications in a separate tab
- Notifications automatically marked as read when viewed
- Visual indicators showing read/unread status

### For Staff (via Admin Panel):
- Send notifications to specific students or groups of students
- Mark notifications as important
- Categorize notifications for better organization

## Technical Implementation

### Data Flow:
1. Notifications are created by staff in the admin panel
2. Backend creates entries in the Notification table and NotificationRecipient table
3. Mobile app fetches notifications for the logged-in student
4. When a notification is viewed, the isRead status is updated in the NotificationRecipient table

### Key Components:

1. **NotificationRecipient table**: 
   - Tracks which students have received which notifications
   - Stores read status and read datetime for each notification per student
   - Enables filtering by read/unread status

2. **Notification tabs**:
   - All: Shows all notifications for the student
   - Unread: Shows only unread notifications
   - Important: Shows notifications marked as important by staff

3. **Read Status Handling**:
   - Notifications are automatically marked as read when opened
   - Read status is visually indicated with color and dot indicator
   - Unread count is shown in the tab bar

## API Endpoints

- `GET /api/notifications` - Get all notifications for the logged-in student
- `GET /api/notifications/unread` - Get only unread notifications
- `GET /api/notifications/important` - Get important notifications
- `POST /api/notifications/:id/read` - Mark a notification as read

## Future Enhancements

- Allow marking notifications as unread
- Push notification support for real-time delivery
- Notification actions (e.g., confirming attendance, submitting a response)
- Bulk actions (mark all as read, delete multiple)

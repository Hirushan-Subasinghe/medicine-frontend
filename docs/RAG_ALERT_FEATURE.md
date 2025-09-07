# RAG Alert Feature Documentation

## Overview
The RAG Alert (Ragging Alert) feature provides a quick way for students to send emergency alerts when experiencing ragging incidents. The system captures location data, student information, and sends an SMS alert to authorities.

## Key Functionality
1. **Verification Process**: Two-step confirmation before sending alert
2. **Location Detection**: Automatically captures GPS coordinates
3. **Student Identification**: Includes student name and ID in alerts
4. **Database Logging**: Records incident details in backend database
5. **SMS Notification**: Sends immediate alert to emergency contacts
6. **Fallback Mechanisms**: Continues alert process even if some steps fail

## Components

### Frontend (Flutter)
1. **Emergency FAB Menu** (`emergency_fab_menu.dart`)
   - Floating Action Button with verification dialog
   - Provides visual feedback during alert sending process
   - Displays success/error messages

2. **RagAlertService** (`rag_alert_service.dart`)
   - Coordinates the alert sending process
   - Retrieves location data using Geolocator
   - Gets user information via RagAlertController
   - Updates database and sends SMS notification
   - Handles failure scenarios with fallbacks

3. **RagAlertController** (`rag_alert_controller.dart`)
   - Handles API calls to the backend
   - Manages authentication tokens
   - Provides mock data during testing

4. **TwilioService** (`twilio_service.dart`)
   - Sends SMS messages via Twilio
   - Validates phone numbers
   - Handles error cases

5. **AppConfig** (`app_config.dart`)
   - Stores configuration settings
   - Provides test/mock data
   - Contains emergency contact information

### Backend (Node.js)
1. **Test Server** (`test-server.js`)
   - Simple Express server for testing the alert API
   - Handles authentication via token verification
   - Provides mock responses for API calls

2. **RAG Alert Routes** (`routes/ragAlertRoutes.js`)
   - Defines API endpoints for RAG alerts
   - Applies authentication middleware

3. **RAG Alert Controller** (`controllers/ragAlertController.js`)
   - Processes incoming alert requests
   - Updates the database via Prisma ORM
   - Handles error cases

## Alert Flow
1. User taps the Emergency button and confirms the alert
2. App retrieves current location (with permission)
3. App gets student information (from local auth or API)
4. App sends alert data to backend API
5. App sends SMS notification via Twilio
6. User receives confirmation of successful alert

## Error Handling
- If location services are disabled, the alert continues with "unknown location"
- If API call fails, SMS is still sent as a fallback
- If SMS sending fails, app attempts alternative notification methods
- All errors are logged for debugging

## Testing
Run the test server with:
```bash
node test-server.js
```

The server listens on port 5002 and provides mock responses.

## Configuration
- Emergency contact numbers are defined in `app_config.dart`
- API endpoints are defined in `constants.dart`
- Twilio credentials are stored in `twilio_service.dart`

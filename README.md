# Freshers Connect

Freshers Connect is a Flutter-based student companion app for medicine and university life. It combines authentication, notifications, campus navigation, study resources, profile management, and emergency alerting in one mobile experience.

## What it does

The app is designed to keep students connected to academic updates and campus services from a single dashboard. After sign-in, users are taken to a personalized home screen with quick access to university resources, notifications, maps, downloads, and profile tools.

## Key Features

### Secure sign-in
- Firebase Authentication drives the login flow.
- Authenticated users land directly in the main app shell.
- Session-dependent services are initialized after login.

### Personalized home dashboard
- Greets the signed-in student by name.
- Shows academic context when student details are available.
- Provides shortcuts to LMS, faculty library, university library, university website, faculty website, and the student portal.
- Includes a floating emergency action menu for urgent situations.

### Notifications center
- Lists all notifications, unread notifications, and important notifications.
- Shows unread counts in the tab bar and bottom navigation badge.
- Marks notifications as read when opened.
- Supports notification detail views for deeper reading.

### Campus map and place search
- Displays an interactive campus map.
- Uses location services to move to the student’s current position.
- Supports searching custom places and nearby locations.
- Pulls place data from backend services when available.

### Student profile management
- Displays profile details such as name, student number, level, and academic year.
- Allows profile image updates from the device gallery.
- Provides account actions such as edit profile, change password, and password recovery.

### Learning materials and downloads
- Fetches downloadable material categories from the backend.
- Lets students browse and download study resources.
- Handles storage permission requests for file downloads.
- Opens downloaded files from the device.

### Emergency RAG alert flow
- Supports a RAG alert workflow for urgent incidents.
- Captures location data before sending an alert.
- Sends notification data through backend and SMS integrations.
- Includes test pages for Twilio and RAG alert flows during development.

## Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Messaging
- Firebase Storage
- Provider
- Geolocator and Flutter Map
- Twilio integration
- Dio and HTTP for backend communication

## Project Structure

- lib/views - UI screens and tabs
- lib/controllers - feature controllers and API orchestration
- lib/services - Firebase, notifications, map, and alert services
- lib/models - app data models
- docs - feature and deployment notes
- android, ios, web, windows, linux, macos - platform targets

## Getting Started

### Prerequisites

- Flutter SDK 3.7 or newer
- Android Studio, Xcode, or Visual Studio depending on your target platform
- A configured Firebase project

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build a release version

Use the release scripts in the repository root or the standard Flutter build commands for your target platform.

## Firebase and backend setup

- Android Firebase config is stored in android/app/google-services.json.
- Make sure your Firebase project matches the package configuration used by the app.
- Review the docs folder for deployment and feature-specific setup notes.

## Useful docs

- docs/NOTIFICATION_FEATURE.md
- docs/RAG_ALERT_FEATURE.md
- docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md
- docs/MOBILE_PRODUCTION_DEPLOYMENT.md

## Notes

This repository currently includes development and test routes for Twilio and emergency alert verification. They are useful for debugging but should be kept out of the normal student workflow in production builds.

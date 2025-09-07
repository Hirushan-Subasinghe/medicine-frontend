# Mobile App Production Deployment Guide

This guide provides steps to ensure your Flutter mobile app connects properly to your Oracle Cloud backend in a production environment.

## Step 1: Update Production Constants

Update `lib/core/constants_prod.dart` with your actual Oracle Cloud backend URL:

```dart
// Production API endpoint
const String baseUrl = "https://your-oracle-cloud-instance.com";  // Replace with your actual domain or IP

// Debug mode (set to false in production)
const bool debugMode = false;
```

## Step 2: Configure Android and iOS Builds

### Android Configuration

1. Update your `android/app/build.gradle` file to ensure the correct release configuration:

```gradle
android {
    // ...existing configuration...
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

2. Ensure your `android/app/src/main/AndroidManifest.xml` has the appropriate internet permissions:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- Other permissions -->
</manifest>
```

### iOS Configuration

1. Update your Info.plist file to allow non-HTTPS URLs if needed (though HTTPS is strongly recommended for production):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Step 3: Enable Production Mode in Main Application

Modify your `main.dart` file to use the production constants in release mode:

```dart
import 'package:flutter/foundation.dart';
import 'core/constants.dart';        // Development constants
import 'core/constants_prod.dart';   // Production constants

void main() {
  // Set the appropriate constants file based on the build mode
  if (kReleaseMode) {
    // Use production constants
    // You would need to implement a way to swap the constants
    // This could involve a separate entry point or conditional imports
  }
  
  runApp(MyApp());
}
```

## Step 4: Build for Production

### Building for Android

```bash
# Generate a signed APK
flutter build apk --release

# Or generate an Android App Bundle for Google Play
flutter build appbundle --release
```

### Building for iOS

```bash
# Build the iOS release
flutter build ios --release

# Then archive and upload through Xcode
```

## Step 5: Test Production Build

Before publishing, install the production build on physical devices and test connectivity:

1. Use the **Connection Diagnostic** page to verify:
   - Backend connection status
   - API endpoint configuration
   - Database connectivity
   - Authentication functionality

2. Run the **Network Monitor** to check:
   - Response times
   - Connection stability
   - API endpoint health

3. Test Authentication:
   - Login
   - Registration
   - Password reset
   - Firebase token validation

## Step 6: Monitor and Debug Production Issues

1. Implement remote logging:
   ```dart
   try {
     // API calls
   } catch (e) {
     // Log error to remote service
     logToRemoteService(e.toString(), stackTrace);
   }
   ```

2. Use Firebase Crashlytics to monitor crashes

3. Implement an in-app feedback mechanism for user-reported issues

## Troubleshooting Common Issues

### Backend Connection Issues

- **Problem**: App cannot connect to backend
- **Solution**: 
  - Verify the `baseUrl` in `constants_prod.dart`
  - Check network security group rules in Oracle Cloud
  - Confirm SSL/TLS certificates are valid and trusted

### Authentication Failures

- **Problem**: Firebase authentication works but backend login fails
- **Solution**:
  - Verify Firebase project settings match between app and backend
  - Check token validation in backend services
  - Ensure the appropriate Firebase SDK versions are used

### Slow Response Times

- **Problem**: Backend responses are slow in production
- **Solution**:
  - Implement caching for frequently accessed data
  - Optimize database queries
  - Consider scaling up Oracle Cloud resources
  - Add a CDN for static content

## Post-Deployment Checklist

- [ ] Regular monitoring of backend health
- [ ] Schedule regular database backups
- [ ] Setup alert notifications for downtime or high error rates
- [ ] Plan for regular updates and maintenance windows
- [ ] Monitor app reviews for user-reported issues

## Security Best Practices

- Implement SSL pinning for added security
- Regularly rotate API keys and secrets
- Implement rate limiting to prevent abuse
- Audit backend logs for suspicious activities
- Keep all dependencies updated with security patches

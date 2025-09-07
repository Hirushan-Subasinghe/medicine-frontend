# Android App Deployment Guide

This guide will help you deploy your Flutter app to Android phones after having successfully set up your Node.js backend on a VM.

## Prerequisites

1. A working Node.js backend on a VM with a public IP address or domain name
2. Flutter SDK installed and configured
3. An Android device for testing
4. USB debugging enabled on your Android device (for direct installation)

## Step 1: Update Production API URL

Before building your app for production, you need to configure it to point to your production backend:

1. Open `lib/core/constants_prod.dart`
2. Update the `baseUrl` constant to point to your VM's IP address or domain name:
   ```dart
   const String baseUrl = "https://your-vm-ip-or-domain.com"; // Replace with your actual VM URL
   ```

## Step 2: Build the Release APK

You have two options for building your app:

### Option 1: Using the Provided Script

Run the PowerShell script to automatically update your constants and build the app:

```
.\build_release.ps1 -baseUrl "https://your-vm-ip-or-domain.com"
```

### Option 2: Manual Build

If you prefer to build manually:

1. Clean your Flutter project:
   ```
   flutter clean
   ```

2. Get dependencies:
   ```
   flutter pub get
   ```

3. Build the APK:
   ```
   flutter build apk --release
   ```

The release APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Step 3: Distribute the APK to Android Devices

You have several options to distribute your APK:

### Direct Installation (Development/Testing)

1. Connect your Android device via USB
2. Enable USB debugging in your phone's developer options
3. Run:
   ```
   flutter install
   ```

### Distribution via File Sharing

1. Copy the APK file from `build/app/outputs/flutter-apk/app-release.apk`
2. Share it via email, cloud storage, or messaging apps
3. On the Android device, download the APK and tap to install

**Note:** The user might need to enable "Install from Unknown Sources" in their Android settings.

### Enterprise Distribution

For larger organizations:
1. Host the APK on an internal website
2. Use QR codes linking to the download URL
3. Deploy using Mobile Device Management (MDM) solutions

## Step 4: Test the Production Build

After installing the app on your device, test the following:

1. Launch the app and check if it connects to your backend server
2. Use the Network Monitor page to verify connectivity
3. Test all critical features that interact with the backend
4. Check if authentication works properly
5. Verify that data sync functions correctly

## Troubleshooting Common Issues

### App Cannot Connect to Backend

If the app shows connection errors:

1. Verify your backend is running and accessible
2. Check that you used the correct URL in `constants_prod.dart`
3. Make sure your VM's firewall allows connections on the required port
4. Test the backend URL directly in a browser to ensure it responds

### SSL/HTTPS Issues

If your app requires HTTPS but can't connect:

1. Ensure your backend has a valid SSL certificate
2. If using a self-signed certificate, consider setting up proper certificate validation

### Slow Performance

If the app performs slowly when connected to the production backend:

1. Use the Network Monitor to check API response times
2. Consider optimizing your server or implementing caching
3. Check if the VM has sufficient resources

## Next Steps

- Set up automated builds using CI/CD pipelines
- Configure crash reporting using Firebase Crashlytics
- Implement analytics to monitor user behavior and app performance
- Consider publishing your app on the Google Play Store for wider distribution

#!/bin/bash
# Flutter Android Release Build Script for bash/sh environments

echo "========= Flutter Android Release Build ========="

# Prompt for backend URL if not provided
if [ -z "$1" ]; then
  read -p "Enter your production backend URL (e.g., https://your-vm-ip.com): " BACKEND_URL
else
  BACKEND_URL=$1
fi

echo "Using production URL: $BACKEND_URL"

# Update constants_prod.dart with the provided baseUrl
CONSTANTS_FILE="lib/core/constants_prod.dart"
sed -i "s|const String baseUrl = \"https://your-vm-ip-or-domain.com\";|const String baseUrl = \"$BACKEND_URL\";|g" $CONSTANTS_FILE

echo "Updated constants_prod.dart with production URL"

# Clean and get dependencies
echo "Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# Build APK
echo "Building APK for distribution..."
flutter build apk --release

if [ $? -eq 0 ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        echo "Build successful! APK is located at: $APK_PATH"
        echo ""
        echo "To install on a connected Android device, run:"
        echo "flutter install"
        echo ""
    else
        echo "APK was not found at the expected location. Check the build output for errors."
    fi
else
    echo "Build failed. Please check the error messages above."
fi

echo "========= Build Process Complete ========="

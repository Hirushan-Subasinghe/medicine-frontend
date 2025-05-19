#!/usr/bin/env pwsh
# Flutter Android Release Build Script

# Check if baseUrl is provided as an argument
param (
    [string]$baseUrl = $null
)

Write-Host "========= Flutter Android Release Build ========="

# Check for required baseUrl
if (-not $baseUrl) {
    $baseUrl = Read-Host "Enter your production backend URL (e.g., https://your-vm-ip.com)"
}

Write-Host "Using production URL: $baseUrl"

# Update constants_prod.dart with the provided baseUrl
$constantsFile = "lib/core/constants_prod.dart"
$content = Get-Content $constantsFile -Raw
$updatedContent = $content -replace 'const String baseUrl = "https://your-vm-ip-or-domain.com";', "const String baseUrl = `"$baseUrl`";"
$updatedContent | Set-Content $constantsFile

Write-Host "Updated constants_prod.dart with production URL"

# Increment version in pubspec.yaml 
# Note: In a real production scenario, you might want to implement proper versioning logic
Write-Host "Updating version in pubspec.yaml"
$pubspecFile = "pubspec.yaml"
$pubspec = Get-Content $pubspecFile -Raw
$versionMatch = [regex]::Match($pubspec, 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
if ($versionMatch.Success) {
    $major = [int]$versionMatch.Groups[1].Value
    $minor = [int]$versionMatch.Groups[2].Value
    $patch = [int]$versionMatch.Groups[3].Value
    $build = [int]$versionMatch.Groups[4].Value
    
    # Increment build number
    $build++
    
    $newVersion = "version: $major.$minor.$patch+$build"
    $updatedPubspec = $pubspec -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newVersion
    $updatedPubspec | Set-Content $pubspecFile
    
    Write-Host "Updated version to $major.$minor.$patch+$build"
}

# Run flutter build with the appropriate constants
Write-Host "Building APK for distribution..."
flutter clean
flutter pub get

# Building APK (directly installable on Android devices)
flutter build apk --release

# You can uncomment the next line if you want to build an app bundle for Google Play Store
# flutter build appbundle --release

if ($LASTEXITCODE -eq 0) {
    $apkPath = "build/app/outputs/flutter-apk/app-release.apk"
    if (Test-Path $apkPath) {
        Write-Host "Build successful! APK is located at: $apkPath"
        Write-Host ""
        Write-Host "To install on a connected Android device, run:"
        Write-Host "flutter install"
        Write-Host ""
    } else {
        Write-Host "APK was not found at the expected location. Check the build output for errors."
    }
} else {
    Write-Host "Build failed. Please check the error messages above."
}

Write-Host "========= Build Process Complete ========="

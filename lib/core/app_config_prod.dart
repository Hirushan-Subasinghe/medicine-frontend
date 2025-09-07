// File: lib/core/app_config.dart for production
class AppConfig {
  // App mode
  static const bool isDebugMode = false;
  static const bool isTestMode = false; // Set to false in production
  
  // API configuration
  static const int apiTimeout = 30; // in seconds, increased for production
  
  // Emergency contact numbers
  static const String primaryEmergencyContact = '+94714719886';
  static const List<String> secondaryEmergencyContacts = [
    // Add additional emergency numbers here
  ];
}

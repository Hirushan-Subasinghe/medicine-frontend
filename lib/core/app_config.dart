// File: e:\Hiru\medicine\lib\core\app_config.dart
class AppConfig {
  // App mode
  static const bool isDebugMode = true;
  static const bool isTestMode = true; // Set to false in production
  
  // API configuration
  static const int apiTimeout = 10; // in seconds
  
  // Emergency contact numbers
  static const String primaryEmergencyContact = '+18777804236';
  static const List<String> secondaryEmergencyContacts = [
    // Add additional emergency numbers here
  ];
  
  // Mock data for testing
  static const Map<String, dynamic> mockUserData = {
    'firstName': 'Test',
    'lastName': 'Student',
    'email': 'test@example.com',
    'student': {
      'studentNumber': 'ST12345',
      'faculty': 'Medicine',
      'batch': '2022'
    }
  };
}

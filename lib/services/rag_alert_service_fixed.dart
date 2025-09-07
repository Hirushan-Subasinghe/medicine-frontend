import 'package:freshers_connect/services/twilio_service.dart';
import '../controllers/rag_alert_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../core/app_config.dart';
import '../core/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class RagAlertService {
  static final RagAlertService _instance = RagAlertService._internal();
  final TwilioService _twilioService = TwilioService();
  final RagAlertController _ragAlertController = RagAlertController();
  
  factory RagAlertService() {
    return _instance;
  }
  
  RagAlertService._internal();
  
  /// Send a ragging alert SMS to emergency contacts and staff
  /// 
  /// Parameters:
  ///   - studentName: Name of the student sending the alert
  ///   - studentId: ID of the student
  ///   - location: Description of location (e.g., "Engineering Building, Floor 2")
  ///   - coordinates: Optional latitude and longitude as string "lat,lng"
  ///   - emergencyContactNumbers: List of emergency contact phone numbers
  Future<bool> sendRaggingAlertSMS({
    required String studentName,
    required String studentId,
    required String location,
    String? coordinates,
    required List<String> emergencyContactNumbers,
  }) async {
    bool allSent = true;
    
    // Create the alert message
    final String message = _createAlertMessage(
      studentName: studentName,
      studentId: studentId,
      location: location,
      coordinates: coordinates,
    );
    
    // Send to all emergency contacts
    for (final phoneNumber in emergencyContactNumbers) {
      try {
        final success = await _twilioService.sendSMS(
          to: phoneNumber,
          messageBody: message,
        );
        
        if (!success) {
          allSent = false;
          print('Failed to send SMS to $phoneNumber');
        }
      } catch (e) {
        allSent = false;
        print('Error sending SMS to $phoneNumber: $e');
      }
    }
    
    return allSent;
  }
  
  /// Create the alert message text
  String _createAlertMessage({
    required String studentName,
    required String studentId,
    required String location,
    String? coordinates,
  }) {
    final String locationInfo = coordinates != null 
        ? '$location (Coordinates: $coordinates)' 
        : location;
        
    return 'RAGGING ALERT: $studentName (ID: $studentId) has reported a ragging incident at $locationInfo. Please respond immediately.';
  }
  
  /// Send a test alert message
  Future<bool> sendTestAlert(String phoneNumber) async {
    const String testMessage = 'This is a TEST RAGGING ALERT from the Anti-Ragging System. If this were a real alert, emergency response would be activated.';
    return await _twilioService.sendSMS(to: phoneNumber, messageBody: testMessage);
  }
  
  /// Send a verification test for the entire RAG alert system
  /// This tests the full workflow without sending to actual emergency contacts
  Future<Map<String, dynamic>> verifyRagAlertSystem({String? testPhoneNumber}) async {
    print('Running RAG Alert System verification...');
    
    Map<String, dynamic> result = {
      'success': false,
      'tests': {
        'location': false,
        'user': false,
        'database': false,
        'sms': 'skipped', // We don't actually send SMS in verification
      }
    };
    
    try {
      // Test 1: Location services
      try {
        print('Testing location services...');
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            );
            result['tests']['location'] = true;
            result['locationData'] = {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
            };
            print('✓ Location test passed: ${position.latitude}, ${position.longitude}');
          } else {
            print('✗ Location permissions not granted: $permission');
            result['locationError'] = 'Permission not granted: $permission';
          }
        } else {
          print('✗ Location services disabled');
          result['locationError'] = 'Location services disabled';
        }
      } catch (e) {
        print('✗ Location test failed: $e');
        result['locationError'] = '$e';
      }
      
      // Test 2: User information
      try {
        print('Testing user information retrieval...');
        final userResult = await _ragAlertController.getCurrentUser();
        if (userResult['success']) {
          result['tests']['user'] = true;
          result['userData'] = userResult['data'];
          print('✓ User test passed: ${userResult['data']['firstName']} ${userResult['data']['lastName']}');
        } else {
          print('✗ User test failed: ${userResult['error']}');
          result['userError'] = userResult['error'];
        }
      } catch (e) {
        print('✗ User test failed with exception: $e');
        result['userError'] = '$e';
      }
      
      // Test 3: Database connection
      try {
        print('Testing database connection...');
        // Just check if we can connect to the API
        final response = await http.get(Uri.parse('$baseUrl'));
        if (response.statusCode < 500) { // Accept any response that's not a server error
          result['tests']['database'] = true;
          print('✓ API connection test passed: Status ${response.statusCode}');
        } else {
          print('✗ API connection test failed: Status ${response.statusCode}');
          result['databaseError'] = 'Server error: ${response.statusCode}';
        }
      } catch (e) {
        print('✗ API connection test failed: $e');
        result['databaseError'] = '$e';
      }
      
      // Overall success is based on the critical tests
      result['success'] = result['tests']['location'] && result['tests']['user'];
      
      return result;
    } catch (e) {
      print('Verification failed with error: $e');
      return {
        'success': false,
        'error': '$e',
      };
    }
  }
  
  /// Send an emergency alert with database update
  /// Returns a map with success status and any error messages
  Future<Map<String, dynamic>> sendEmergencyAlert() async {
    Map<String, dynamic> result = {
      'success': false,
      'steps': {
        'locationAccess': false,
        'userInfoRetrieved': false,
        'databaseUpdated': false,
        'smsSent': false
      }
    };
    
    try {
      // 1. Get current location
      Position? position;
      try {
        print('Step 1: Getting current location...');
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Location services are disabled');
          result['locationError'] = 'Location services are disabled';
        } else {
          // Check for permissions
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              print('Location permissions are denied');
              result['locationError'] = 'Location permissions denied';
            }
          }
          
          if (permission == LocationPermission.deniedForever) {
            print('Location permissions are permanently denied');
            result['locationError'] = 'Location permissions permanently denied';
          }
          
          // Get position if allowed
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5), // Timeout after 5 seconds
            );
            result['steps']['locationAccess'] = true;
            print('Got location: ${position.latitude}, ${position.longitude}');
          }
        }
      } catch (e) {
        print('Error getting location: $e');
        result['locationError'] = '$e';
        // Continue even if we can't get location
      }
      
      // 2. Get current user details
      print('Step 2: Getting user information...');
      Map<String, dynamic> userResult;
      try {
        userResult = await _ragAlertController.getCurrentUser();
        print('User result: $userResult');
        if (!userResult['success']) {
          print('Error getting user details: ${userResult['error']}');
          result['userError'] = userResult['error'];
          // Continue with minimal info if we can't get user details
          userResult = {
            'success': true,
            'data': {
              'firstName': 'Emergency',
              'lastName': 'User',
              'student': {
                'studentNumber': 'EMERGENCY'
              }
            }
          };
        } else {
          result['steps']['userInfoRetrieved'] = true;
        }
      } catch (e) {
        print('Exception getting user details: $e');
        result['userError'] = '$e';
        // Provide fallback user info
        userResult = {
          'success': true,
          'data': {
            'firstName': 'Emergency',
            'lastName': 'User',
            'student': {
              'studentNumber': 'EMERGENCY'
            }
          }
        };
      }
      
      // 3. Create alert in database
      print('Step 3: Creating alert in database...');
      bool databaseUpdated = false;
      Map<String, dynamic> alertRecord = {};
      
      try {
        if (position != null) {
          final createResult = await _ragAlertController.createRagAlert(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          
          databaseUpdated = createResult['success'];
          result['steps']['databaseUpdated'] = databaseUpdated;
          
          if (!databaseUpdated) {
            print('Failed to create rag alert in database: ${createResult['error'] ?? createResult['warning']}');
            result['databaseError'] = createResult['error'] ?? createResult['warning'] ?? 'Unknown database error';
            
            // Additional debugging information
            if (createResult['statusCode'] != null) {
              result['dbStatusCode'] = createResult['statusCode'];
            }
            if (createResult['response'] != null) {
              result['dbResponse'] = createResult['response'];
            }
          } else {
            print('Rag alert created in database successfully');
            // Save the database record details if available
            if (createResult['data'] != null) {
              result['alertRecord'] = createResult;
              alertRecord = createResult['data'] ?? {};
              
              // Log detailed information about the created alert
              print('Alert created with ID: ${alertRecord['alertId'] ?? 'Unknown'}');
              print('Alert timestamp: ${alertRecord['alertDateTime'] ?? 'Unknown'}');
              print('Alert coordinates: ${alertRecord['latitude'] ?? 0}, ${alertRecord['longitude'] ?? 0}');
              if (alertRecord['studentId'] != null) {
                print('Student ID in database: ${alertRecord['studentId']}');
              }
              if (alertRecord['studentName'] != null) {
                print('Student Name in database: ${alertRecord['studentName']}');
              }
            }
          }
        } else {
          result['databaseError'] = 'Could not update database: Location data unavailable';
        }
      } catch (e) {
        print('Exception during database update: $e');
        result['databaseError'] = '$e';
        // Continue anyway to ensure SMS is sent
      }
      
      // 4. Prepare student data for the alert
      print('Step 4: Preparing student data for alert...');
      
      // Start with user information from user service
      String studentName = 'Unknown';
      String studentId = 'Unknown';
      
      if (userResult['success'] && userResult['data'] != null) {
        final userData = userResult['data'];
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        studentName = '$firstName $lastName'.trim();
        
        if (userData['student'] != null) {
          studentId = userData['student']['studentNumber'] ?? 'Unknown';
        }
        
        print('Using student info from user service: Name=$studentName, ID=$studentId');
      }
      
      // Update with DB record if available (this overrides the user service data)
      if (databaseUpdated && alertRecord.isNotEmpty) {
        // Override with database information if available
        if (alertRecord['studentName'] != null && alertRecord['studentName'].toString().isNotEmpty) {
          studentName = alertRecord['studentName'].toString();
          print('Using student name from database: $studentName');
        }
        
        if (alertRecord['studentId'] != null && alertRecord['studentId'].toString().isNotEmpty) {
          studentId = alertRecord['studentId'].toString();
          print('Using student ID from database: $studentId');
        }
      }
      
      String locationInfo = 'Unknown location';
      String? coordinates;
      if (position != null) {
        coordinates = '${position.latitude},${position.longitude}';
        locationInfo = 'Current location';
      }
      
      // Use DB coordinates if available
      if (databaseUpdated && alertRecord.isNotEmpty) {
        if (alertRecord['latitude'] != null && alertRecord['longitude'] != null) {
          coordinates = '${alertRecord['latitude']},${alertRecord['longitude']}';
          print('Using coordinates from database: $coordinates');
        }
      }
      
      String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      // Get alert record details from the database response if available
      String alertId = 'Unknown';
      String alertDateTime = timestamp; // Default to current timestamp if DB record not available
      
      // Extract database alert record if available
      if (databaseUpdated && alertRecord.isNotEmpty) {
        if (alertRecord['alertId'] != null) {
          alertId = alertRecord['alertId'].toString();
        }
        
        if (alertRecord['alertDateTime'] != null) {
          alertDateTime = alertRecord['alertDateTime'].toString();
        }
      }
      
      // Format coordinates for better readability if available
      String formattedCoordinates = coordinates ?? 'Unknown';
      
      // 5. Create and send the SMS
      print('Step 5: Creating and sending SMS...');
      // Create a more detailed timestamped message with database details
      final alertMessage = 'RAGGING ALERT (ID: $alertId):\n'
          'Time: $alertDateTime\n'
          'Student: $studentName\n'
          'ID: $studentId\n'
          'Location: $locationInfo\n'
          'Coordinates: $formattedCoordinates\n\n'
          'Please respond immediately.';
          
      // Store the message details for debugging and for the UI
      result['messageDetails'] = {
        'timestamp': alertDateTime,
        'studentName': studentName,
        'studentId': studentId,
        'location': locationInfo,
        'coordinates': formattedCoordinates,
        'fullMessage': alertMessage,
      };
      
      // Set these values for result dialog
      result['timestamp'] = alertDateTime;
      result['location'] = formattedCoordinates;
      result['studentName'] = studentName;
      result['studentId'] = studentId;
      
      // Send SMS to primary emergency contact
      final emergencyNumber = AppConfig.primaryEmergencyContact;
      print('Sending SMS to $emergencyNumber with message: $alertMessage');
      bool smsResult = false;
      
      try {
        // Add a timeout to SMS sending to avoid blocking indefinitely
        Future<bool> smsFuture = _twilioService.sendSMS(
          to: emergencyNumber,
          messageBody: alertMessage,
        );
        
        // Apply timeout to the SMS sending future
        smsResult = await smsFuture.timeout(
          Duration(seconds: 15), // Timeout after 15 seconds
          onTimeout: () {
            print('SMS sending timed out after 15 seconds');
            result['timeoutIssue'] = true;
            return false; // Consider the SMS sending as failed
          },
        );
        
        result['steps']['smsSent'] = smsResult;
          
        if (!smsResult) {
          print('Failed to send SMS');
          result['smsError'] = 'Failed to send SMS';
          
          // Try fallback method if SMS sending failed
          try {
            print('Attempting fallback alert mechanism...');
            // This would be a different way to alert - maybe local notification
            // For now just log the attempt
            result['fallbackAttempted'] = true;
          } catch (fallbackError) {
            print('Fallback mechanism also failed: $fallbackError');
            result['fallbackError'] = '$fallbackError';
          }
        } else {
          print('SMS sent successfully');
        }
      } catch (e) {
        print('Error sending SMS: $e');
        result['smsError'] = '$e';
        
        // Try to determine if it's a network issue
        if ('$e'.toLowerCase().contains('network') ||
            '$e'.toLowerCase().contains('connection') ||
            '$e'.toLowerCase().contains('internet')) {
          result['networkIssue'] = true;
        }
      }
      
      // Final success means SMS was sent - that's the most critical part
      result['success'] = smsResult;
      result['alertSent'] = smsResult;
      result['databaseUpdated'] = databaseUpdated;
      
      return result;
    } catch (e) {
      print('Error in sendEmergencyAlert: $e');
      return {
        'success': false,
        'error': '$e',
        'steps': {
          'locationAccess': false,
          'userInfoRetrieved': false,
          'databaseUpdated': false,
          'smsSent': false
        }
      };
    }
  }
}

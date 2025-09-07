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
      // No alert ID available in this method as it's used before database creation
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
    String? alertId,
  }) {
    final String locationInfo = coordinates != null 
        ? '$location' 
        : location;
    
    // Create Google Maps link with coordinates if available
    String mapsLink = '';
    if (coordinates != null) {
      final List<String> parts = coordinates.split(',');
      if (parts.length == 2) {
        mapsLink = 'https://www.google.com/maps?q=${parts[0]},${parts[1]}';
      }
    }
    
    String alertIdInfo = alertId != null ? ' (Alert ID: $alertId)' : '';
    
    return 'RAGGING ALERT$alertIdInfo:\n$studentName (ID: $studentId) has reported a ragging incident at $locationInfo.\n\nView Location: $mapsLink\n\nPlease respond immediately.';
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
      
      // We'll still get the user information for fallback purposes
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
      
      // IMPORTANT: 3. Create alert in database FIRST, before preparing SMS
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
        // Print entire alert record for debugging
        print('ALERT RECORD FROM DATABASE:');
        alertRecord.forEach((key, value) {
          print('  $key: $value');
        });
        
        // Override with database information if available
        if (alertRecord['studentName'] != null && alertRecord['studentName'].toString().isNotEmpty) {
          studentName = alertRecord['studentName'].toString();
          print('Using student name from database: $studentName');
        }
        
        // CRITICAL: Extract the studentId from the RAG alert database
        print('Checking for studentId in database record');
        if (alertRecord['studentId'] != null) {
          studentId = alertRecord['studentId'].toString();
          print('Found studentId in database record: $studentId');
        } else if (alertRecord['data'] != null && alertRecord['data']['studentId'] != null) {
          // Try nested data structure
          studentId = alertRecord['data']['studentId'].toString();
          print('Found studentId in nested data: $studentId');
        } else {
          print('WARNING: studentId not found in expected locations');
          print('Attempting to find studentId in any field of the record...');
          
          bool found = false;
          alertRecord.forEach((key, value) {
            if (key.toLowerCase().contains('student') && key.toLowerCase().contains('id')) {
              studentId = value.toString();
              print('Found potential studentId in field $key: $studentId');
              found = true;
            }
          });
          
          if (!found) {
            print('Could not find studentId in any field of the record');
          }
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
      }        // Format coordinates for better readability if available
      String formattedCoordinates = coordinates ?? 'Unknown';
      
      // Make one more attempt to get the most recent alert if we don't have a good record
      if (!databaseUpdated || alertRecord.isEmpty || alertId == 'Unknown') {
        print('Attempting to fetch the most recent RAG alert from database...');
        try {
          // Fetch the latest alert
          final latestAlertResult = await _ragAlertController.getLatestRagAlert();
          
          if (latestAlertResult['success'] && latestAlertResult['data'] != null) {
            print('Successfully retrieved the latest RAG alert');
            
            // Update our record with the latest data
            Map<String, dynamic> latestAlert = latestAlertResult['data'];
            
            // Print the entire latest alert record
            print('LATEST ALERT FROM DATABASE:');
            latestAlert.forEach((key, value) {
              print('  $key: $value');
            });
            
            // Update alertRecord with this latest data
            alertRecord = latestAlert;
            
            // Update our alert ID and date/time
            if (latestAlert['alertId'] != null) {
              alertId = latestAlert['alertId'].toString();
              print('Updated Alert ID from latest record: $alertId');
            }
            
            if (latestAlert['alertDateTime'] != null) {
              alertDateTime = latestAlert['alertDateTime'].toString();
              print('Updated Date/Time from latest record: $alertDateTime');
            }
            
            // Update studentId if available
            if (latestAlert['studentId'] != null) {
              studentId = latestAlert['studentId'].toString();
              print('Updated Student ID from latest record: $studentId');
            }
            
            // Update coordinates if available
            if (latestAlert['latitude'] != null && latestAlert['longitude'] != null) {
              coordinates = '${latestAlert['latitude']},${latestAlert['longitude']}';
              formattedCoordinates = coordinates;
              print('Updated Coordinates from latest record: $coordinates');
            }
            
            databaseUpdated = true;
          } else {
            print('Failed to retrieve latest alert: ${latestAlertResult['error'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print('Error retrieving latest alert: $e');
        }
      }
      
      // 5. Create and send the SMS
      print('Step 5: Creating and sending SMS with latest database information...');
        // Add extra debug output to verify final student ID
      print('FINAL VALUES FOR SMS:');
      print('  Alert ID: $alertId');
      print('  Date/Time: $alertDateTime');
      print('  Student ID: $studentId');
      print('  Location: $locationInfo');
      print('  Coordinates: $formattedCoordinates');
        // Use our improved _createAlertMessage method which includes Google Maps link
      final alertMessage = _createAlertMessage(
        studentName: studentName,
        studentId: studentId,
        location: locationInfo,
        coordinates: formattedCoordinates,
        alertId: alertId,
      );
      
      print('  Final SMS Message: \n$alertMessage');
          
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

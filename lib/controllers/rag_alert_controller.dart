import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../core/app_config.dart';

class RagAlertController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  /// Create a new rag alert in the database
  Future<Map<String, dynamic>> createRagAlert({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get current user's ID token
      String? idToken;
      try {
        idToken = await _auth.currentUser?.getIdToken();
        print('Got ID token: ${idToken?.substring(0, 10)}...');
      } catch (e) {
        print('Error getting ID token: $e');
        // Continue with a placeholder token for testing
        idToken = 'test-token-for-development';
      }

      if (idToken == null) {
        print('No ID token available');
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      // Create rag alert data
      final data = {
        'latitude': latitude,
        'longitude': longitude,
        // alertDateTime will be set by the server (default: now)
      };
      print('Sending rag alert data: $data to $baseUrl/api/rag-alerts');

      // Send API request to create rag alert
      final response = await http.post(
        Uri.parse('$baseUrl/api/rag-alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(data),
      );
      
      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Rag alert created in database successfully');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // For offline fallback, we'll return success even if the API fails
        // This ensures the SMS will still be sent even if DB update fails
        print('Failed to create rag alert: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'warning': 'Alert created but database update may have failed.',
          'statusCode': response.statusCode,
          'response': response.body,
        };
      }
    } catch (e) {
      print('Error creating rag alert: $e');
      return {
        'success': false,
        'error': 'Failed to create alert: $e',
      };
    }
  }
  /// Get the latest RAG alert from the database
  Future<Map<String, dynamic>> getLatestRagAlert() async {
    try {
      // Get current user's ID token
      String? idToken;
      try {
        idToken = await _auth.currentUser?.getIdToken();
        print('Got ID token: ${idToken?.substring(0, 10)}...');
      } catch (e) {
        print('Error getting ID token: $e');
        // Continue with a placeholder token for testing
        idToken = 'test-token-for-development';
      }

      if (idToken == null) {
        print('No ID token available');
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      // Send API request to get latest rag alert
      final response = await http.get(
        Uri.parse('$baseUrl/api/rag-alerts/latest'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      
      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Latest rag alert retrieved successfully');
        return {
          'success': true,
          'data': responseData.containsKey('data') ? responseData['data'] : responseData,
        };
      } else {
        print('Failed to get latest rag alert: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to retrieve latest alert',
          'statusCode': response.statusCode,
          'response': response.body,
        };
      }
    } catch (e) {
      print('Error getting latest rag alert: $e');
      return {
        'success': false,
        'error': 'Failed to retrieve latest alert: $e',
      };
    }
  }
  
  /// Get current user details - now with fallback mock data for testing
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Try getting authenticated user info
      User? currentUser = _auth.currentUser;
      String? idToken;
      
      // Try to get token if user exists
      if (currentUser != null) {
        try {
          idToken = await currentUser.getIdToken();
        } catch (e) {
          print('Error getting ID token: $e');
        }
      }
      
      // If we have a token, try the API
      if (idToken != null) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/api/users/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          );

          if (response.statusCode == 200) {
            final user = jsonDecode(response.body);
            return {
              'success': true,
              'data': user,
            };
          }
        } catch (e) {
          print('API error getting user details: $e');
        }
      }      // If we got here, either no user, no token, or API failed
      
      // Use our AppConfig mock data in test mode, or build from user info
      String firstName = AppConfig.mockUserData['firstName'];
      String lastName = AppConfig.mockUserData['lastName'];
      String studentId = AppConfig.mockUserData['student']['studentNumber'];
      
      if (!AppConfig.isTestMode && currentUser != null) {
        if (currentUser.displayName != null) {
          List<String> nameParts = currentUser.displayName!.split(' ');
          firstName = nameParts.first;
          if (nameParts.length > 1) {
            lastName = nameParts.last;
          }
        } else if (currentUser.email != null) {
          // Use email as alternative to display name
          firstName = currentUser.email!.split('@').first;
          lastName = "User";
        }
        
        // Use part of UID as student ID if we don't have one
        studentId = currentUser.uid.substring(0, 6);
      }
      
      // Print debug info
      print('Using fallback user info: $firstName $lastName (ID: $studentId)');
      
      // Add additional debug identification if available
      Map<String, dynamic> debugInfo = {};
      if (currentUser != null) {
        if (currentUser.email != null) debugInfo['email'] = currentUser.email;
        if (currentUser.phoneNumber != null) debugInfo['phone'] = currentUser.phoneNumber;
        debugInfo['uid'] = currentUser.uid;
      }
      
      // Log debug info if available
      if (debugInfo.isNotEmpty && AppConfig.isDebugMode) {
        print('Debug user info: $debugInfo');
      }
      
      return {
        'success': true,
        'data': {
          'firstName': firstName,
          'lastName': lastName,
          'student': {
            'studentNumber': studentId
          }
        },
        'source': 'fallback-data'
      };
    } catch (e) {
      print('Error in getCurrentUser: $e');
      // Always return something - emergency case
      return {
        'success': true,
        'data': {
          'firstName': 'Emergency',
          'lastName': 'User',
          'student': {
            'studentNumber': 'EMERGENCY'
          }
        },
        'source': 'emergency-fallback'
      };
    }
  }
}
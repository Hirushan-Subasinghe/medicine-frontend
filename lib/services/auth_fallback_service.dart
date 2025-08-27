import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Development authentication service that bypasses Firebase when needed
class AuthFallbackService {
  
  /// Test login using backend directly (for development when Firebase fails)
  static Future<Map<String, dynamic>?> testLogin(String email) async {
    print("🧪 Attempting fallback login for: $email");
    
    // Try multiple possible backend URLs
    final List<String> possibleUrls = [
      "http://10.0.2.2:5002/api/auth/loginWithToken",
      "http://192.168.56.1:5002/api/auth/loginWithToken", 
      "http://192.168.183.1:5002/api/auth/loginWithToken",
      "http://localhost:5002/api/auth/loginWithToken",
    ];
    
    for (String url in possibleUrls) {
      try {
        print("🔍 Trying URL: $url");
        
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"idToken": "test-token"}),
        ).timeout(Duration(seconds: 5));

        print("📡 Response from $url: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          print("📡 Response body: ${response.body}");
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['user'] != null) {
            print("✅ Connected successfully via: $url");
            return data['user'];
          }
        }
      } catch (e) {
        print("❌ Failed to connect to $url: $e");
        continue; // Try next URL
      }
    }
    
    print("❌ All backend connection attempts failed");
    return null;
  }
  
  /// Test signup using backend directly (for development when Firebase fails)
  static Future<bool> testSignup({
    required String firstName,
    required String lastName,
    required String email,
    required String studentNumber,
    required String academicYear,
    required String faculty,
    required String department,
    required String phoneNo,
  }) async {
    try {
      print("🧪 Attempting fallback signup for: $email");
      
      // Use test token for signup
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idToken": "test-token-signup",
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "studentNumber": studentNumber,
          "studentAcademicYear": academicYear,
          "faculty": faculty,
          "department": department,
          "phoneNo": phoneNo,
        }),
      );

      print("📡 Fallback signup status: ${response.statusCode}");
      print("📡 Fallback signup response: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("❌ Fallback signup error: $e");
      return false;
    }
  }

  /// Check if we should use fallback authentication
  static bool shouldUseFallback() {
    // For now, always return true in development to bypass Firebase issues
    // You can make this more sophisticated later
    return true;
  }
}

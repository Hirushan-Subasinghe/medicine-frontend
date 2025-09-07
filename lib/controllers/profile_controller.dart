import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../core/constants.dart';

class ProfileController {
  // Fetch the complete user profile (including student data) using the idToken
  Future<UserModel?> fetchUserProfile(String idToken) async {
    try {
      print("🔍 Fetching user profile with token: ${idToken.substring(0, 20)}...");
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/loginWithToken"), // Using consistent endpoint with auth_controller.dart
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      print("📡 Profile fetch status code: ${response.statusCode}");
      print("📦 Profile fetch raw response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          // Debug the structure of the response
          final decodedData = jsonDecode(response.body);
          print("🔍 Response structure: ${decodedData.runtimeType}");
          print("🔍 Full response data: $decodedData");
          
          if (decodedData is Map && decodedData.containsKey('user')) {
            final userData = decodedData['user'];
            print("👤 User data type: ${userData.runtimeType}");
            print("👤 Full user data: $userData");
            
            // Check if student data exists
            if (userData is Map && userData.containsKey('student')) {
              print("🎓 Student data found: ${userData['student']}");
            } else {
              print("❌ No student data in response");
            }
            
            // Handle the case where user data is a List
            if (userData is List) {
              print("⚠️ Warning: User data is a List, expected Map. Attempting to use first item.");
              if (userData.isNotEmpty && userData[0] is Map) {
                // Convert to Map<String, dynamic> explicitly
                final Map<String, dynamic> userDataMap = Map<String, dynamic>.from(userData[0] as Map);
                return UserModel.fromJson(userDataMap);
              } else {
                print("❌ Cannot process List user data: $userData");
                return null;
              }
            } else if (userData is Map) {
              // Normal case - user data is a Map - convert to Map<String, dynamic> explicitly
              final Map<String, dynamic> userDataMap = Map<String, dynamic>.from(userData as Map);
              return UserModel.fromJson(userDataMap);
            } else {
              print("❌ Unknown user data type: ${userData.runtimeType}");
              return null;
            }
          } else {
            print("❌ Missing 'user' field in response: $decodedData");
            return null;
          }
        } catch (e) {
          print("❌ Error parsing user data: $e");
          print(StackTrace.current);
          return null;
        }
      } else {
        print("❌ Failed to fetch profile: ${response.statusCode}");
        print("❌ Error response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching user profile: $e");
      print(StackTrace.current);
      return null;
    }
  }

  // Update the user's profile image URL (example method)
  Future<bool> updateProfileImage(String idToken, String profileImgUrl) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/auth/update-profile-image"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idToken": idToken,
        "profileImgUrl": profileImgUrl,
      }),
    );
    return response.statusCode == 200;
  }

  // Update the user's profile information
  Future<bool> updateProfile(String idToken, String firstName, String lastName, String phoneNo) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/update-profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idToken": idToken,
          "firstName": firstName,
          "lastName": lastName,
          "phoneNo": phoneNo,
        }),
      );
      
      if (response.statusCode == 200) {
        print("Profile updated successfully");
        return true;
      } else {
        print("Failed to update profile: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception updating profile: $e");
      return false;
    }
  }
}

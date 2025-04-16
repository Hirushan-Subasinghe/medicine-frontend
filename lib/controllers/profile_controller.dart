import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../core/constants.dart';

class ProfileController {
  // Fetch the complete user profile (including student data) using the idToken
  Future<UserModel?> fetchUserProfile(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['user'];
      return UserModel.fromJson(data);
    }
    return null;
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
}

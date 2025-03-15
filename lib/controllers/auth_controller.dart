import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> login(String email, String password) async {
    try {
      // Firebase authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get Firebase ID Token
      String? idToken = await userCredential.user?.getIdToken();

      // Send token to backend for verification
      final response = await http.post(
          Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyAHOOMTWLjC7N_K2j0Nffwmf2s7J7Sfy-M"),
          headers: {
            "Content-Type": "application/json",

          },
          body: jsonEncode({"email": email, "password": password, "returnSecureToken": true})
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return "success"; // ✅ Successful login
      } else {
        return "Login failed: ${response.body}";
      }
    } catch (e) {
      return "Error logging in: $e";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

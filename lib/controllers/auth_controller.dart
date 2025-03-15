import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io'; // Import for handling network errors
import 'package:http/http.dart' as http;

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 **User Login Function**
  Future<String?> login(String email, String password) async {
    try {
      // ✅ Check if fields are empty before making API request
      if (email.isEmpty && password.isEmpty) {
        return "Email and password fields cannot be empty.";
      } else if (email.isEmpty) {
        return "The email field cannot be empty.";
      } else if (password.isEmpty) {
        return "The password field cannot be empty.";
      }

      print("🚀 Attempting Firebase login...");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Firebase login successful! User: ${userCredential.user?.uid}");

      String? idToken = await userCredential.user?.getIdToken();
      print("🔑 Firebase ID Token: $idToken");

      // ✅ Sending request to Firebase Auth REST API
      final response = await http.post(
        Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyAHOOMTWLjC7N_K2j0Nffwmf2s7J7Sfy-M"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
          "returnSecureToken": true
        }),
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📜 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("🎉 Login Successful!");
        return "success";
      } else {
        // ✅ Extract Firebase error message properly
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String? errorCode = responseBody["error"]?["message"];

        print("❌ Login failed: $errorCode");

        return getFirebaseErrorMessage(errorCode ?? "UNKNOWN_ERROR");
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      return getFirebaseErrorMessage(e.code);
    } on SocketException {
      print("❌ No internet connection.");
      return "No internet connection. Please check your network and try again.";
    } catch (e) {
      print("❌ General Error: $e");
      return "An unexpected error occurred. Please try again later.";
    }
  }

  /// 🔥 Converts Firebase error codes into user-friendly messages
  String getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case "INVALID_LOGIN_CREDENTIALS":
      case "wrong-password":
        return "The password you entered is incorrect. Please try again.";
      case "EMAIL_NOT_FOUND":
      case "user-not-found":
        return "No account found with this email. Please register first.";
      case "invalid-email":
        return "Invalid email format. Please enter a valid email address.";
      case "too-many-requests":
        return "Too many failed login attempts. Try again later.";
      case "NETWORK_REQUEST_FAILED":
        return "Network error. Please check your connection.";
      case "WEAK_PASSWORD":
        return "Password is too weak. Please use a stronger password.";
      case "EMAIL_EXISTS":
        return "This email is already in use. Try logging in instead.";
      case "OPERATION_NOT_ALLOWED":
        return "This operation is not allowed. Please contact support.";
      default:
        return "Login failed. Please check your credentials and try again.";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    print("✅ User logged out successfully.");
  }
}

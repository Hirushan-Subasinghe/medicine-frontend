import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 User Login Function — Firebase login + backend token verification
  Future<String?> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Email and password fields cannot be empty.";
      }

      print("🚀 Attempting Firebase login...");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Firebase login successful! User: ${userCredential.user?.uid}");

      String? idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        return "Failed to get Firebase ID token.";
      }

      print("🔑 Firebase ID Token: $idToken");

      final response = await http.post(
        Uri.parse("http://172.19.44.233:5000/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      print("📡 Backend Response Status: ${response.statusCode}");
      print("📜 Backend Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("🎉 Backend Login Verified!");
        return "success";
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return "Login failed: ${body['error'] ?? 'Unknown backend error'}";
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

  /// 🔹 User Signup Function — Firebase + MySQL + UID
  Future<String?> signup(
      String firstName,
      String lastName,
      String email,
      String password,
      String studentNumber,
      String level,
      String department,
      String faculty,
      String phoneNo,
      ) async {
    try {
      if (firstName.isEmpty ||
          lastName.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          studentNumber.isEmpty ||
          level.isEmpty ||
          department.isEmpty ||
          faculty.isEmpty ||
          phoneNo.isEmpty) {
        return "All fields are required.";
      }

      print("🚀 Creating Firebase user...");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print("❌ Firebase user creation failed!");
        return "Firebase signup failed. Please try again.";
      }

      print("✅ Firebase user created: ${userCredential.user?.uid}");

      // 🔑 Get Firebase ID Token (REQUIRED for backend)
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        print("❌ Failed to get Firebase ID token.");
        return "Failed to get Firebase ID token.";
      }

      // 📡 Send user data + ID token to backend
      final response = await http.post(
        Uri.parse("http://172.19.44.233:5000/api/auth/signup"), // Replace with your local IP or domain
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idToken": idToken,
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "studentNumber": studentNumber,
          "level": level,
          "department": department,
          "faculty": faculty,
          "phoneNo": phoneNo,
        }),
      );

      print("📜 Response Status: ${response.statusCode}");
      print("📜 Response Body: ${response.body}");

      if (response.statusCode == 201) {
        print("🎉 Signup Successful!");
        return "success";
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return "Signup failed: ${body['error'] ?? 'Unknown error'}";
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      return getFirebaseErrorMessage(e.code);
    } on SocketException {
      print("❌ No internet connection.");
      return "No internet connection. Please check your network.";
    } catch (e) {
      print("❌ General Error: $e");
      return "An unexpected error occurred.";
    }
  }


  /// 🔥 Firebase Error Code Translator
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

  /// 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
    print("✅ User logged out successfully.");
  }
}

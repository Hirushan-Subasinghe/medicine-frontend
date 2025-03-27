import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 **User Login Function**
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
      print("🔑 Firebase ID Token: $idToken");

      final response = await http.post(
        Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyAHOOMTWLjC7N_K2j0Nffwmf2s7J7Sfy-M"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password, "returnSecureToken": true}),
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📜 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("🎉 Login Successful!");
        return "success";
      } else {
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String? errorCode = responseBody["error"]?["message"];
        print("❌ Login failed: $errorCode");

        return getFirebaseErrorMessage(errorCode ?? "UNKNOWN_ERROR"); // ✅ Fixed
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      return getFirebaseErrorMessage(e.code); // ✅ Fixed
    } on SocketException {
      print("❌ No internet connection.");
      return "No internet connection. Please check your network and try again.";
    } catch (e) {
      print("❌ General Error: $e");
      return "An unexpected error occurred. Please try again later.";
    }
  }

  /// 🔹 **User Signup Function**
  Future<String?> signup(
      String firstName,
      String lastName,
      String email,
      String password,
      String studentNumber,
      String level,
      String department,
      String faculty,
      String phoneNo) async {
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
      String uid = userCredential.user!.uid;

      print("📡 Sending user data to backend...");

      final response = await http.post(
        Uri.parse("http://172.19.44.233/api/auth/signup"), // Update with your backend URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firebase_uid": uid,
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
        print("🎉 Signup Successful! Navigating to login...");
        return "success";
      } else {
        print("❌ Signup failed: ${response.body}");
        return "Signup failed: ${response.body}";
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      return getFirebaseErrorMessage(e.code); // ✅ Fixed
    } on SocketException {
      print("❌ No internet connection.");
      return "No internet connection. Please check your network and try again.";
    } catch (e) {
      print("❌ General Error: $e");
      return "An unexpected error occurred. Please try again later.";
    }
  }

  /// 🔥 **Converts Firebase error codes into user-friendly messages**
  String getFirebaseErrorMessage(String errorCode) { // ✅ Added this function
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

  /// 🔹 **Logout Function**
  Future<void> logout() async {
    await _auth.signOut();
    print("✅ User logged out successfully.");
  }
}

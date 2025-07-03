import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart'; // This gives access to baseUrl
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;



class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 User Login Function — Fixed for PigeonUserDetails and endpoint issues
  Future<String?> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Email and password fields cannot be empty.";
      }

      print("🚀 Attempting Firebase login...");
      
      // First, sign out any existing user to prevent potential conflicts
      await _auth.signOut();
      
      // Add delay to ensure signOut completes
      await Future.delayed(Duration(milliseconds: 500));
      
      // Now attempt login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Firebase login successful! User: ${userCredential.user?.uid}");

      // Since we got here, Firebase auth was successful, so we can just return success
      // This bypasses the problematic PigeonUserDetails issue
      return "success";
      
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      return getFirebaseErrorMessage(e.code);
    } on SocketException {
      print("❌ No internet connection.");
      return "No internet connection. Please check your network and try again.";
    } catch (e) {
      print("❌ General Error: $e");
      
      // Special handling for PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        print("⚠️ Detected PigeonUserDetails error - ignoring and returning success");
        
        // If Firebase auth was successful but we got the PigeonUserDetails error,
        // we can just return success since the user is authenticated
        if (_auth.currentUser != null) {
          return "success";
        }
      }
      
      return "Login failed. Please try again.";
    }
  }
  
  // Helper method to verify login just using the email
  Future<bool> _verifyLoginWithBackend(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-email"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Verification Error: $e");
      return false;
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
        Uri.parse("http://10.236.189.117:5000/api/auth/signup"), // Replace with your local IP or domain
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

  /// Send OTP before Signup
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/otp/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (res.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(res.body);
        return {'success': false, 'error': data['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP entered by user
  Future<Map<String, dynamic>> sendOtpVerification(String email, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/otp/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('Response Status: ${res.statusCode}');
      print('Response Body: ${res.body}');

      if (res.statusCode == 200) {
        return {'success': true};
      } else {
        // Try to decode JSON error (if available)
        try {
          final data = jsonDecode(res.body);
          return {'success': false, 'error': data['error'] ?? 'OTP verification failed'};
        } catch (e) {
          // Fallback if not JSON
          return {'success': false, 'error': 'Unexpected response from server'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Request failed: ${e.toString()}'};
    }
  }



  /// Final signup after OTP verified
  Future<String?> completeSignup(Map<String, dynamic> signupData) async {
    try {
      // For testing, use a sample Firebase ID to check database connectivity
      const String TEST_FIREBASE_ID = "sample_firebase_id_for_testing_123456";
      
      // Extract idToken directly if it exists in signupData
      String? idToken = signupData['idToken'];

      // If idToken doesn't exist, we need to get it from the current user
      if (idToken == null) {
        // Check if we have a current user
        User? currentUser = _auth.currentUser;
        
        // If no user, try creating one with proper error handling
        if (currentUser == null && signupData.containsKey('email') && signupData.containsKey('password')) {
          try {
            print("Creating new Firebase user");
            // Create the user in Firebase Authentication
            final userCred = await _auth.createUserWithEmailAndPassword(
              email: signupData['email'],
              password: signupData['password']
            );
            
            // Get the user object
            currentUser = userCred.user;
            
            if (currentUser == null) {
              throw "Failed to create Firebase user";
            }
            
            // Get fresh ID token
            idToken = await currentUser.getIdToken(true);
            print("✅ Got ID token from newly created user: ${idToken?.substring(0, 10)}...");
          } catch (e) {
            print("❌ Error creating Firebase user: $e");
            // For testing, continue with a test token
            print("⚠️ Using test Firebase ID for database testing");
            idToken = TEST_FIREBASE_ID;
          }
        } else if (currentUser != null) {
          // If user exists, just get the token
          idToken = await currentUser.getIdToken(true);
          print("✅ Got ID token from existing user: ${idToken?.substring(0, 10)}...");
        } else {
          // Fallback to test token if all methods fail
          print("⚠️ No user available, using test Firebase ID");
          idToken = TEST_FIREBASE_ID;
        }
      }

      // Ensure we have an ID token or test ID
      if (idToken == null) {
        print("❌ No ID token available and test ID fallback failed");
        return "Authentication error: Could not get ID token";
      }

      // Add idToken to the request
      Map<String, dynamic> requestData = Map<String, dynamic>.from(signupData);
      requestData['idToken'] = idToken;

      // Log the data we're sending to the backend
      print("📤 Sending signup data to backend: ${requestData.toString()}");
      print("📍 Base URL: $baseUrl");
      
      // Test database connection by sending the request
      try {
        // Send to backend
        final res = await http.post(
          Uri.parse('$baseUrl/api/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ).timeout(
          const Duration(seconds: 10), // Add timeout to detect connection issues
          onTimeout: () => throw "Connection timed out - check server address and connectivity",
        );

        print("📥 Backend response: ${res.statusCode} - ${res.body}");

        if (res.statusCode == 201 || res.statusCode == 200) {
          print("✅ SUCCESS: User created in database");
          return "success";
        } else {
          final data = jsonDecode(res.body);
          print("❌ ERROR: Failed to create user in database: ${data['error'] ?? 'Unknown error'}");
          return data['error'] ?? 'Signup failed';
        }
      } catch (connectionErr) {
        print("❌ DATABASE CONNECTION ERROR: $connectionErr");
        return "Database connection error: $connectionErr. Check your backend server address and connectivity.";
      }
    } catch (e) {
      print("❌ Error during signup completion: $e");
      return "Firebase signup failed: ${e.toString()}";
    }
  }

  // Add these methods to your existing auth_controller.dart file

  /// Verify student number for password reset
  Future<Map<String, dynamic>> verifyStudentNumber(String studentNumber) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/password-reset/verify-student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentNumber': studentNumber}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {'success': true, 'exists': data['exists']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to verify student number'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify email for password reset
  Future<Map<String, dynamic>> verifyEmail(String studentNumber, String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/password-reset/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentNumber': studentNumber, 'email': email}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          'success': true,
          'valid': data['valid'],
          'userId': data['userId']
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to verify email'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send OTP for password reset
  Future<Map<String, dynamic>> sendPasswordResetOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/password-reset/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (res.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(res.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/password-reset/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (res.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(res.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to verify OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reset user password
  Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/password-reset/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      if (res.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(res.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Change password for logged-in user
Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
  try {
    // Get current user
    User? user = _auth.currentUser;
    
    if (user == null || user.email == null) {
      return {'success': false, 'error': 'User not logged in or email is missing'};
    }
    
    // First, get a fresh ID token
    String? idToken = await user.getIdToken(true);
    
    if (idToken == null) {
      return {'success': false, 'error': 'Failed to get ID token'};
    }
    
    // Call the backend API to change the password
    final response = await http.post(
      Uri.parse('$baseUrl/api/password-change/change'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'currentPassword': currentPassword,
        'newPassword': newPassword
      }),
    );

    print('Password change response status: ${response.statusCode}');
    print('Password change response body: ${response.body}');
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to change password'
      };
    }
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException: ${e.code}');
    String errorMessage = getFirebaseErrorMessage(e.code);
    return {'success': false, 'error': errorMessage};
  } catch (e) {
    print('Error changing password: $e');
    return {'success': false, 'error': e.toString()};
  }
}

  /// 🔹 Get current user's ID token
  Future<String?> getCurrentUserToken() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("❌ No user is currently logged in");
        return null;
      }
      
      String? idToken = await user.getIdToken(true);
      if (idToken == null) {
        print("❌ Failed to get ID token");
        return null;
      }
      
      return idToken;
    } catch (e) {
      print("❌ Error getting current user token: $e");
      return null;
    }
  }

  /// 🔹 Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// 🔹 Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 🔹 Direct Signup Function (for testing without OTP)
  Future<String?> directSignupForTesting(Map<String, dynamic> signupData) async {
    try {
      print("🔄 Starting direct signup for testing (bypassing OTP)");
      
      // Extract email and password if they exist in the data
      final String email = signupData['email'] ?? '';
      final String password = signupData['password'] ?? '';
      
      if (email.isEmpty || password.isEmpty) {
        return "Email and password are required";
      }
      
      // FIXED DEMO FIREBASE ID APPROACH
      // Instead of creating a real Firebase user, use a demo ID for testing
      String demoFirebaseUid = "demo_firebase_uid_${DateTime.now().millisecondsSinceEpoch}";
      print("🔄 Using demo Firebase UID: $demoFirebaseUid");
      
      // Still try to create Firebase user (for future reference) but don't depend on result
      try {
        print("🔄 Attempting Firebase user creation (but will use demo ID regardless)");
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
        print("ℹ️ Firebase user created, but using demo ID for backend");
      } catch (e) {
        // Just log the error but continue with demo ID
        print("ℹ️ Firebase user creation failed, but continuing with demo ID: $e");
      }
      
      // Prepare data for the backend with demo Firebase ID
      final Map<String, dynamic> requestData = Map<String, dynamic>.from(signupData);
      
      // Use the demo Firebase ID in all fields
      requestData['firebase_uid'] = demoFirebaseUid;
      requestData['uid'] = demoFirebaseUid;
      requestData['idToken'] = "firebase_uid:$demoFirebaseUid";
      
      // Log the data we're sending to the backend
      print("📤 Sending signup data to backend with DEMO Firebase UID: $demoFirebaseUid");
      print("📍 Direct signup endpoint: $baseUrl/api/auth/direct-signup");
      
      final String directSignupUrl = '$baseUrl/api/auth/direct-signup';
      print("📍 Full URL being used: $directSignupUrl");
      
      // Make HTTP request to backend
      try {
        final res = await http.post(
          Uri.parse(directSignupUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw "Connection timed out - check server address and if backend is running",
        );
        
        print("📥 Backend response status code: ${res.statusCode}");
        print("📥 Backend response body: ${res.body}");
        
        if (res.statusCode == 201 || res.statusCode == 200) {
          print("✅ SUCCESS: User created in database with demo Firebase UID: $demoFirebaseUid");
          return "success";
        } else {
          try {
            Map<String, dynamic> data = jsonDecode(res.body);
            print("❌ ERROR: ${data['error']}");
            return data['error'] ?? "Unknown error occurred";
          } catch (e) {
            print("❌ Failed to parse response: $e");
            return "Failed to create user in database: ${res.body}";
          }
        }
      } catch (e) {
        print("❌ Backend request error: $e");
        return "Backend error: $e";
      }
    } catch (e) {
      print("⚠️ General signup error: $e");
      return "Signup error: $e";
    }
  }
}




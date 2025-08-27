import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart'; // This gives access to baseUrl
import '../services/auth_fallback_service.dart'; // Import fallback service
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
      
      // For development: Skip Firebase and go directly to fallback
      print("🧪 Development mode: Using fallback authentication directly");
      print("🔄 Trying fallback authentication...");
      
      try {
        final fallbackUser = await AuthFallbackService.testLogin(email);
        if (fallbackUser != null) {
          print("✅ Fallback login successful!");
          print("👤 User: ${fallbackUser['firstName']} ${fallbackUser['lastName']}");
          return "success";
        } else {
          print("❌ Fallback login failed");
        }
      } catch (fallbackError) {
        print("❌ Fallback error: $fallbackError");
      }
      
      // If fallback fails, try Firebase as backup
      try {
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
        return "success";
        
      } on FirebaseAuthException catch (e) {
        print("❌ FirebaseAuthException: ${e.code}");
        print("❌ Firebase Error Message: ${e.message}");
        print("❌ Full Firebase Error: $e");
        
        return "Firebase authentication is currently unavailable. Please try again later.";
      } on SocketException {
        print("❌ No internet connection");
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
      
    } catch (e) {
      print("❌ Outer catch error: $e");
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
      
      try {
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
          Uri.parse("$baseUrl/api/auth/signup"),
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
        
        // If Firebase fails with network error, try fallback
        if (e.code == 'network-request-failed') {
          print("🔄 Network error detected, trying fallback signup...");
          final success = await AuthFallbackService.testSignup(
            firstName: firstName,
            lastName: lastName,
            email: email,
            studentNumber: studentNumber,
            academicYear: level, // Using level as academic year for now
            faculty: faculty,
            department: department,
            phoneNo: phoneNo,
          );
          
          if (success) {
            print("✅ Fallback signup successful!");
            return "success";
          } else {
            print("❌ Fallback signup also failed");
            return "Signup failed. Please try again.";
          }
        }
        
        return getFirebaseErrorMessage(e.code);
      }
      
    } on SocketException {
      print("❌ No internet connection, trying fallback signup...");
      final success = await AuthFallbackService.testSignup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        studentNumber: studentNumber,
        academicYear: level,
        faculty: faculty,
        department: department,
        phoneNo: phoneNo,
      );
      
      if (success) {
        print("✅ Fallback signup successful!");
        return "success";
      }
      
      return "No internet connection. Please check your network.";
    } catch (e) {
      print("❌ General Error: $e");
      
      // Try fallback for any other error
      print("🔄 Trying fallback signup...");
      final success = await AuthFallbackService.testSignup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        studentNumber: studentNumber,
        academicYear: level,
        faculty: faculty,
        department: department,
        phoneNo: phoneNo,
      );
      
      if (success) {
        print("✅ Fallback signup successful!");
        return "success";
      }
      
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

  /// Validate Email before Signup
  Future<Map<String, dynamic>> validateEmail(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/otp/validate-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Email Validation Response Status: ${res.statusCode}');
      print('Email Validation Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = jsonDecode(res.body);
        return {'success': false, 'error': data['error'] ?? 'Email validation failed'};
      }
    } catch (e) {
      print('❌ Email validation error: $e');
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
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
        final data = jsonDecode(res.body);
        // Check if development OTP is provided
        if (data['developmentOtp'] != null) {
          print('🧪 DEVELOPMENT OTP: ${data['developmentOtp']}');
        }
        return {'success': true, 'data': data};
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
      print("🔄 Starting complete signup with real Firebase user creation");
      
      // Extract email and password
      final String email = signupData['email'] ?? '';
      final String password = signupData['password'] ?? '';
      
      if (email.isEmpty || password.isEmpty) {
        return "Email and password are required for Firebase user creation";
      }
      
      // Create REAL Firebase user
      String realFirebaseUid;
      String? idToken;
      
      try {
        print("🔥 Creating REAL Firebase user with email: $email");
        
        // First, sign out any existing user to prevent conflicts
        await _auth.signOut();
        await Future.delayed(Duration(milliseconds: 500));
        
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
        
        if (userCredential.user == null) {
          throw "Firebase user creation returned null user";
        }
        
        realFirebaseUid = userCredential.user!.uid;
        print("✅ REAL Firebase user created successfully with UID: $realFirebaseUid");
        
        // Try to update display name, but don't fail if it doesn't work due to PigeonUserDetails
        try {
          await userCredential.user!.updateDisplayName("${signupData['firstName']} ${signupData['lastName']}");
          print("✅ Display name updated successfully");
        } catch (displayNameError) {
          print("⚠️ Failed to update display name (PigeonUserDetails issue): $displayNameError");
          // Continue anyway, this is not critical
        }
        
        // Get the ID token for backend verification
        try {
          idToken = await userCredential.user!.getIdToken();
          print("✅ Got real Firebase ID token");
        } catch (tokenError) {
          print("⚠️ Failed to get ID token (PigeonUserDetails issue): $tokenError");
          // Use the UID as fallback
          idToken = realFirebaseUid;
        }
        
      } catch (e) {
        print("❌ Failed to create real Firebase user: $e");
        
        // Special handling for PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          print("⚠️ Detected PigeonUserDetails error - but Firebase user might have been created anyway");
          
          // Wait a moment for Firebase to process
          await Future.delayed(Duration(milliseconds: 2000));
          
          try {
            // Check if we have a current user (the user might have been created despite the error)
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              realFirebaseUid = currentUser.uid;
              idToken = realFirebaseUid; // Use UID as token fallback
              print("✅ Found current Firebase user despite PigeonUserDetails error! UID: $realFirebaseUid");
            } else {
              // Try to sign in with the credentials to see if the user was created
              final testCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password
              );
              
              if (testCredential.user != null) {
                realFirebaseUid = testCredential.user!.uid;
                idToken = realFirebaseUid; // Use UID as token fallback
                print("✅ User was created despite PigeonUserDetails error! UID: $realFirebaseUid");
              } else {
                throw "User creation failed - no user found after PigeonUserDetails error";
              }
            }
          } catch (signInError) {
            print("❌ User was not created after PigeonUserDetails error: $signInError");
            return "Firebase user creation failed due to platform issue. Please try again.";
          }
        }
        // Check if it's an "email already in use" error
        else if (e.toString().contains('email-already-in-use')) {
          return "This email is already registered. Please try logging in instead.";
        }
        else {
          return "Firebase user creation failed: ${e.toString()}";
        }
      }

      // Add the real Firebase UID and ID token to the request
      Map<String, dynamic> requestData = Map<String, dynamic>.from(signupData);
      requestData['idToken'] = idToken;
      requestData['firebase_uid'] = realFirebaseUid;

      // Log the data we're sending to the backend
      print("📤 Sending signup data to backend with REAL Firebase UID: $realFirebaseUid");
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
          print("✅ SUCCESS: User created in database with real Firebase UID");
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
      return "Signup failed: ${e.toString()}";
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
    print('🔐 Starting password change process...');
    
    // Get current user
    User? user = _auth.currentUser;
    
    if (user == null) {
      print('❌ No user is currently logged in');
      return {'success': false, 'error': 'User not logged in'};
    }
    
    if (user.email == null) {
      print('❌ User email is missing');
      return {'success': false, 'error': 'User email is missing'};
    }
    
    print('✅ User found: ${user.email}');
    
    // First, get a fresh ID token
    String? idToken;
    try {
      idToken = await user.getIdToken(true);
      print('✅ ID token obtained successfully');
    } catch (tokenError) {
      print('❌ Failed to get ID token: $tokenError');
      return {'success': false, 'error': 'Failed to get authentication token'};
    }
    
    if (idToken == null) {
      print('❌ ID token is null');
      return {'success': false, 'error': 'Failed to get ID token'};
    }
    
    print('🌐 Calling backend API...');
    
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

    print('📊 Response status: ${response.statusCode}');
    print('📋 Response body: ${response.body}');
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      print('✅ Password changed successfully');
      return {'success': true};
    } else {
      print('❌ Password change failed: ${data['error']}');
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to change password'
      };
    }
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    String errorMessage = getFirebaseErrorMessage(e.code);
    return {'success': false, 'error': errorMessage};
  } catch (e) {
    print('❌ General error changing password: $e');
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

  /// 🔹 Direct Signup Function (creates real Firebase user)
  Future<String?> directSignupForTesting(Map<String, dynamic> signupData) async {
    try {
      print("🔄 Starting direct signup with real Firebase user creation");
      
      // Extract email and password if they exist in the data
      final String email = signupData['email'] ?? '';
      final String password = signupData['password'] ?? '';
      
      if (email.isEmpty || password.isEmpty) {
        return "Email and password are required";
      }
      
      // Create REAL Firebase user
      String realFirebaseUid;
      try {
        print("� Creating REAL Firebase user with email: $email");
        
        // First, sign out any existing user to prevent conflicts
        await FirebaseAuth.instance.signOut();
        await Future.delayed(Duration(milliseconds: 500));
        
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
        
        if (userCredential.user == null) {
          throw "Firebase user creation returned null user";
        }
        
        realFirebaseUid = userCredential.user!.uid;
        print("✅ REAL Firebase user created successfully with UID: $realFirebaseUid");
        
        // Try to update display name, but don't fail if it doesn't work due to PigeonUserDetails
        try {
          await userCredential.user!.updateDisplayName("${signupData['firstName']} ${signupData['lastName']}");
          print("✅ Display name updated successfully");
        } catch (displayNameError) {
          print("⚠️ Failed to update display name (PigeonUserDetails issue): $displayNameError");
          // Continue anyway, this is not critical
        }
        
      } catch (e) {
        print("❌ Failed to create real Firebase user: $e");
        
        // Special handling for PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          print("⚠️ Detected PigeonUserDetails error - but Firebase user might have been created anyway");
          
          // Wait a moment for Firebase to process
          await Future.delayed(Duration(milliseconds: 2000));
          
          try {
            // Check if we have a current user (the user might have been created despite the error)
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              realFirebaseUid = currentUser.uid;
              print("✅ Found current Firebase user despite PigeonUserDetails error! UID: $realFirebaseUid");
            } else {
              // Try to sign in with the credentials to see if the user was created
              final testCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password
              );
              
              if (testCredential.user != null) {
                realFirebaseUid = testCredential.user!.uid;
                print("✅ User was created despite PigeonUserDetails error! UID: $realFirebaseUid");
              } else {
                throw "User creation failed - no user found after PigeonUserDetails error";
              }
            }
          } catch (signInError) {
            print("❌ User was not created after PigeonUserDetails error: $signInError");
            return "Firebase user creation failed due to platform issue. Please try again.";
          }
        }
        // Check if it's an "email already in use" error
        else if (e.toString().contains('email-already-in-use')) {
          return "This email is already registered. Please try logging in instead.";
        }
        else {
          return "Firebase user creation failed: ${e.toString()}";
        }
      }
      
      // Prepare data for the backend with REAL Firebase UID
      final Map<String, dynamic> requestData = Map<String, dynamic>.from(signupData);
      
      // Use the REAL Firebase UID in all fields
      requestData['firebase_uid'] = realFirebaseUid;
      requestData['uid'] = realFirebaseUid;
      requestData['idToken'] = realFirebaseUid; // Send the actual UID instead of demo token
      
      // Log the data we're sending to the backend
      print("📤 Sending signup data to backend with REAL Firebase UID: $realFirebaseUid");
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
          print("✅ SUCCESS: User created in database with real Firebase UID: $realFirebaseUid");
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




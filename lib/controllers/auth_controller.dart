// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class AuthController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Future<void> login(String email, String password) async {
//     try {
//       // Firebase authentication
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Get Firebase ID Token
//       String? idToken = await userCredential.user?.getIdToken();
//
//       // Send token to backend for verification
//       final response = await http.post(
//         Uri.parse("http://your-backend-url.com/api/auth/login"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $idToken",
//         },
//         body: jsonEncode({"email": email}),
//       );
//
//       if (response.statusCode == 200) {
//         print("✅ Login successful: ${response.body}");
//       } else {
//         print("❌ Login failed: ${response.body}");
//       }
//     } catch (e) {
//       print("❌ Error logging in: $e");
//     }
//   }
// }

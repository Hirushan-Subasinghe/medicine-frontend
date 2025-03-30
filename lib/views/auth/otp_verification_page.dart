import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import 'login_page.dart';
import '../../core/constants.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic> signupData;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.signupData,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController otpController = TextEditingController();
  final AuthController authController = AuthController();

  bool isLoading = false;
  String errorMessage = "";

  void verifyOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final response = await authController.sendOtpVerification(
      widget.email,
      otpController.text.trim(),
    );

    if (!response['success']) {
      setState(() {
        isLoading = false;
        errorMessage = response['error'] ?? "Invalid OTP.";
      });
      return;
    }

    // OTP verified. Now create Firebase user and complete signup
    final email = widget.signupData['email'];
    final password = widget.signupData['password'];

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to get Firebase ID token.";
        });
        return;
      }

      final updatedSignupData = Map<String, dynamic>.from(widget.signupData);
      updatedSignupData['idToken'] = idToken;

      final result = await authController.completeSignup(updatedSignupData);

      setState(() {
        isLoading = false;
      });

      if (result == "success") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Your account has been created."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          errorMessage = result ?? "Signup failed.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Firebase signup failed: ${e.toString()}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter the 6-digit OTP sent to',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            Text(
              widget.email,
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "OTP",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify", style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

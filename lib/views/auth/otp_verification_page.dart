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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🔹 Heading + Subheading
              Center(
                child: Column(
                  children: [
                    const Text("Verify your email", style: AppTextStyles.subheading),
                    const SizedBox(height: 8),
                    Text("OTP Verification", style: AppTextStyles.heading),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Hero Image
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Image.asset(
                    'assets/images/login-hero.png',
                    height: 300,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Text(
                      'Enter the 6-digit OTP sent to your university email:',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: AppTextStyles.subheading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 🔹 OTP Input
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter OTP",
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Error Message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // 🔹 Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButtons.primaryButton(
                        text: isLoading ? "Verifying..." : "Verify",
                        onPressed: isLoading ? () {} : verifyOtp,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔁 Resend OTP
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                        final res = await authController.sendOtp(widget.email);
                        if (!res['success']) {
                          setState(() {
                            errorMessage = res['error'] ?? "Failed to resend OTP.";
                          });
                        } else {
                          setState(() {
                            errorMessage = "OTP resent to your email.";
                          });
                        }
                      },
                      child: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

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
  bool isInfoMessage = false; // To differentiate between info and error messages

  @override
  void initState() {
    super.initState();
    // Show message that OTP has been sent
    setState(() {
      errorMessage = "OTP has been sent to ${widget.email}. Please check your email and enter the code below.";
      isInfoMessage = true;
    });
  }

  // Updated testing function that creates real Firebase users - REMOVED
  // This was bypassing OTP verification for testing, now we use proper OTP flow
  /*
  Future<void> _directSignupForTesting() async {
    setState(() {
      isLoading = true;
      errorMessage = "Creating your account with real Firebase authentication...";
    });
    
    try {
      // Call the updated direct signup method that creates real Firebase users
      final result = await authController.directSignupForTesting(widget.signupData);
      
      setState(() {
        isLoading = false;
      });
      
      if (result == "success") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Your account has been created successfully with real Firebase authentication."),
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
        // Display the error message
        setState(() {
          errorMessage = "Signup failed: $result";
        });
      }
    } catch (e) {
      print("⚠️ Error in direct signup: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Signup failed: ${e.toString()}";
      });
      // Clean up by signing out if there was an error
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }
  */

  // Original OTP verification function (updated to create real Firebase users)
  void verifyOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
      isInfoMessage = false;
    });

    final response = await authController.sendOtpVerification(
      widget.email,
      otpController.text.trim(),
    );

    if (!response['success']) {
      setState(() {
        isLoading = false;
        errorMessage = response['error'] ?? "Invalid OTP.";
        isInfoMessage = false;
      });
      return;
    }

    // OTP verified. Now create Firebase user and complete signup
    try {
      // First sign out any existing user to avoid conflicts
      await FirebaseAuth.instance.signOut();
      
      // Call backend to complete signup with real Firebase user creation
      final result = await authController.completeSignup(widget.signupData);
      
      setState(() {
        isLoading = false;
      });

      if (result == "success") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Your account has been created successfully."),
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
          isInfoMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Signup failed: ${e.toString()}";
        isInfoMessage = false;
      });
      // Clean up by signing out if there was an error
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

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

                    // 🔹 Error/Info Message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: isInfoMessage ? AppColors.primaryColor : Colors.red, 
                            fontSize: 14
                          ),
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
                            isInfoMessage = false;
                          });
                        } else {
                          setState(() {
                            errorMessage = "OTP resent to your email.";
                            isInfoMessage = true;
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

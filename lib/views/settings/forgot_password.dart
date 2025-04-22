import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();
  final TextEditingController _studentNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final List<TextEditingController> otpControllers =
  List.generate(4, (index) => TextEditingController());

  final AuthController _authController = AuthController();

  int _currentPage = 0;
  final int _totalPages = 6; // Added a new page for password reset
  bool _isLoading = false;
  String _errorMessage = "";
  String _otpEmail = "";

  @override
  void dispose() {
    _pageController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No internet connection. Please check and try again.";
      });
      _showErrorSnackBar(_errorMessage);
      return Future.error(_errorMessage);
    }
    return Future.value();
  }

  // Verify student number
  Future<void> _verifyStudentNumber() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _checkConnectivity();

      final studentNumber = _studentNumberController.text.trim();
      if (studentNumber.isEmpty) {
        throw "Student number cannot be empty";
      }

      final result = await _authController.verifyStudentNumber(studentNumber);

      if (result['success'] && result['exists']) {
        _nextPage();
      } else {
        throw result['error'] ?? "Student number not found";
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify email
  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _checkConnectivity();

      final studentNumber = _studentNumberController.text.trim();
      final email = _emailController.text.trim();

      if (email.isEmpty) {
        throw "Email cannot be empty";
      }

      if (!email.endsWith("@stu.kln.ac.lk")) {
        throw "Only university emails (@stu.kln.ac.lk) are allowed";
      }

      final result = await _authController.verifyEmail(studentNumber, email);

      if (result['success'] && result['valid']) {
        // Store email for OTP verification
        _otpEmail = email;

        // Send OTP
        final otpResult = await _authController.sendPasswordResetOtp(email);

        if (otpResult['success']) {
          _showSuccessSnackBar("OTP sent to your email");
          _nextPage();
        } else {
          throw otpResult['error'] ?? "Failed to send OTP";
        }
      } else {
        throw result['error'] ?? "Email verification failed";
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify OTP
  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _checkConnectivity();

      final otp = otpControllers.map((controller) => controller.text).join();

      if (otp.length != 4) {
        throw "Please enter the complete 4-digit OTP";
      }

      final result = await _authController.verifyPasswordResetOtp(_otpEmail, otp);

      if (result['success']) {
        _nextPage();
      } else {
        _pageController.animateToPage(
          4, // Show failure page
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        throw result['error'] ?? "OTP verification failed";
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset password
  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _checkConnectivity();

      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword.isEmpty) {
        throw "New password cannot be empty";
      }

      if (newPassword.length < 6) {
        throw "Password should be at least 6 characters";
      }

      if (newPassword != confirmPassword) {
        throw "Passwords do not match";
      }

      final result = await _authController.resetPassword(_otpEmail, newPassword);

      if (result['success']) {
        _pageController.animateToPage(
          5, // Success page
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        throw result['error'] ?? "Password reset failed";
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _checkConnectivity();

      final result = await _authController.sendPasswordResetOtp(_otpEmail);

      if (result['success']) {
        _showSuccessSnackBar("OTP resent to your email");
      } else {
        throw result['error'] ?? "Failed to resend OTP";
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _retryVerification() {
    // Go back to OTP page
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reset Password",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildStudentNumberPage(),
                _buildEmailPage(),
                _buildOtpVerificationPage(),
                _buildNewPasswordPage(),
                _buildFailurePage(),
                _buildSuccessPage(),
              ],
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages - 2, (index) {
          // We subtract 2 because we don't want to show dots for the failure and success pages
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? AppColors.primaryColor
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentNumberPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Enter your student number",
            style: AppTextStyles.heading.copyWith(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We need your student ID to verify your account",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _studentNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Student Number",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyStudentNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "Next",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Verify your email",
            style: AppTextStyles.heading.copyWith(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your registered email to receive verification code",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email Address",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "Send Verification Code",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Enter verification code",
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a 4-digit code to your email",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 60,
                child: TextFormField(
                  controller: otpControllers[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 3) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code? ",
                style: AppTextStyles.body,
              ),
              TextButton(
                onPressed: _isLoading ? null : _resendOTP,
                child: Text(
                  "Resend",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "Verify",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Set New Password",
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new password for your account",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "New Password",
              hintText: "At least 6 characters",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              "Reset Password",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            "Password Reset Successful!",
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Your password has been reset successfully. You can now login with your new password.",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Return to Login",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailurePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            "Verification Failed",
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "We couldn't verify your code. Please check that you entered the correct code or try requesting a new one.",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _retryVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Try Again",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
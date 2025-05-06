import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicine/views/auth/signup_page.dart';
import '../../core/constants.dart';
import '../main_menu/main_menu.dart';
import '../../controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = AuthController();

  bool isLoading = false;
  String errorMessage = "";

  Future<void> loginUser() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    if (emailController.text.trim().isEmpty && passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Email and password fields cannot be empty.";
        isLoading = false;
      });
      return;
    }

    if (emailController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "The email field cannot be empty.";
        isLoading = false;
      });
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "The password field cannot be empty.";
        isLoading = false;
      });
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage = "No internet connection. Please check and try again.";
        isLoading = false;
      });
      return;
    }

    String? result = await authController.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainMenu()),
      );
    } else {
      setState(() {
        errorMessage = result ?? "Login failed. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Sign in to continue",
                      style: AppTextStyles.subheading,
                    ),
                    SizedBox(height: 8),
                    Text("Student Login", style: AppTextStyles.heading),
                  ],
                ),
              ),
              SizedBox(height: 30),

              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 24),
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
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Student email",
                        prefixIcon: Icon(Icons.email, color: AppColors.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
                        suffixIcon: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot?",
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: AppButtons.primaryButton(
                        text: isLoading ? "Logging in..." : "Login",
                        onPressed: isLoading
                            ? () {} // ✅ Empty function to prevent null error
                            : () {
                          loginUser();
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // ✅ "Don't have an account? Register" Text
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentSignupPage()),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.body,
                          children: [
                            TextSpan(
                              text: "Register",
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
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

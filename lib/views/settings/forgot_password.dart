import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Center(
        child: Text(
          "Forgot Password Page",
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}

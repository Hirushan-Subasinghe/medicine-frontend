import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Center(
        child: Text(
          "Change Password Page",
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}

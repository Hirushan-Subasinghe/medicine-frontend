import 'package:flutter/material.dart';
import '../../core/constants.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Center(
        child: Text(
          "Edit Profile Page",
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}

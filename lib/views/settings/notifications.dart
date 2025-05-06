import 'package:flutter/material.dart';
import '../../core/constants.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Center(
        child: Text(
          "Notifications Page",
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}

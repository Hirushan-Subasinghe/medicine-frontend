import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'core/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freshers Connect',
      debugShowCheckedModeBanner: false, // Removes debug banner
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.primaryColor,
        ),
        textTheme: TextTheme(
          bodyLarge: AppTextStyles.body,
          titleLarge: AppTextStyles.heading,
        ),
      ),
      home: LoginPage(), // Set LoginPage as the first screen
    );
  }
}

import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'core/constants.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

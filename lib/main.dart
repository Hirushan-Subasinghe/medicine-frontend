import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';  // Import Provider package
import 'controllers/map_controller.dart'; // Import your custom MapController
import 'views/auth/login_page.dart';
import 'views/main_menu/main_menu.dart';
import 'views/test/twilio_test_page.dart'; // Import Twilio test page
import 'views/rag_alert/rag_alert_test_page.dart'; // Import Rag Alert test page

// Import both constant files
import 'core/constants.dart' as dev_constants;
import 'core/constants_prod.dart' as prod_constants;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapController()),
        // You can add more providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {    return MaterialApp(
      title: 'Freshers Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kReleaseMode ? prod_constants.AppColors.primaryColor : dev_constants.AppColors.primaryColor,
        scaffoldBackgroundColor: kReleaseMode ? prod_constants.AppColors.backgroundColor : dev_constants.AppColors.backgroundColor,
        colorScheme: ColorScheme.light(
          primary: kReleaseMode ? prod_constants.AppColors.primaryColor : dev_constants.AppColors.primaryColor,
          secondary: kReleaseMode ? prod_constants.AppColors.primaryColor : dev_constants.AppColors.primaryColor,
        ),
        textTheme: TextTheme(
          bodyLarge: kReleaseMode ? prod_constants.AppTextStyles.body : dev_constants.AppTextStyles.body,
          titleLarge: kReleaseMode ? prod_constants.AppTextStyles.heading : dev_constants.AppTextStyles.heading,
        ),
      ),
      routes: {
        '/twilio_test': (context) => const TwilioTestPage(),
        '/rag_alert_test': (context) => const RagAlertTestPage(),
      },
      home: AuthChecker(), // Check if user is logged in or not
    );
  }
}

// Automatically navigate based on authentication state
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return MainMenu(); // Navigate to main menu if logged in
        }
        return LoginPage(); // Show login page otherwise
      },
    );
  }
}

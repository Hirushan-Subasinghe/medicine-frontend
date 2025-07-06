import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';  // Import Provider package
import 'package:overlay_support/overlay_support.dart'; // Import overlay support
import 'controllers/map_controller.dart'; // Import your custom MapController
import 'services/notification_manager.dart'; // Import NotificationManager
import 'services/user_state_service.dart'; // Import UserStateService
import 'services/navigation_service.dart'; // Import NavigationService
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
        ChangeNotifierProvider(create: (_) => NotificationManager()),
        // You can add more providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey, // Use NavigationService navigator key
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
      ),
    );
  }
}

// Automatically navigate based on authentication state
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isInitialized = false;

  Future<void> _initializeServices() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 AuthChecker: Initializing services...');
      
      // Initialize user state service first
      final userStateService = UserStateService();
      await userStateService.initializeUser();
      
      // Initialize notification manager with user data
      final notificationManager = Provider.of<NotificationManager>(context, listen: false);
      await notificationManager.initialize();
      
      _isInitialized = true;
      print('✅ AuthChecker: Services initialized successfully');
    } catch (e) {
      print('❌ AuthChecker: Error initializing services - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          // User is authenticated, initialize services and show main menu
          _initializeServices();
          return MainMenu(); // Navigate to main menu if logged in
        } else {
          // User is not authenticated, clear initialization flag
          _isInitialized = false;
          return LoginPage(); // Show login page otherwise
        }
      },
    );
  }
}

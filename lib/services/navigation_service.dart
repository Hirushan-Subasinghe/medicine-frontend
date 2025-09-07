import 'package:flutter/material.dart';
import '../views/main_menu/main_menu.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to notification tab in main menu
  static void navigateToNotifications() {
    try {
      print('🎯 NavigationService: Navigating to notifications tab');
      MainMenu.navigateToNotificationTab();
    } catch (e) {
      print('❌ NavigationService: Error navigating to notifications - $e');
    }
  }

  /// Navigate to a specific route
  static void navigateToRoute(String route, {Object? arguments}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  /// Go back
  static void goBack() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

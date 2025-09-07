import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_tab.dart';
import 'map_tab.dart';
import 'notification_tab.dart';
import 'profile_tab.dart';
import '../../core/constants.dart';
import '../../services/notification_manager.dart';

class MainMenu extends StatefulWidget {
  // Static instance to allow external control
  static _MainMenuState? _currentInstance;

  @override
  _MainMenuState createState() => _MainMenuState();

  /// Static method to navigate to notification tab from anywhere in the app
  static void navigateToNotificationTab() {
    _currentInstance?.switchToNotificationTab();
  }
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;

  // List of pages for each tab
  final List<Widget> _pages = [
    HomeTab(),
    MapTab(),
    NotificationTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Set the current instance for static access
    MainMenu._currentInstance = this;
    
    // Initialize NotificationManager when MainMenu loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationManager = Provider.of<NotificationManager>(context, listen: false);
      notificationManager.initialize();
    });
  }

  @override
  void dispose() {
    // Clear the current instance
    MainMenu._currentInstance = null;
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Method to switch to notification tab (index 2)
  void switchToNotificationTab() {
    if (mounted) {
      setState(() {
        _selectedIndex = 2; // Notification tab is at index 2
      });
      print('🎯 MainMenu: Switched to notification tab');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected tab
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // Removes ripple effect
          highlightColor: Colors.transparent, // Removes highlight effect
        ),
        child: Consumer<NotificationManager>(
          builder: (context, notificationManager, child) {
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppColors.primaryColor, // Highlighted icon color
              unselectedItemColor: Colors.grey, // Unselected icon color
              enableFeedback: false, // Disables hover effect on tap
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      Icon(Icons.notifications),
                      if (notificationManager.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notificationManager.unreadCount > 99 ? '99+' : notificationManager.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: "Notifications",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../controllers/profile_controller.dart';

class UserStateService {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  UserModel? _currentUser;
  final ProfileController _profileController = ProfileController();

  UserModel? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?.userId;

  /// Initialize user data on app start
  Future<void> initializeUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        print('🔄 UserStateService: Initializing user data...');
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          _currentUser = await _profileController.fetchUserProfile(idToken);
          
          if (_currentUser != null) {
            print('✅ UserStateService: User initialized - ID: ${_currentUser!.userId}, Name: ${_currentUser!.firstName} ${_currentUser!.lastName}');
          } else {
            print('❌ UserStateService: Failed to load user profile');
          }
        }
      } else {
        print('❌ UserStateService: No Firebase user found');
      }
    } catch (e) {
      print('❌ UserStateService: Error initializing user - $e');
    }
  }

  /// Update current user data
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    print('👤 UserStateService: User updated - ID: ${user.userId}, Name: ${user.firstName} ${user.lastName}');
  }

  /// Clear user data on logout
  void clearUser() {
    _currentUser = null;
    print('🧹 UserStateService: User data cleared');
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          final refreshedUser = await _profileController.fetchUserProfile(idToken);
          if (refreshedUser != null) {
            _currentUser = refreshedUser;
            print('🔄 UserStateService: User data refreshed');
          }
        }
      }
    } catch (e) {
      print('❌ UserStateService: Error refreshing user - $e');
    }
  }
}

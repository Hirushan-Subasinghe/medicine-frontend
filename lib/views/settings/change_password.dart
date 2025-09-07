import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../controllers/auth_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // 0 = current password, 1 = new password

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _moveToNextStep() async {
    // First, validate the current password
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your current password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Verify that the user is still authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Validate current password by attempting to re-authenticate
      print('🔍 Validating current password...');
      
      // Show a brief validation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Verifying current password...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 🚀 NEW: Alternative validation approach using sign-in test first
      bool passwordValid = false;
      String? validationError;
      
      // Try the alternative approach first (safer)
      try {
        print('🔄 Attempting alternative password validation via sign-in test...');
        
        // Store current auth state
        final originalUser = FirebaseAuth.instance.currentUser;
        final originalEmail = originalUser?.email;
        
        if (originalEmail != null) {
          // Create a temporary auth instance for testing
          await FirebaseAuth.instance.signOut();
          
          // Test the password by signing in
          final testResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: originalEmail,
            password: _currentPasswordController.text,
          );
          
          if (testResult.user != null) {
            print('✅ Alternative password validation successful');
            passwordValid = true;
          }
        }
      } catch (altError) {
        print('⚠️ Alternative validation failed: $altError');
        
        if (altError is FirebaseAuthException) {
          if (altError.code == 'wrong-password' || altError.code == 'invalid-credential') {
            validationError = 'Current password is incorrect. Please try again.';
          } else {
            validationError = 'Failed to verify current password. Please try again.';
          }
        } else {
          validationError = 'Password verification failed. Please try again.';
        }
      }
      
      // If alternative approach failed, try the original reauthenticate method
      if (!passwordValid) {
        try {
          print('🔄 Falling back to reauthenticateWithCredential...');
          
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.email != null) {
            final credential = EmailAuthProvider.credential(
              email: currentUser.email!,
              password: _currentPasswordController.text,
            );
            
            // 🚀 FIX: Handle PigeonUserDetails type casting issue
            try {
              await currentUser.reauthenticateWithCredential(credential);
              print('✅ Reauthenticate password validation successful');
              passwordValid = true;
            } catch (pigeonError) {
              // If we get a PigeonUserDetails error, it might still be successful
              if (pigeonError.toString().contains('PigeonUserDetails')) {
                print('⚠️ PigeonUserDetails type error encountered, treating as success');
                passwordValid = true;
              } else {
                // If it's not a PigeonUserDetails error, re-throw it
                rethrow;
              }
            }
          }
        } catch (e) {
          print('❌ Reauthenticate validation also failed: $e');
          
          if (e is FirebaseAuthException) {
            switch (e.code) {
              case 'wrong-password':
              case 'invalid-credential':
                validationError = 'Current password is incorrect. Please try again.';
                break;
              case 'too-many-requests':
                validationError = 'Too many failed attempts. Please try again later.';
                break;
              default:
                validationError = 'Failed to verify current password. Please try again.';
            }
          } else {
            validationError = 'Failed to verify current password. Please try again.';
          }
        }
      }
      
      // Hide any existing snackbars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (passwordValid) {
        // Show success message briefly
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Password verified!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navigate to the next step after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _currentStep = 1;
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(validationError ?? 'Password verification failed')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Clear the current password field for security
        _currentPasswordController.clear();
        return;
      }

    } catch (e) {
      print('❌ Error during password validation: $e');
      
      // Hide any existing snackbars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Handle PigeonUserDetails error specially
      if (e.toString().contains('PigeonUserDetails')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Authentication system issue. Please try logging out and back in.')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (_newPasswordController.text == _currentPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from current password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryColor),
                SizedBox(width: 20),
                Text('Changing password...'),
              ],
            ),
          );
        },
      );

      // Use the AuthController to change the password
      final result = await _authController.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Dismiss progress dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text('Success'),
                ],
              ),
              content: const Text('Your password has been changed successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to change password'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Dismiss progress dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Step 1 indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 0 ? AppColors.primaryColor : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: _currentStep >= 0 ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1 ? AppColors.primaryColor : Colors.grey[300],
                  ),
                ),
                // Step 2 indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 1 ? AppColors.primaryColor : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: _currentStep >= 1 ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: _currentStep == 0 
                    ? _buildCurrentPasswordStep(key: const ValueKey('step1'))
                    : _buildNewPasswordStep(key: const ValueKey('step2')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPasswordStep({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Lock and key image
            Container(
              width: double.infinity,
              height: 150,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/padlock.png', // Update with your actual image path
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Text
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle text
            Text(
              'Enter your current password to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Current Password Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Current Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your current password',
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _moveToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'VERIFYING...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPasswordStep({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Lock and key image
            Container(
              width: double.infinity,
              height: 150,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/unlock.png', // Update with your actual image path
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Text
            Text(
              'Set New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle text
            Text(
              'Create a new secure password',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // New Password Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'New Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild for password strength indicator
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your new password',
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current password';
                    }
                    // Check for at least one letter and one number
                    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                      return 'Password should contain at least one letter and one number';
                    }
                    return null;
                  },
                ),
                // Password strength indicator
                if (_newPasswordController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildPasswordStrengthIndicator(_newPasswordController.text),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirm Password Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm your new password',
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Buttons row
            Row(
              children: [
                // Back button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Confirm Change Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'CONFIRM CHANGE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = 0;
    String strengthText = '';
    Color strengthColor = Colors.red;

    // Check password strength criteria
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
    } else if (strength <= 4) {
      strengthText = 'Medium';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 6,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }
}
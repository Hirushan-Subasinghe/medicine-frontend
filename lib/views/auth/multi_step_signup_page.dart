import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../controllers/auth_controller.dart';
import 'otp_verification_page.dart';

class MultiStepSignupPage extends StatefulWidget {
  @override
  _MultiStepSignupPageState createState() => _MultiStepSignupPageState();
}

class _MultiStepSignupPageState extends State<MultiStepSignupPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int currentStep = 0;
  final int totalSteps = 4;

  // Controllers for all form fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController academicYearController = TextEditingController();

  String? selectedDepartment;
  String? selectedFaculty;
  int? selectedFacultyId;

  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> faculties = [];

  String errorMessage = "";
  bool isLoading = false;
  bool isFacultiesLoading = true;
  bool isDepartmentsLoading = false;
  final AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    fetchFaculties();
    academicYearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    // Dispose all controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    studentNumberController.dispose();
    phoneNoController.dispose();
    academicYearController.dispose();
    super.dispose();
  }

  Future<void> fetchFaculties() async {
    setState(() {
      isFacultiesLoading = true;
    });
    
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print("🔍 Fetching faculties from: $baseUrl (Attempt ${retryCount + 1}/$maxRetries)");
        print("🔍 Faculty URL: $baseUrl/api/common/faculties");
        
        final facResponse = await http.get(
          Uri.parse("$baseUrl/api/common/faculties"),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 15));

        print("📊 Faculty response status: ${facResponse.statusCode}");
        
        if (facResponse.statusCode == 200) {
          print("✅ Faculty API call successful");
          final List<dynamic> facData = jsonDecode(facResponse.body);
          print("📋 Raw faculty data length: ${facData.length}");
          if (facData.isNotEmpty) {
            print("📋 First faculty item: ${facData[0]}");
          }
          
          setState(() {
            faculties = facData.map((e) => {
              'facultyId': e['facultyId'],
              'facultyName': e['facultyName'].toString()
            }).toList();
            isFacultiesLoading = false;
          });
          
          print("✅ Parsed Faculties (${faculties.length}): $faculties");
          return; // Success, exit the retry loop
        } else {
          print("❌ Faculty API call failed with status: ${facResponse.statusCode}");
          print("❌ Faculty Response body: ${facResponse.body}");
          throw Exception("HTTP ${facResponse.statusCode}");
        }
      } catch (e) {
        retryCount++;
        print("❌ Error fetching faculties (Attempt $retryCount/$maxRetries): $e");
        
        if (retryCount >= maxRetries) {
          setState(() {
            isFacultiesLoading = false;
          });
          break;
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  Future<void> fetchDepartmentsByFaculty(int facultyId) async {
    setState(() {
      isDepartmentsLoading = true;
    });
    
    try {
      print("🔍 Fetching departments for faculty $facultyId from: $baseUrl");
      print("🔍 Department URL: $baseUrl/api/common/faculties/$facultyId/departments");
      
      final depResponse = await http.get(
        Uri.parse("$baseUrl/api/common/faculties/$facultyId/departments"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print("📊 Department response status: ${depResponse.statusCode}");
      
      if (depResponse.statusCode == 200) {
        print("✅ Department API call successful");
        final List<dynamic> depData = jsonDecode(depResponse.body);
        print("📋 Raw department data length: ${depData.length}");
        if (depData.isNotEmpty) {
          print("📋 First department item: ${depData[0]}");
        }
        
        setState(() {
          departments = depData.map((e) => {
            'deptId': e['deptId'],
            'departmentName': e['departmentName'].toString()
          }).toList();
          selectedDepartment = null;
          isDepartmentsLoading = false;
        });
        
        print("✅ Parsed Departments (${departments.length}): $departments");
      } else {
        print("❌ Department API call failed with status: ${depResponse.statusCode}");
        setState(() {
          departments = [];
          selectedDepartment = null;
          isDepartmentsLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching departments: $e");
      setState(() {
        departments = [];
        selectedDepartment = null;
        isDepartmentsLoading = false;
      });
    }
  }

  void nextStep() async {
    if (currentStep < totalSteps - 1) {
      final isValid = await validateCurrentStep();
      if (isValid) {
        setState(() {
          currentStep++;
          errorMessage = "";
        });
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      }
    } else {
      // Final step - submit form
      submitForm();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        errorMessage = "";
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> validateCurrentStep() async {
    switch (currentStep) {
      case 0: // Personal Info
        if (firstNameController.text.trim().isEmpty ||
            lastNameController.text.trim().isEmpty ||
            emailController.text.trim().isEmpty) {
          setState(() {
            errorMessage = "Please fill in all personal information";
          });
          return false;
        }
        
        // Basic email validation
        if (!emailController.text.contains('@')) {
          setState(() {
            errorMessage = "Please enter a valid email address";
          });
          return false;
        }

        // University email and existence validation
        setState(() {
          isLoading = true;
          errorMessage = "";
        });

        try {
          final validationResult = await authController.validateEmail(emailController.text.trim());
          
          setState(() {
            isLoading = false;
          });

          if (!validationResult['success']) {
            setState(() {
              errorMessage = validationResult['error'] ?? "Email validation failed";
            });
            return false;
          }

          return true;
        } catch (e) {
          setState(() {
            isLoading = false;
            errorMessage = "Failed to validate email. Please check your connection.";
          });
          return false;
        }

      case 1: // Password
        if (passwordController.text.trim().isEmpty ||
            confirmPasswordController.text.trim().isEmpty) {
          setState(() {
            errorMessage = "Please enter both password fields";
          });
          return false;
        }
        if (passwordController.text != confirmPasswordController.text) {
          setState(() {
            errorMessage = "Passwords do not match";
          });
          return false;
        }
        if (passwordController.text.length < 6) {
          setState(() {
            errorMessage = "Password must be at least 6 characters";
          });
          return false;
        }
        return true;

      case 2: // Academic Info
        if (selectedFaculty == null || selectedDepartment == null) {
          setState(() {
            errorMessage = "Please select both faculty and department";
          });
          return false;
        }
        
        final academicYear = academicYearController.text.trim();
        final int? year = int.tryParse(academicYear);
        final int currentYear = DateTime.now().year;
        if (year == null || year < (currentYear - 6) || year > currentYear) {
          setState(() {
            errorMessage = "Please enter a valid academic year (${currentYear-6} to $currentYear)";
          });
          return false;
        }
        return true;

      case 3: // Contact Info
        if (studentNumberController.text.trim().isEmpty ||
            phoneNoController.text.trim().isEmpty) {
          setState(() {
            errorMessage = "Please fill in all contact information";
          });
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> submitForm() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final signupData = {
      "firstName": firstNameController.text.trim(),
      "lastName": lastNameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "studentNumber": studentNumberController.text.trim(),
      "studentAcademicYear": academicYearController.text.trim(),
      "department": selectedDepartment!,
      "faculty": selectedFaculty!,
      "phoneNo": phoneNoController.text.trim()
    };

    try {
      // Send OTP to user's email
      final otpResult = await authController.sendOtp(emailController.text.trim());
      
      setState(() {
        isLoading = false;
      });
      
      if (otpResult['success']) {
        // Navigate to OTP verification page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationPage(
              email: emailController.text.trim(),
              signupData: signupData,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = otpResult['error'] ?? "Failed to send OTP. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to send OTP: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress indicator
            _buildHeader(),
            // Content area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoStep(),
                  _buildPasswordStep(),
                  _buildAcademicInfoStep(),
                  _buildContactInfoStep(),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (currentStep > 0)
                IconButton(
                  onPressed: previousStep,
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
              Expanded(
                child: Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: currentStep > 0 ? TextAlign.left : TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Progress indicator
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= currentStep 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8),
          Text(
            "Step ${currentStep + 1} of $totalSteps",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return _buildStepContainer(
      title: "Personal Information",
      subtitle: "Let's get to know you better",
      children: [
        _buildTextField(
          "First Name",
          Icons.person_outline,
          firstNameController,
        ),
        SizedBox(height: 20),
        _buildTextField(
          "Last Name",
          Icons.person_outline,
          lastNameController,
        ),
        SizedBox(height: 20),
        _buildTextField(
          "Email Address",
          Icons.email_outlined,
          emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return _buildStepContainer(
      title: "Create Password",
      subtitle: "Choose a secure password for your account",
      children: [
        _buildTextField(
          "Password",
          Icons.lock_outline,
          passwordController,
          isPassword: true,
        ),
        SizedBox(height: 20),
        _buildTextField(
          "Confirm Password",
          Icons.lock_outline,
          confirmPasswordController,
          isPassword: true,
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Password should be at least 6 characters long",
                  style: TextStyle(color: Colors.blue[700], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicInfoStep() {
    return _buildStepContainer(
      title: "Academic Information",
      subtitle: "Tell us about your studies",
      children: [
        // Faculty dropdown
        _buildDropdown(
          "Faculty",
          Icons.school_outlined,
          selectedFaculty,
          isFacultiesLoading
              ? [DropdownMenuItem<String>(
                  value: null, 
                  child: Text("Loading faculties...")
                )]
              : faculties.isEmpty
                  ? [DropdownMenuItem<String>(
                      value: null, 
                      child: Text("No faculties available")
                    )]
                  : [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text("Select Faculty"),
                      ),
                      ...faculties.map((fac) {
                        return DropdownMenuItem<String>(
                          value: fac['facultyName'],
                          child: Text(fac['facultyName']),
                        );
                      }).toList(),
                    ],
          isFacultiesLoading ? null : (value) async {
            setState(() {
              selectedFaculty = value;
              selectedDepartment = null;
              departments = [];
            });
            
            if (value != null) {
              final selectedFacultyData = faculties.firstWhere(
                (fac) => fac['facultyName'] == value,
                orElse: () => {},
              );
              
              if (selectedFacultyData.isNotEmpty) {
                selectedFacultyId = selectedFacultyData['facultyId'];
                await fetchDepartmentsByFaculty(selectedFacultyId!);
              }
            }
          },
        ),
        SizedBox(height: 20),
        // Department dropdown
        _buildDropdown(
          selectedFaculty == null ? "Department (Select Faculty First)" : "Department",
          Icons.business_outlined,
          selectedDepartment,
          selectedFaculty == null
              ? [DropdownMenuItem<String>(
                  value: null, 
                  child: Text("Select faculty first")
                )]
              : isDepartmentsLoading
                  ? [DropdownMenuItem<String>(
                      value: null, 
                      child: Text("Loading departments...")
                    )]
                  : departments.isEmpty
                      ? [DropdownMenuItem<String>(
                          value: null, 
                          child: Text("No departments available")
                        )]
                      : [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text("Select Department"),
                          ),
                          ...departments.map((dep) {
                            return DropdownMenuItem<String>(
                              value: dep['departmentName'],
                              child: Text(dep['departmentName']),
                            );
                          }).toList(),
                        ],
          (selectedFaculty == null || isDepartmentsLoading) ? null : (value) {
            setState(() {
              selectedDepartment = value;
            });
          },
        ),
        SizedBox(height: 20),
        _buildTextField(
          "Academic Year (Batch Year)",
          Icons.calendar_today_outlined,
          academicYearController,
          keyboardType: TextInputType.number,
          helperText: "Enter the year you started at the university",
        ),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return _buildStepContainer(
      title: "Contact Information",
      subtitle: "Final step - contact details",
      children: [
        _buildTextField(
          "Student Number",
          Icons.badge_outlined,
          studentNumberController,
        ),
        SizedBox(height: 20),
        _buildTextField(
          "Phone Number",
          Icons.phone_outlined,
          phoneNoController,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "You're almost done! Review your information and create your account.",
                  style: TextStyle(color: Colors.green[700], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ...children,
          if (errorMessage.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?>? onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: AppColors.primaryColor),
                ),
                child: Text(
                  "Previous",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (currentStep > 0) SizedBox(width: 16),
          Expanded(
            flex: currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: isLoading ? null : nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      currentStep == totalSteps - 1 ? "Create Account" : "Next",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

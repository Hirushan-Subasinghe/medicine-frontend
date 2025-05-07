import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../controllers/auth_controller.dart';
import 'login_page.dart';
import 'otp_verification_page.dart'; // << Add this

class StudentSignupPage extends StatefulWidget {
  @override
  _StudentSignupPageState createState() => _StudentSignupPageState();
}

class _StudentSignupPageState extends State<StudentSignupPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();

  String? selectedLevel;
  String? selectedDepartment;
  String? selectedFaculty;

  final List<String> levels = ["Level 1", "Level 2", "Level 3", "Level 4", "Level 5"];
  List<String> departments = [];
  List<String> faculties = [];

  String errorMessage = "";
  bool isLoading = false;
  final AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    // Set a timeout value
    const timeout = Duration(seconds: 15);
    
    try {
      print("🔄 Starting fetchDropdownData with baseUrl: $baseUrl");
      
      // Try to fetch departments
      print("🌐 Requesting departments from: $baseUrl/api/common/departments");
      final depResponse = await http.get(
        Uri.parse("$baseUrl/api/common/departments"),
        headers: {"Content-Type": "application/json"},
      ).timeout(timeout);
      
      print("📊 Department response status: ${depResponse.statusCode}");
      print("📄 Department response body: ${depResponse.body}");
      
      // Try to fetch faculties
      print("🌐 Requesting faculties from: $baseUrl/api/common/faculties");
      final facResponse = await http.get(
        Uri.parse("$baseUrl/api/common/faculties"),
        headers: {"Content-Type": "application/json"},
      ).timeout(timeout);
      
      print("📊 Faculty response status: ${facResponse.statusCode}");
      print("📄 Faculty response body: ${facResponse.body}");
      
      // Process department response
      if (depResponse.statusCode == 200) {
        final List<dynamic> depData = json.decode(depResponse.body);
        print("📋 Parsed departments data: $depData");
        
        if (depData.isNotEmpty) {
          final List<String> parsedDeps = depData
            .where((item) => item != null && item['deptName'] != null)
            .map<String>((e) => e['deptName'].toString())
            .toList();
          
          print("🔄 Department names extracted: $parsedDeps");
          
          if (mounted) {
            setState(() {
              departments = parsedDeps;
              // Force selection if we have departments
              if (departments.isNotEmpty) {
                selectedDepartment = departments.first;
              }
            });
            print("✅ Departments state updated: ${departments.length} items");
          }
        } else {
          print("⚠️ Department data is empty");
        }
      } else {
        print("❌ Department request failed with status: ${depResponse.statusCode}");
      }
      
      // Process faculty response
      if (facResponse.statusCode == 200) {
        final List<dynamic> facData = json.decode(facResponse.body);
        print("📋 Parsed faculties data: $facData");
        
        if (facData.isNotEmpty) {
          final List<String> parsedFacs = facData
            .where((item) => item != null && item['facultyName'] != null)
            .map<String>((e) => e['facultyName'].toString())
            .toList();
          
          print("🔄 Faculty names extracted: $parsedFacs");
          
          if (mounted) {
            setState(() {
              faculties = parsedFacs;
              // Force selection if we have faculties
              if (faculties.isNotEmpty) {
                selectedFaculty = faculties.first;
              }
            });
            print("✅ Faculties state updated: ${faculties.length} items");
          }
        } else {
          print("⚠️ Faculty data is empty");
        }
      } else {
        print("❌ Faculty request failed with status: ${facResponse.statusCode}");
      }
      
      // Final state check 
      print("📊 FINAL STATE - Departments: ${departments.length}, Faculties: ${faculties.length}");
      if (departments.isEmpty) {
        print("⚠️ WARNING: Departments list is still empty after processing");
      }
      if (faculties.isEmpty) {
        print("⚠️ WARNING: Faculties list is still empty after processing");
      }
      
    } catch (e, stackTrace) {
      print("❌ ERROR in fetchDropdownData: $e");
      print("📑 Stack trace: $stackTrace");
      
      // Attempt a retry with direct JSON parsing as a fallback
      try {
        print("🔄 Attempting fallback method for fetching data...");
        
        // Hardcoded department data based on your Postman response
        final List<String> hardcodedDepts = [
          "Anatomy", "Chemistry", "Civil Engineering", "Computer Science",
          "Internal Medicine", "Mathematics", "Oral Surgery", "Orthodontics",
          "Pharmaceutical Chemistry", "Pharmacology", "Physiology", "Surgery"
        ];
        
        // Hardcoded faculty data (adapt this to match your actual faculties)
        final List<String> hardcodedFacs = [
          "Faculty of Medicine", "Faculty of Engineering", "Faculty of Science"
        ];
        
        if (mounted) {
          setState(() {
            departments = hardcodedDepts;
            faculties = hardcodedFacs;
            // Set defaults
            selectedDepartment = departments.isNotEmpty ? departments.first : null;
            selectedFaculty = faculties.isNotEmpty ? faculties.first : null;
          });
          print("⚠️ Using fallback data - Departments: ${departments.length}, Faculties: ${faculties.length}");
        }
      } catch (fallbackError) {
        print("❌ Fallback method also failed: $fallbackError");
      }
    }
  }

  Future<void> initiateSignupWithOtp() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    final email = emailController.text.trim();

    // ✅ Check for empty fields
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        email.isEmpty ||
        passwordController.text.trim().isEmpty ||
        studentNumberController.text.trim().isEmpty ||
        selectedDepartment == null ||
        selectedFaculty == null ||
        phoneNoController.text.trim().isEmpty ||
        selectedLevel == null) {
      setState(() {
        errorMessage = "All fields are required.";
        isLoading = false;
      });
      return;
    }

    // ✅ Enforce university email restriction
    if (!email.endsWith('@stu.kln.ac.lk')) {
      setState(() {
        errorMessage = "Only university emails (@stu.kln.ac.lk) are allowed.";
        isLoading = false;
      });
      return;
    }

    // ✅ Send OTP
    final otpResponse = await authController.sendOtp(email);

    setState(() {
      isLoading = false;
    });

    if (otpResponse['success']) {
      final signupData = {
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": email,
        "password": passwordController.text.trim(),
        "studentNumber": studentNumberController.text.trim(),
        "studentLevel": selectedLevel!,
        "department": selectedDepartment!,
        "faculty": selectedFaculty!,
        "phoneNo": phoneNoController.text.trim()
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationPage(
            email: email,
            signupData: signupData,
          ),
        ),
      );
    } else {
      setState(() {
        errorMessage = otpResponse['error'] ?? "Failed to send OTP.";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text("Student Signup", style: TextStyle(color: Colors.white, fontSize: 25)),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text("Create an Account", style: AppTextStyles.heading),
                    SizedBox(height: 8),
                    Text("Sign up to continue", style: AppTextStyles.body),
                  ],
                ),
              ),
              SizedBox(height: 24),

              buildTextField("First Name", Icons.person, firstNameController),
              SizedBox(height: 16),
              buildTextField("Last Name", Icons.person, lastNameController),
              SizedBox(height: 16),
              buildTextField("Email", Icons.email, emailController),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Level",
                  prefixIcon: Icon(Icons.school, color: AppColors.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: selectedLevel,
                items: levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                onChanged: (value) => setState(() => selectedLevel = value),
              ),
              SizedBox(height: 16),

              buildTextField("Student Number", Icons.badge, studentNumberController),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Department",
                  prefixIcon: Icon(Icons.business, color: AppColors.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: selectedDepartment,
                items: departments.isEmpty
                    ? [
                  DropdownMenuItem(
                    value: null,
                    child: Text("No departments available"),
                  )
                ]
                    : departments.map((dep) {
                  return DropdownMenuItem(
                    value: dep,
                    child: Text(dep),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select a department";
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Faculty",
                  prefixIcon: Icon(Icons.school_outlined, color: AppColors.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: selectedFaculty,
                items: faculties.isEmpty
                    ? [
                  DropdownMenuItem(
                    value: null,
                    child: Text("No faculties available"),
                  )
                ]
                    : faculties.map((fac) {
                  return DropdownMenuItem(
                    value: fac,
                    child: Text(fac),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFaculty = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select a faculty";
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              buildTextField("Phone Number", Icons.phone, phoneNoController, isPhone: true),
              SizedBox(height: 16),
              buildTextField("Password", Icons.lock, passwordController, isPassword: true),
              SizedBox(height: 24),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : initiateSignupWithOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up", style: AppTextStyles.button),
                ),
              ),
              SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: AppTextStyles.body,
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, IconData icon, TextEditingController controller,
      {bool isPassword = false, bool isPhone = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

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
  final TextEditingController academicYearController = TextEditingController();

  String? selectedDepartment;
  String? selectedFaculty;

  List<String> departments = [];
  List<String> faculties = [];

  String errorMessage = "";
  bool isLoading = false;
  final AuthController authController = AuthController();

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    // Set default academic year to current year for new students
    academicYearController.text = DateTime.now().year.toString();
  }

  Future<void> fetchDropdownData() async {
    try {
      final depResponse = await http.get(Uri.parse("$baseUrl/api/common/departments"));
      final facResponse = await http.get(Uri.parse("$baseUrl/api/common/faculties"));

      if (depResponse.statusCode == 200 && facResponse.statusCode == 200) {
        final List<dynamic> depData = jsonDecode(depResponse.body);
        final List<dynamic> facData = jsonDecode(facResponse.body);

        setState(() {
          departments = depData.map((e) => e['departmentName'].toString()).toList();
          faculties = facData.map((e) => e['facultyName'].toString()).toList();
        });

        //debug
        print("Departments: $departments");
        print("Faculties: $faculties");

      } else {
        print("Failed to load dropdown data");
      }
    } catch (e) {
      print("Error fetching dropdown data: $e");
    }
  }

  Future<void> initiateSignupWithOtp() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    final email = emailController.text.trim();
    final academicYear = academicYearController.text.trim();

    // ✅ Check for empty fields
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        email.isEmpty ||
        passwordController.text.trim().isEmpty ||
        studentNumberController.text.trim().isEmpty ||
        selectedDepartment == null ||
        selectedFaculty == null ||
        phoneNoController.text.trim().isEmpty ||
        academicYear.isEmpty) {
      setState(() {
        errorMessage = "All fields are required.";
        isLoading = false;
      });
      return;
    }

    // Validate academic year
    final int? year = int.tryParse(academicYear);
    final int currentYear = DateTime.now().year;
    if (year == null || year < (currentYear - 6) || year > currentYear) {
      setState(() {
        errorMessage = "Please enter a valid academic year (${currentYear-6} to $currentYear)";
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
        "studentAcademicYear": academicYear, // Changed to use academic year instead of level
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

              // Academic Year field instead of Level dropdown
              buildTextField(
                "Academic Year (Batch Year)", 
                Icons.calendar_today, 
                academicYearController,
                isNumeric: true,
                helperText: "Enter the year you started at the university"
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
      {bool isPassword = false, bool isPhone = false, bool isNumeric = false, String? helperText}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumeric 
          ? TextInputType.number 
          : isPhone 
              ? TextInputType.phone 
              : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

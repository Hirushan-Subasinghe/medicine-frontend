import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../controllers/auth_controller.dart';
import 'login_page.dart';

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
    try {
      final depResponse = await http.get(Uri.parse("http://172.19.44.233:5000/api/common/departments"));
      final facResponse = await http.get(Uri.parse("http://172.19.44.233:5000/api/common/faculties"));

      if (depResponse.statusCode == 200 && facResponse.statusCode == 200) {
        final List<dynamic> depData = jsonDecode(depResponse.body);
        final List<dynamic> facData = jsonDecode(facResponse.body);

        setState(() {
          departments = depData.map((e) => e['deptName'].toString()).toList();
          faculties = facData.map((e) => e['facultyName'].toString()).toList();
        });
      } else {
        print("Failed to load dropdown data");
      }
    } catch (e) {
      print("Error fetching dropdown data: $e");
    }
  }

  Future<void> signupUser() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
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

    String? result = await authController.signup(
      firstNameController.text.trim(),
      lastNameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
      studentNumberController.text.trim(),
      selectedLevel!,
      selectedDepartment!,
      selectedFaculty!,
      phoneNoController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      showSuccessDialog();
    } else {
      setState(() {
        errorMessage = result ?? "Signup failed. Please try again.";
      });
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Success"),
        content: Text("Your account has been created successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
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
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
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
                items: departments.map((dep) => DropdownMenuItem(value: dep, child: Text(dep))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value;
                  });
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
                items: faculties.map((fac) => DropdownMenuItem(value: fac, child: Text(fac))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFaculty = value;
                  });
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
                  onPressed: isLoading ? null : signupUser,
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

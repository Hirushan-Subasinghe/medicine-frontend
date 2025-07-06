class StudentData {
  final String studentNumber;
  final String academicYear;
  final String level;  // For example: LEVEL_1, LEVEL_2, etc.

  StudentData({
    required this.studentNumber,
    required this.academicYear,
    required this.level,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    print("🎓 Parsing student data: $json");
    return StudentData(
      studentNumber: json['studentNumber'] ?? json['stuId'] ?? '',
      academicYear: json['academicYear'] ?? '',
      level: json['level'] ?? '',
    );
  }
}

class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNo;
  final String profileImgUrl;
  final String? userRole;  // Add userRole field
  final StudentData? student;
  final DateTime? createdAt;  // New field for creation timestamp
  final DateTime? updatedAt;  // New field for update timestamp

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNo,
    required this.profileImgUrl,
    this.userRole,
    this.student,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print("👤 Parsing user data: $json");
    return UserModel(
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNo: json['phoneNo'],
      profileImgUrl: json['profileImgUrl'] ?? '',
      userRole: json['userRole'],
      student: json['student'] != null
          ? StudentData.fromJson(Map<String, dynamic>.from(json['student']))
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // A method to update the profile data
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNo,
    String? profileImgUrl,
    String? userRole,
    StudentData? student,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      userRole: userRole ?? this.userRole,
      student: student ?? this.student,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

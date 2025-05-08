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
    return StudentData(
      studentNumber: json['studentNumber'] ?? '',
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
    this.student,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNo: json['phoneNo'],
      profileImgUrl: json['profileImgUrl'] ?? '',
      student: json['student'] != null
          ? StudentData.fromJson(json['student'])
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
      student: student ?? this.student,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

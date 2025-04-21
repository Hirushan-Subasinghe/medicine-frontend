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

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNo,
    required this.profileImgUrl,
    this.student,
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
    );
  }

  // A method to update the profile image if needed
  UserModel copyWith({String? profileImgUrl}) {
    return UserModel(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNo: phoneNo,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      student: student,
    );
  }
}

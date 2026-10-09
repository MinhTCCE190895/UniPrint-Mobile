class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final int role; // 1: Student, 2: Staff, 3: Admin

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  bool get isStudent => role == 1;
  bool get isStaff => role == 2;
  bool get isAdmin => role == 3;

  String get roleName {
    switch (role) {
      case 1:
        return 'Sinh viên';
      case 2:
        return 'Nhân viên';
      case 3:
        return 'Quản trị viên';
      default:
        return 'Người dùng';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] is int ? json['role'] : 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'role': role,
  };
}

class AuthResponse {
  final String accessToken;
  final UserModel user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      user: UserModel.fromJson(json),
    );
  }
}

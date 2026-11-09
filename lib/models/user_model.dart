class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final int role; // 1: Student, 2: Staff, 3: Admin
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    this.createdAt,
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

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    int? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parsedRole = 1;
    if (json['role'] is int) {
      parsedRole = json['role'];
    } else if (json['role'] is String) {
      final rStr = (json['role'] as String).toLowerCase();
      if (rStr == 'admin' || rStr == '3') {
        parsedRole = 3;
      } else if (rStr == 'staff' || rStr == '2') {
        parsedRole = 2;
      } else {
        parsedRole = 1;
      }
    }

    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: parsedRole,
      isActive: json['isActive'] is bool ? json['isActive'] : true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'avatarUrl': avatarUrl,
    'role': role,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
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

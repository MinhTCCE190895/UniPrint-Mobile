import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<AuthResponse> login(String email, String password) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      withAuth: false,
    );

    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return AuthResponse.fromJson(response['data']);
    }
    return AuthResponse.fromJson(response);
  }

  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await ApiClient.post(
      ApiEndpoints.register,
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      },
      withAuth: false,
    );
  }

  static Future<UserModel> getProfile() async {
    final response = await ApiClient.get(ApiEndpoints.profile, withAuth: true);
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return UserModel.fromJson(response['data']);
    }
    return UserModel.fromJson(response);
  }

  static Future<UserModel> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    final response = await ApiClient.put(
      ApiEndpoints.updateProfile,
      body: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      },
      withAuth: true,
    );
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return UserModel.fromJson(response['data']);
    }
    return UserModel.fromJson(response);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await ApiClient.put(
      ApiEndpoints.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      withAuth: true,
    );
  }
}

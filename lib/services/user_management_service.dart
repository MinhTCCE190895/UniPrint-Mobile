import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

/// Task 5: Dịch vụ API Quản lý người dùng dành cho Admin:
/// - Lấy danh sách người dùng kèm bộ lọc (tìm kiếm, role, status)
/// - Phân quyền vai trò (Role: Student / Staff / Admin)
/// - Khóa / Mở khóa tài khoản (IsActive)
class UserManagementService {
  static dynamic _data(dynamic response) =>
      (response is Map<String, dynamic> && response.containsKey('data'))
          ? response['data']
          : response;

  static String _extractMessage(dynamic response, String fallback) {
    if (response is Map<String, dynamic> && response['message'] != null) {
      return response['message'].toString();
    }
    return fallback;
  }

  /// Lấy danh sách người dùng với các bộ lọc tuỳ chọn
  static Future<List<UserModel>> getUsers({
    String? searchTerm,
    int? role,
    bool? isActive,
  }) async {
    final params = <String>[];
    if (searchTerm != null && searchTerm.trim().isNotEmpty) {
      params.add('searchTerm=${Uri.encodeComponent(searchTerm.trim())}');
    }
    if (role != null) {
      params.add('role=$role');
    }
    if (isActive != null) {
      params.add('isActive=$isActive');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '${ApiEndpoints.users}$query';

    final response = await ApiClient.get(url);
    final data = _data(response);

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }
    return [];
  }

  /// Lấy chi tiết thông tin người dùng theo ID
  static Future<UserModel> getUserById(String id) async {
    final response = await ApiClient.get(ApiEndpoints.userById(id));
    return UserModel.fromJson(_data(response));
  }

  /// Cập nhật quyền (Role) của người dùng
  static Future<({UserModel user, String message})> updateUserRole(
    String userId,
    int role,
  ) async {
    final response = await ApiClient.put(
      ApiEndpoints.userRole(userId),
      body: {'role': role},
    );
    final message = _extractMessage(response, 'Cập nhật vai trò thành công.');
    return (user: UserModel.fromJson(_data(response)), message: message);
  }

  /// Khóa hoặc mở khóa tài khoản người dùng
  static Future<({UserModel user, String message})> toggleUserStatus(
    String userId, {
    bool? isActive,
  }) async {
    final body = isActive != null ? {'isActive': isActive} : <String, dynamic>{};
    final response = await ApiClient.put(
      ApiEndpoints.userStatus(userId),
      body: body,
    );
    final message = _extractMessage(response, 'Cập nhật trạng thái thành công.');
    return (user: UserModel.fromJson(_data(response)), message: message);
  }
}


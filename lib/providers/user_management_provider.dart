import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_management_service.dart';

/// Task 5: Quản lý trạng thái danh sách người dùng cho Admin
class UserManagementProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchTerm = '';
  int? _selectedRole; // null: tất cả, 1: Student, 2: Staff, 3: Admin
  bool? _selectedStatus; // null: tất cả, true: hoạt động, false: khóa

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get searchTerm => _searchTerm;
  int? get selectedRole => _selectedRole;
  bool? get selectedStatus => _selectedStatus;

  // Thống kê nhanh
  int get totalCount => _users.length;
  int get studentCount => _users.where((u) => u.isStudent).length;
  int get staffCount => _users.where((u) => u.isStaff).length;
  int get adminCount => _users.where((u) => u.isAdmin).length;
  int get lockedCount => _users.where((u) => !u.isActive).length;

  @protected
  Future<List<UserModel>> fetchUsersFromService({
    String? searchTerm,
    int? role,
    bool? isActive,
  }) =>
      UserManagementService.getUsers(
        searchTerm: searchTerm,
        role: role,
        isActive: isActive,
      );

  @protected
  Future<({UserModel user, String message})> submitRoleUpdate(
    String userId,
    int role,
  ) =>
      UserManagementService.updateUserRole(userId, role);

  @protected
  Future<({UserModel user, String message})> submitStatusToggle(
    String userId, {
    bool? isActive,
  }) =>
      UserManagementService.toggleUserStatus(userId, isActive: isActive);

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await fetchUsersFromService(
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        role: _selectedRole,
        isActive: _selectedStatus,
      );
    } catch (e) {
      _errorMessage = _clean(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    if (_searchTerm == term) return;
    _searchTerm = term;
    loadUsers();
  }

  void setRoleFilter(int? role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    loadUsers();
  }

  void setStatusFilter(bool? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadUsers();
  }

  void resetFilters() {
    _searchTerm = '';
    _selectedRole = null;
    _selectedStatus = null;
    loadUsers();
  }

  Future<bool> updateUserRole(String userId, int newRole) async {
    if (_isActionLoading) return false;
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await submitRoleUpdate(userId, newRole);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = result.user;
      }
      _successMessage = result.message;
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(String userId, {bool? isActive}) async {
    if (_isActionLoading) return false;
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await submitStatusToggle(userId, isActive: isActive);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = result.user;
      }
      _successMessage = result.message;
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  static String _clean(Object e) => e
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiResponseException: ', '');
}


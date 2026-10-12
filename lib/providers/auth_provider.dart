import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await AuthService.getProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      await StorageService.clearSession();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await AuthService.login(email, password);
      _currentUser = res.user;

      await StorageService.saveSession(
        token: res.accessToken,
        userId: res.user.id,
        name: res.user.fullName,
        email: res.user.email,
        role: res.user.role,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.register(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  @visibleForTesting
  void setUserForTesting(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
}

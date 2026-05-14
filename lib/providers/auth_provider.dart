import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isModerator => _currentUser?.isModerator ?? false;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) _currentUser = await _authService.getCurrentUser();
    } catch (_) {
      // Тихая ошибка при старте — просто не залогинен
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authService.login(email, password);
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _msg(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resultEmail = await _authService.register(email, username, password);
      _isLoading = false;
      notifyListeners();
      return resultEmail;
    } catch (e) {
      _error = _msg(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> setUserFromResponse(AuthResponse response) async {
    _currentUser = response.user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? username, String? avatarUrl}) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.updateProfile(username: username, avatarUrl: avatarUrl);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _msg(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.changePassword(currentPassword, newPassword, code);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _msg(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(List<int> imageBytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _msg(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<List<User>?> getAllUsers() async {
    if (!isModerator) return null;
    try {
      final response = await _authService.getAllUsers();
      return response.items;
    } catch (e) {
      _error = _msg(e);
      return null;
    }
  }

  Future<bool> banUser(int userId, String banType, {String? banUntil, String? reason}) async {
    if (!isModerator) return false;
    try {
      await _authService.banUser(userId, banType, banUntil: banUntil, reason: reason);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    }
  }

  Future<bool> unbanUser(int userId) async {
    if (!isModerator) return false;
    try {
      await _authService.unbanUser(userId);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    if (!isAdmin) return false;
    try {
      await _authService.deleteUser(userId);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, String role) async {
    if (!isAdmin) return false;
    try {
      await _authService.updateUserRole(userId, role);
      return true;
    } catch (e) {
      _error = _msg(e);
      return false;
    }
  }

  static String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

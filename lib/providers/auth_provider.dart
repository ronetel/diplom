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

  // Инициализация - проверка сохраненной сессии
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Вход
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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Регистрация
  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(email, username, password);
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Выход
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Обновить профиль
  Future<bool> updateProfile({String? username, String? avatarUrl}) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Сменить пароль
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Загрузить аватар
  Future<bool> uploadAvatar(List<int> imageBytes, String filename) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: реализовать загрузку аватарки через ApiService
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== ADMIN/MODERATOR ====================

  // Получить всех пользователей
  Future<List<User>?> getAllUsers() async {
    if (!isModerator) return null;

    try {
      final response = await _authService.getAllUsers();
      return response.items;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Заблокировать пользователя
  Future<bool> banUser(int userId, String banType, {String? banUntil, String? reason}) async {
    if (!isModerator) return false;

    try {
      await _authService.banUser(userId, banType, banUntil: banUntil, reason: reason);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Разблокировать пользователя
  Future<bool> unbanUser(int userId) async {
    if (!isModerator) return false;

    try {
      await _authService.unbanUser(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Удалить пользователя (только админ)
  Future<bool> deleteUser(int userId) async {
    if (!isAdmin) return false;

    try {
      await _authService.deleteUser(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Изменить роль (только админ)
  Future<bool> updateUserRole(int userId, String role) async {
    if (!isAdmin) return false;

    try {
      await _authService.updateUserRole(userId, role);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}

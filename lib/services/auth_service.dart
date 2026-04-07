import '../models/user.dart';
import '../models/auth_response.dart';
export '../models/auth_response.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Регистрация
  Future<AuthResponse> register(String email, String username, String password) async {
    final response = await _api.post('/auth/register', body: {
      'email': email,
      'username': username,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  // Вход
  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  // Сохранить данные авторизации
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', authResponse.token);
    await prefs.setString('user_email', authResponse.user.email);
    await prefs.setInt('user_id', authResponse.user.id);
    await prefs.setString('username', authResponse.user.username);
    await prefs.setString('user_role', authResponse.user.role);
    ApiService.setToken(authResponse.token);
  }

  // Получить текущего пользователя
  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return User.fromJson(response['user']);
    } catch (e) {
      return null;
    }
  }

  // Обновить профиль
  Future<User> updateProfile({String? username, String? avatarUrl}) async {
    final body = <String, String>{};
    if (username != null) body['username'] = username;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _api.put('/auth/profile', body: body);
    return User.fromJson(response['user']);
  }

  // Загрузить аватар
  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final response = await _api.uploadBytes(
      '/upload/uploadAvatar',
      bytes,
      filename,
    );
    return response['user']['avatar_url'] as String;
  }

  // Сменить пароль
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.put('/auth/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Выход
  Future<void> logout() async {
    await _api.clearToken();
  }

  // Проверить, авторизован ли пользователь
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      ApiService.setToken(token);
      return true;
    }
    return false;
  }

  // Получить сохраненного пользователя
  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;

    return {
      'token': token,
      'id': prefs.getInt('user_id'),
      'email': prefs.getString('user_email'),
      'username': prefs.getString('username'),
      'role': prefs.getString('user_role'),
    };
  }

  // ==================== ADMIN/MODERATOR ====================

  // Получить всех пользователей (только для admin/moderator)
  Future<PaginationData<User>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (role != null) queryParams['role'] = role;
    if (search != null) queryParams['search'] = search;

    final response = await _api.get('/auth/users', queryParams: queryParams);
    return PaginationData.fromJson(
      response,
      (json) => User.fromJson(json),
      'users',
    );
  }

  // Получить пользователя по ID
  Future<User> getUserById(int userId) async {
    final response = await _api.get('/auth/users/$userId');
    return User.fromJson(response['user']);
  }

  // Изменить роль пользователя (только admin)
  Future<User> updateUserRole(int userId, String role) async {
    final response = await _api.put('/auth/users/$userId/role', body: {
      'role': role,
    });
    return User.fromJson(response['user']);
  }

  // Заблокировать пользователя
  Future<void> banUser(int userId, String banType, {String? banUntil, String? reason}) async {
    await _api.post('/auth/users/$userId/ban', body: {
      'banType': banType,
      'banUntil': banUntil,
      'reason': reason,
    });
  }

  // Разблокировать пользователя
  Future<void> unbanUser(int userId) async {
    await _api.post('/auth/users/$userId/unban');
  }

  // Удалить пользователя (только admin)
  Future<void> deleteUser(int userId) async {
    await _api.delete('/auth/users/$userId');
  }
}

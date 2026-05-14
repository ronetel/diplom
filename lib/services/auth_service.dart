import '../models/user.dart';
import '../models/auth_response.dart';
export '../models/auth_response.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _api = ApiService();

  
  // Возвращает email — пользователь должен подтвердить код
  Future<String> register(String email, String username, String password) async {
    final response = await _api.post('/auth/register', body: {
      'email': email,
      'username': username,
      'password': password,
    });
    return response['email'] as String;
  }

  Future<AuthResponse> verifyEmail(String email, String code) async {
    final response = await _api.post('/auth/verify-email', body: {
      'email': email,
      'code': code,
    });
    final authResponse = AuthResponse.fromJson(response);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  Future<void> resendVerification(String email) async {
    await _api.post('/auth/resend-verification', body: {'email': email});
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _api.post('/auth/reset-password', body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  
  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', authResponse.token);
    await prefs.setString('user_email', authResponse.user.email);
    await prefs.setInt('user_id', authResponse.user.id);
    await prefs.setString('username', authResponse.user.username);
    await prefs.setString('user_role', authResponse.user.role);
    ApiService.setToken(authResponse.token);
  }

  
  Future<User?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return User.fromJson(response['user']);
    } catch (e) {
      return null;
    }
  }

  
  Future<User> updateProfile({String? username, String? avatarUrl}) async {
    final body = <String, String>{};
    if (username != null) body['username'] = username;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _api.put('/auth/profile', body: body);
    return User.fromJson(response['user']);
  }

  
  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final response = await _api.uploadBytes(
      '/upload/uploadAvatar',
      bytes,
      filename,
    );
    return response['user']['avatar_url'] as String;
  }

  
  Future<String> requestPasswordChangeCode(String currentPassword) async {
    final response = await _api.post('/auth/password-change-code', body: {
      'currentPassword': currentPassword,
    });
    return response['email'] as String;
  }

  Future<void> changePassword(String currentPassword, String newPassword, String code) async {
    await _api.put('/auth/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'code': code,
    });
  }

  
  Future<void> logout() async {
    await _api.clearToken();
  }

  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      ApiService.setToken(token);
      return true;
    }
    return false;
  }

  
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

  
  Future<User> getUserById(int userId) async {
    final response = await _api.get('/auth/users/$userId');
    return User.fromJson(response['user']);
  }

  
  Future<User> updateUserRole(int userId, String role) async {
    final response = await _api.put('/auth/users/$userId/role', body: {
      'role': role,
    });
    return User.fromJson(response['user']);
  }

  
  Future<void> banUser(int userId, String banType, {String? banUntil, String? reason}) async {
    await _api.post('/auth/users/$userId/ban', body: {
      'banType': banType,
      'banUntil': banUntil,
      'reason': reason,
    });
  }

  
  Future<void> unbanUser(int userId) async {
    await _api.post('/auth/users/$userId/unban');
  }

  
  Future<void> deleteUser(int userId) async {
    await _api.delete('/auth/users/$userId');
  }
}

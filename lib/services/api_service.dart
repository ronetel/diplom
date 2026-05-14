import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Исключение с читаемым сообщением (без "Exception:" префикса).
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration _timeout = Duration(seconds: 15);
  static String? _token;

  static String? get token => _token;
  static void setToken(String? value) => _token = value;

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('user_role');
  }

  Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setInt('user_id', user['id'] ?? 0);
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('user_role', user['role'] ?? 'user');
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return _execute(() async {
      final response = await http.get(uri, headers: await _getHeaders()).timeout(_timeout);
      return _handleResponse(response);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _execute(() async {
      final response = await http.post(uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _handleResponse(response);
    });
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return _execute(() async {
      final response = await http.put(uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _handleResponse(response);
    });
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _execute(() async {
      final response = await http.delete(uri, headers: await _getHeaders()).timeout(_timeout);
      return _handleResponse(response);
    });
  }

  Future<dynamic> uploadBytes(
    String path,
    List<int> bytes,
    String filename, {
    Map<String, String>? fields,
    String fieldName = 'file',
  }) async {
    return _execute(() async {
      final uri = Uri.parse('$baseUrl$path');
      final token = await _getToken();
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (fields != null) request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(
        fieldName, bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    });
  }

  /// Перехватывает сетевые ошибки и даёт читаемые сообщения.
  Future<T> _execute<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on SocketException {
      throw AppException('Нет соединения с сервером. Проверьте интернет.');
    } on TimeoutException {
      throw AppException('Сервер не отвечает. Попробуйте позже.');
    } on http.ClientException {
      throw AppException('Ошибка соединения с сервером.');
    } on HandshakeException {
      throw AppException('Ошибка защищённого соединения.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Неизвестная ошибка. Попробуйте ещё раз.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    if (statusCode == 401) clearToken();

    String rawMessage = '';
    try {
      final decoded = jsonDecode(body);
      rawMessage = (decoded['message'] as String?) ?? '';
    } catch (_) {}

    throw AppException(_translateError(rawMessage, statusCode));
  }

  static String _translateError(String message, int statusCode) {
    // Уже русский текст — возвращаем как есть
    if (_isRussian(message)) return message;

    const map = <String, String>{
      // Auth
      'Invalid credentials': 'Неверный email или пароль',
      'Email already exists': 'Этот email уже занят',
      'Username already exists': 'Это имя пользователя уже занято',
      'User already exists': 'Пользователь уже существует',
      'User not found': 'Пользователь не найден',
      'Email not verified': 'Сначала подтвердите email',
      'Email and password required': 'Введите email и пароль',
      'Email, username and password required': 'Заполните все поля',
      'Invalid email format': 'Неверный формат email',
      'Username must be 3-30 characters, alphanumeric and underscores only':
          'Имя: 3–30 символов, только буквы, цифры и _',
      'Current and new password required': 'Введите текущий и новый пароль',
      'Current password, new password and code required':
          'Введите пароли и код подтверждения',
      'Current password is incorrect': 'Неверный текущий пароль',
      'Current password required': 'Введите текущий пароль',
      'Invalid or expired code': 'Неверный или истёкший код',
      'Code expired': 'Код истёк, запросите новый',
      'Code already used': 'Код уже был использован',
      'Wait before resending': 'Подождите перед повторной отправкой',
      // Token / access
      'No token': 'Необходима авторизация',
      'Invalid token': 'Сессия истекла, войдите снова',
      'Token expired': 'Сессия истекла, войдите снова',
      'Unauthorized': 'Необходима авторизация',
      'Forbidden': 'Доступ запрещён',
      'Insufficient permissions': 'Недостаточно прав',
      // Account
      'Account is banned': 'Аккаунт заблокирован',
      'Account suspended': 'Аккаунт приостановлен',
      // Resources
      'Not found': 'Запрашиваемый ресурс не найден',
      'Endpoint not found': 'Маршрут не найден',
      'Outfit not found': 'Образ не найден',
      'Post not found': 'Публикация не найдена',
      'Cloth not found': 'Вещь не найдена',
      // Server
      'Internal error': 'Внутренняя ошибка сервера',
      'Internal server error': 'Внутренняя ошибка сервера',
      'Service unavailable': 'Сервис временно недоступен',
    };

    if (map.containsKey(message)) return map[message]!;

    // Проверяем частичные совпадения для длинных сообщений
    for (final entry in map.entries) {
      if (message.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Фолбэк по статус-коду
    if (message.isNotEmpty) return message;
    return switch (statusCode) {
      400 => 'Неверный запрос',
      401 => 'Необходима авторизация',
      403 => 'Доступ запрещён',
      404 => 'Не найдено',
      409 => 'Конфликт: данные уже существуют',
      422 => 'Неверные данные',
      429 => 'Слишком много запросов, подождите немного',
      500 => 'Ошибка сервера. Попробуйте позже.',
      502 || 503 => 'Сервер временно недоступен',
      _ => 'Ошибка (код $statusCode)',
    };
  }

  static bool _isRussian(String text) {
    return text.runes.any((r) => r >= 0x0400 && r <= 0x04FF);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // WEB: localhost:8000
  // http://10.0.2.2:8000
  // http://192.168.1.103:8000
  static const String baseUrl = 'http://localhost:8000';
  static String? _token;

  static String? get token => _token;

  static void setToken(String? value) {
    _token = value;
  }

  // Получить токен из SharedPreferences
  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  // Получить заголовки с авторизацией
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Сохранить токен
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Удалить токен
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('user_role');
  }

  // Сохранить данные пользователя
  Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setInt('user_id', user['id'] ?? 0);
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('user_role', user['role'] ?? 'user');
  }

  // GET запрос
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  // POST запрос
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // PUT запрос
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // DELETE запрос
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  // Загрузка байтов (для image_picker)
  Future<dynamic> uploadBytes(
    String path,
    List<int> bytes,
    String filename, {
    Map<String, String>? fields,
    String fieldName = 'file',
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();

    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Добавляем поля
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Добавляем файл
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // Обработка ответа
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (e) {
        return body;
      }
    } else {
      String errorMessage;
      try {
        final decoded = jsonDecode(body);
        errorMessage = decoded['message'] ?? 'Ошибка запроса';
      } catch (e) {
        errorMessage = 'Ошибка запроса (код $statusCode)';
      }
      if (statusCode == 401) clearToken();
      throw Exception(errorMessage);
    }
  }
}

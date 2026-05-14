import '../models/user.dart';
import 'api_service.dart';

class FollowService {
  final ApiService _api = ApiService();

  Future<User> getUserProfile(int userId) async {
    final response = await _api.get('/auth/profile/$userId');
    return User.fromJson(response['user']);
  }

  Future<bool> followUser(int userId) async {
    final response = await _api.post('/auth/users/$userId/follow');
    return response['following'] == true;
  }

  Future<bool> unfollowUser(int userId) async {
    final response = await _api.delete('/auth/users/$userId/follow');
    return response['following'] == true;
  }

  Future<List<User>> getFollowers(int userId) async {
    final response = await _api.get('/auth/users/$userId/followers');
    return (response['users'] as List).map((e) => User.fromJson({
      ...e,
      'email': e['email'] ?? '',
      'created_at': e['created_at'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }

  Future<List<User>> getFollowing(int userId) async {
    final response = await _api.get('/auth/users/$userId/following');
    return (response['users'] as List).map((e) => User.fromJson({
      ...e,
      'email': e['email'] ?? '',
      'created_at': e['created_at'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await _api.get('/auth/users/search?q=${Uri.encodeQueryComponent(query)}');
    return (response['users'] as List).map((e) => User.fromJson({
      ...e,
      'email': e['email'] ?? '',
      'created_at': e['created_at'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }
}

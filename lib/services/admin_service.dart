import 'api_service.dart';
import '../models/user.dart';

class AdminPost {
  final int id;
  final String? content;
  final String? title;
  final bool isHidden;
  final List<String> tags;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final int likesCount;
  final int commentsCount;
  final String? reportReason;

  AdminPost({
    required this.id,
    this.content,
    this.title,
    required this.isHidden,
    required this.tags,
    required this.imageUrls,
    required this.createdAt,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.likesCount,
    required this.commentsCount,
    this.reportReason,
  });

  factory AdminPost.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.startsWith('{')) {
        return val.replaceAll('{', '').replaceAll('}', '').split(',')
            .where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return AdminPost(
      id: json['id'],
      content: json['content'],
      title: json['title'],
      isHidden: json['is_hidden'] ?? false,
      tags: parseList(json['tags']),
      imageUrls: parseList(json['image_urls']),
      createdAt: DateTime.parse(json['created_at']),
      authorId: json['author_id'],
      authorUsername: json['username'] ?? 'Пользователь',
      authorAvatarUrl: json['avatar_url'],
      likesCount: int.tryParse((json['likes_count'] ?? 0).toString()) ?? 0,
      commentsCount: int.tryParse((json['comments_count'] ?? 0).toString()) ?? 0,
      reportReason: json['report_reason'],
    );
  }
}

class AdminComment {
  final int id;
  final String content;
  final bool isHidden;
  final DateTime createdAt;
  final int postId;
  final int authorId;
  final String authorUsername;
  final String? authorAvatarUrl;

  AdminComment({
    required this.id,
    required this.content,
    required this.isHidden,
    required this.createdAt,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
  });

  factory AdminComment.fromJson(Map<String, dynamic> json) {
    return AdminComment(
      id: json['id'],
      content: json['content'] ?? '',
      isHidden: json['is_hidden'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      postId: json['post_id'],
      authorId: json['author_id'],
      authorUsername: json['username'] ?? 'Пользователь',
      authorAvatarUrl: json['avatar_url'],
    );
  }
}

class LogEntry {
  final int id;
  final String action;
  final int? actorId;
  final String? actorUsername;
  final String? targetType;
  final int? targetId;
  final String? targetName;
  final String? details;
  final DateTime createdAt;

  LogEntry({
    required this.id,
    required this.action,
    this.actorId,
    this.actorUsername,
    this.targetType,
    this.targetId,
    this.targetName,
    this.details,
    required this.createdAt,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      action: json['action'],
      actorId: json['actor_id'],
      actorUsername: json['actor_username'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      targetName: json['target_name'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AdminService {
  final ApiService _api = ApiService();

  // ── POSTS ─────────────────────────────────────────────────

  Future<({List<AdminPost> posts, int total})> getPosts({
    int page = 1, int limit = 30, String search = '',
  }) async {
    final response = await _api.get('/admin/posts', queryParams: {
      'page': page.toString(), 'limit': limit.toString(), 'search': search,
    });
    final posts = (response['posts'] as List)
        .map((e) => AdminPost.fromJson(e))
        .toList();
    final total = int.tryParse((response['pagination']?['total'] ?? 0).toString()) ?? 0;
    return (posts: posts, total: total);
  }

  Future<void> hidePost(int postId, bool isHidden, {String? reason}) async {
    await _api.put('/admin/posts/$postId/hide', body: {
      'isHidden': isHidden,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> editPostContent(int postId, String content) async {
    await _api.put('/admin/posts/$postId/content', body: {'content': content});
  }

  Future<void> deletePost(int postId) async {
    await _api.delete('/admin/posts/$postId');
  }

  // ── COMMENTS ──────────────────────────────────────────────

  Future<({List<AdminComment> comments, int total})> getComments({
    int page = 1, int limit = 30, String search = '',
  }) async {
    final response = await _api.get('/admin/comments', queryParams: {
      'page': page.toString(), 'limit': limit.toString(), 'search': search,
    });
    final comments = (response['comments'] as List)
        .map((e) => AdminComment.fromJson(e))
        .toList();
    final total = int.tryParse((response['pagination']?['total'] ?? 0).toString()) ?? 0;
    return (comments: comments, total: total);
  }

  Future<void> hideComment(int commentId, bool isHidden) async {
    await _api.put('/admin/comments/$commentId/hide', body: {'isHidden': isHidden});
  }

  Future<void> editComment(int commentId, String content) async {
    await _api.put('/admin/comments/$commentId/content', body: {'content': content});
  }

  Future<void> deleteComment(int commentId) async {
    await _api.delete('/admin/comments/$commentId');
  }

  // ── USERS ─────────────────────────────────────────────────

  Future<({List<User> users, int total})> getUsers({
    int page = 1, int limit = 30, String search = '', String? role,
  }) async {
    final params = <String, String>{
      'page': page.toString(), 'limit': limit.toString(), 'search': search,
    };
    if (role != null) params['role'] = role;

    final response = await _api.get('/admin/users', queryParams: params);
    final users = (response['users'] as List)
        .map((e) => User.fromJson(e))
        .toList();
    final total = int.tryParse((response['pagination']?['total'] ?? 0).toString()) ?? 0;
    return (users: users, total: total);
  }

  Future<void> banUser(int userId, {DateTime? banUntil, required String reason}) async {
    await _api.post('/admin/users/$userId/ban', body: {
      'reason': reason,
      'banUntil': banUntil?.toIso8601String(),
    });
  }

  Future<void> unbanUser(int userId) async {
    await _api.post('/admin/users/$userId/unban');
  }

  Future<void> changeRole(int userId, String role) async {
    await _api.put('/admin/users/$userId/role', body: {'role': role});
  }

  Future<void> deleteUser(int userId) async {
    await _api.delete('/admin/users/$userId');
  }

  // ── LOGS ──────────────────────────────────────────────────

  Future<({List<LogEntry> logs, List<String> actionTypes, int total})> getLogs({
    int page = 1, int limit = 50,
    String? action, String? actor, String? search,
    DateTime? from, DateTime? to,
  }) async {
    final params = <String, String>{
      'page': page.toString(), 'limit': limit.toString(),
    };
    if (action != null) params['action'] = action;
    if (actor != null && actor.isNotEmpty) params['actor'] = actor;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final response = await _api.get('/admin/logs', queryParams: params);
    final logs = (response['logs'] as List)
        .map((e) => LogEntry.fromJson(e))
        .toList();
    final actionTypes = (response['actionTypes'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final total = int.tryParse((response['pagination']?['total'] ?? 0).toString()) ?? 0;
    return (logs: logs, actionTypes: actionTypes, total: total);
  }
}

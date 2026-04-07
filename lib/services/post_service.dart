import '../models/post.dart';
import '../models/comment.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class PostService {
  final ApiService _api = ApiService();

  // Получить ленту постов
  Future<PaginationData<Post>> getFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/posts/feed', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    return PaginationData.fromJson(
      response,
      (json) => Post.fromJson(json),
      'posts',
    );
  }

  // Получить посты пользователя
  Future<PaginationData<Post>> getUserPosts(int userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/posts/user/$userId', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    return PaginationData.fromJson(
      response,
      (json) => Post.fromJson(json),
      'posts',
    );
  }

  // Получить пост по ID
  Future<Post> getPostById(int id) async {
    final response = await _api.get('/posts/$id');
    return Post.fromJson(response['post']);
  }

  // Создать пост
  Future<Post> createPost({
    int? outfitId,
    String? title,
    String? content,
    List<String> imageUrls = const [],
    List<String> tags = const [],
  }) async {
    final response = await _api.post('/posts', body: {
      'outfit_id': outfitId,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
      'tags': tags,
    });

    return Post.fromJson(response['post']);
  }

  // Обновить пост
  Future<Post> updatePost(
    int id, {
    String? title,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (imageUrls != null) body['image_urls'] = imageUrls;
    if (tags != null) body['tags'] = tags;

    final response = await _api.put('/posts/$id', body: body);
    return Post.fromJson(response['post']);
  }

  // Удалить пост
  Future<void> deletePost(int id) async {
    await _api.delete('/posts/$id');
  }

  // Лайкнуть пост
  Future<Map<String, dynamic>> likePost(int id) async {
    final response = await _api.post('/posts/$id/like');
    return {
      'liked': response['liked'],
      'likesCount': response['likesCount'],
    };
  }

  // Убрать лайк
  Future<Map<String, dynamic>> unlikePost(int id) async {
    final response = await _api.delete('/posts/$id/like');
    return {
      'liked': response['liked'],
      'likesCount': response['likesCount'],
    };
  }

  // Проверить, лайкнул ли пользователь пост
  Future<bool> isLiked(int id) async {
    try {
      final response = await _api.get('/posts/$id/like/status');
      return response['liked'];
    } catch (e) {
      return false;
    }
  }

  // Получить лайки поста
  Future<List<dynamic>> getLikes(int id) async {
    final response = await _api.get('/posts/$id/likes');
    return response['likes'];
  }

  // Добавить комментарий
  Future<Comment> addComment(int postId, String content) async {
    final response = await _api.post('/posts/$postId/comments', body: {
      'content': content,
    });

    return Comment.fromJson(response['comment']);
  }

  // Получить комментарии поста
  Future<List<Comment>> getComments(int postId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get('/posts/$postId/comments', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    final comments = response['comments'] as List;
    return comments.map((e) => Comment.fromJson(e)).toList();
  }

  // Удалить комментарий
  Future<void> deleteComment(int postId, int commentId) async {
    await _api.delete('/posts/$postId/comments/$commentId');
  }

  // ==================== MODERATOR ====================

  // Скрыть/показать пост (moderator/admin)
  Future<Post> hidePost(int id, bool isHidden, {String? reason}) async {
    final response = await _api.put('/posts/$id/hide', body: {
      'isHidden': isHidden,
      'reason': reason,
    });
    return Post.fromJson(response['post']);
  }

  // Получить посты с жалобами (moderator/admin)
  Future<List<Post>> getReportedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/posts/reports/list', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    final posts = response['posts'] as List;
    return posts.map((e) => Post.fromJson(e)).toList();
  }
}

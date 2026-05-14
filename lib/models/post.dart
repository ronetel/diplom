import 'outfit.dart';
import 'comment.dart';

class Post {
  final int id;
  final int authorId;
  final int? outfitId;
  final Outfit? outfit;
  final String? title;
  final String? content;
  final List<String> imageUrls;
  final List<String> tags;
  final bool isHidden;
  final bool isReported;
  final String? reportReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  final String? authorUsername;
  final String? authorAvatarUrl;
  
  final int likesCount;
  final int commentsCount;
  final bool? isLiked;
  
  final List<Comment>? comments;

  Post({
    required this.id,
    required this.authorId,
    this.outfitId,
    this.outfit,
    this.title,
    this.content,
    this.imageUrls = const [],
    this.tags = const [],
    this.isHidden = false,
    this.isReported = false,
    this.reportReason,
    required this.createdAt,
    this.updatedAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      authorId: json['author_id'] ?? json['authorId'],
      outfitId: json['outfit_id'] ?? json['outfitId'],
      outfit: json['outfit'] != null ? Outfit.fromJson(json['outfit']) : null,
      title: json['title'],
      content: json['content'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isHidden: json['is_hidden'] ?? json['isHidden'] ?? false,
      isReported: json['is_reported'] ?? json['isReported'] ?? false,
      reportReason: json['report_reason'] ?? json['reportReason'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
      authorUsername: json['username'] ?? json['authorUsername'],
      authorAvatarUrl: json['avatar_url'] ?? json['authorAvatarUrl'],
      likesCount: int.tryParse((json['likes_count'] ?? json['likesCount'] ?? 0).toString()) ?? 0,
      commentsCount: int.tryParse((json['comments_count'] ?? json['commentsCount'] ?? 0).toString()) ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((e) => Comment.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'outfit_id': outfitId,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Post copyWith({
    int? id,
    int? authorId,
    int? outfitId,
    Outfit? outfit,
    String? title,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    bool? isHidden,
    bool? isReported,
    String? reportReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorUsername,
    String? authorAvatarUrl,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      outfitId: outfitId ?? this.outfitId,
      outfit: outfit ?? this.outfit,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      isHidden: isHidden ?? this.isHidden,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}

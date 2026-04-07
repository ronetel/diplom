class Comment {
  final int id;
  final int postId;
  final int authorId;
  final String content;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Автор
  final String? authorUsername;
  final String? authorAvatarUrl;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.isHidden = false,
    required this.createdAt,
    this.updatedAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'] ?? json['postId'],
      authorId: json['author_id'] ?? json['authorId'],
      content: json['content'],
      isHidden: json['is_hidden'] ?? json['isHidden'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
      authorUsername: json['username'] ?? json['authorUsername'],
      authorAvatarUrl: json['avatar_url'] ?? json['authorAvatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

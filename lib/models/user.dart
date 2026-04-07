class User {
  final int id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String role;
  final bool isBanned;
  final DateTime? banUntil;
  final String? banReason;
  final DateTime createdAt;
  // Статистика
  final int? clothesCount;
  final int? outfitsCount;
  final int? postsCount;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.role = 'user',
    this.isBanned = false,
    this.banUntil,
    this.banReason,
    required this.createdAt,
    this.clothesCount,
    this.outfitsCount,
    this.postsCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      role: json['role'] ?? 'user',
      isBanned: json['is_banned'] ?? json['isBanned'] ?? false,
      banUntil: json['ban_until'] != null || json['banUntil'] != null
          ? DateTime.parse(json['ban_until'] ?? json['banUntil'])
          : null,
      banReason: json['ban_reason'] ?? json['banReason'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      clothesCount: int.tryParse((json['clothes_count'] ?? json['clothesCount'] ?? 0).toString()),
      outfitsCount: int.tryParse((json['outfits_count'] ?? json['outfitsCount'] ?? 0).toString()),
      postsCount: int.tryParse((json['posts_count'] ?? json['postsCount'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'role': role,
      'is_banned': isBanned,
      'ban_until': banUntil?.toIso8601String(),
      'ban_reason': banReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator' || role == 'admin';
  bool get isUser => role == 'user';

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? role,
    bool? isBanned,
    DateTime? banUntil,
    String? banReason,
    DateTime? createdAt,
    int? clothesCount,
    int? outfitsCount,
    int? postsCount,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      banUntil: banUntil ?? this.banUntil,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      clothesCount: clothesCount ?? this.clothesCount,
      outfitsCount: outfitsCount ?? this.outfitsCount,
      postsCount: postsCount ?? this.postsCount,
    );
  }
}

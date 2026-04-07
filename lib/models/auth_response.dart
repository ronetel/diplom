import 'user.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

class PaginationData<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationData({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
    String key,
  ) {
    final data = json[key] as List;
    final pagination = json['pagination'] ?? {};

    return PaginationData(
      items: data.map((e) => fromJson(e)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      total: pagination['total'] ?? 0,
      pages: pagination['pages'] ?? 1,
    );
  }

  bool get hasMore => page < pages;

  bool get isEmpty => items.isEmpty;
}

import 'cloth.dart';

class Outfit {
  final int id;
  final int ownerId;
  final String? name;
  final String? description;
  final String event;
  final String? season;
  final List<int> clothesIds;
  final List<Cloth>? clothes;
  final String? thumbnailUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final String? ownerUsername;

  Outfit({
    required this.id,
    required this.ownerId,
    this.name,
    this.description,
    this.event = 'casual',
    this.season,
    this.clothesIds = const [],
    this.clothes,
    this.thumbnailUrl,
    this.isFavorite = false,
    required this.createdAt,
    this.ownerUsername,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    List<Cloth>? clothesList;
    if (json['clothes'] != null) {
      clothesList = (json['clothes'] as List)
          .map((e) => Cloth.fromJson(e))
          .toList();
    }

    return Outfit(
      id: json['id'],
      ownerId: json['owner_id'] ?? json['ownerId'],
      name: json['name'],
      description: json['description'],
      event: json['event'] ?? 'casual',
      season: json['season'],
      clothesIds: json['clothes_ids'] != null
          ? List<int>.from(json['clothes_ids'])
          : [],
      clothes: clothesList,
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : DateTime.now(),
      ownerUsername: json['owner_username'] ?? json['ownerUsername'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'event': event,
      'season': season,
      'clothes_ids': clothesIds,
      'thumbnail_url': thumbnailUrl,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName => name ?? 'Образ #$id';

  String get eventLabel {
    final index = Cloth.events.indexOf(event);
    return index >= 0 ? Cloth.eventLabels[index] : event;
  }

  String get seasonLabel {
    if (season == null) return '';
    final index = Cloth.seasons.indexOf(season!);
    return index >= 0 ? Cloth.seasonLabels[index] : season!;
  }

  Outfit copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? description,
    String? event,
    String? season,
    List<int>? clothesIds,
    List<Cloth>? clothes,
    String? thumbnailUrl,
    bool? isFavorite,
    DateTime? createdAt,
    String? ownerUsername,
  }) {
    return Outfit(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      event: event ?? this.event,
      season: season ?? this.season,
      clothesIds: clothesIds ?? this.clothesIds,
      clothes: clothes ?? this.clothes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      ownerUsername: ownerUsername ?? this.ownerUsername,
    );
  }
}

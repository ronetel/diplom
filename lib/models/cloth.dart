class Cloth {
  final int id;
  final int? ownerId;
  final String imageUrl;
  final String? processedImageUrl; 
  final String? name;              
  final String? category;          
  final String? brandNames;
  final String? descriptions;
  final String type;
  final String event;
  final String? color;
  final String? material;
  final String? season;
  final String? size;
  final bool isFavorite;
  final DateTime createdAt;
  final String? ownerUsername;

  Cloth({
    required this.id,
    this.ownerId,
    required this.imageUrl,
    this.processedImageUrl,
    this.name,
    this.category,
    this.brandNames,
    this.descriptions,
    required this.type,
    this.event = 'casual',
    this.color,
    this.material,
    this.season,
    this.size,
    this.isFavorite = false,
    required this.createdAt,
    this.ownerUsername,
  });

  factory Cloth.fromJson(Map<String, dynamic> json) {
    return Cloth(
      id: json['id'],
      ownerId: json['owner_id'] ?? json['ownerId'],
      imageUrl: json['image_urls'] ?? json['imageUrl'] ?? '',
      processedImageUrl: json['processed_image_url'] ?? json['processedImageUrl'],
      name: json['name'],
      category: json['category'],
      brandNames: json['brand_names'] ?? json['brandNames'],
      descriptions: json['descriptions'],
      type: json['type'] ?? 'top',
      event: json['event'] ?? 'casual',
      color: json['color'],
      material: json['material'],
      season: json['season'],
      size: json['size'],
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
      'image_urls': imageUrl,
      'brand_names': brandNames,
      'descriptions': descriptions,
      'type': type,
      'event': event,
      'color': color,
      'material': material,
      'season': season,
      'size': size,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }

  
  static const List<String> types = [
    'top',
    'bottom',
    'full-body',
    'outerwear',
    'shoes',
    'accessory',
  ];

  static const List<String> typeLabels = [
    'Верх',
    'Низ',
    'Полный костюм',
    'Верхняя одежда',
    'Обувь',
    'Аксессуар',
  ];

  
  static const List<String> events = [
    'casual',
    'workout',
    'formal',
    'meeting',
    'outdoor',
    'night-out',
  ];

  static const List<String> eventLabels = [
    'Повседневное',
    'Спорт',
    'Формальное',
    'Встреча',
    'На улице',
    'Вечеринка',
  ];

  
  static const List<String> seasons = [
    'spring',
    'summer',
    'autumn',
    'winter',
    'all-season',
  ];

  static const List<String> seasonLabels = [
    'Весна',
    'Лето',
    'Осень',
    'Зима',
    'Всесезонное',
  ];

  String get typeLabel {
    final index = types.indexOf(type);
    return index >= 0 ? typeLabels[index] : type;
  }

  String get eventLabel {
    final index = events.indexOf(event);
    return index >= 0 ? eventLabels[index] : event;
  }

  String get seasonLabel {
    if (season == null) return '';
    final index = seasons.indexOf(season!);
    return index >= 0 ? seasonLabels[index] : season!;
  }

  Cloth copyWith({
    int? id,
    int? ownerId,
    String? imageUrl,
    String? processedImageUrl,
    String? name,
    String? category,
    String? brandNames,
    String? descriptions,
    String? type,
    String? event,
    String? color,
    String? material,
    String? season,
    String? size,
    bool? isFavorite,
    DateTime? createdAt,
    String? ownerUsername,
  }) {
    return Cloth(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      processedImageUrl: processedImageUrl ?? this.processedImageUrl,
      name: name ?? this.name,
      category: category ?? this.category,
      brandNames: brandNames ?? this.brandNames,
      descriptions: descriptions ?? this.descriptions,
      type: type ?? this.type,
      event: event ?? this.event,
      color: color ?? this.color,
      material: material ?? this.material,
      season: season ?? this.season,
      size: size ?? this.size,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      ownerUsername: ownerUsername ?? this.ownerUsername,
    );
  }
}

import '../models/outfit.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class OutfitService {
  final ApiService _api = ApiService();

  // Получить образы текущего пользователя
  Future<PaginationData<Outfit>> getMyOutfits({
    String? event,
    String? season,
    bool? isFavorite,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (event != null) queryParams['event'] = event;
    if (season != null) queryParams['season'] = season;
    if (isFavorite != null) queryParams['is_favorite'] = isFavorite.toString();

    final response = await _api.get('/outfits', queryParams: queryParams);
    return PaginationData.fromJson(
      response,
      (json) => Outfit.fromJson(json),
      'outfits',
    );
  }

  // Получить образ по ID
  Future<Outfit> getOutfitById(int id) async {
    final response = await _api.get('/outfits/$id');
    return Outfit.fromJson(response['outfit']);
  }

  // Создать образ
  Future<Outfit> createOutfit({
    required String name,
    String? description,
    String event = 'casual',
    String? season,
    List<int> clothesIds = const [],
    String? thumbnailUrl,
  }) async {
    final response = await _api.post('/outfits', body: {
      'name': name,
      'description': description,
      'event': event,
      'season': season,
      'clothes_ids': clothesIds,
      'thumbnail_url': thumbnailUrl,
    });

    return Outfit.fromJson(response['outfit']);
  }

  // Обновить образ
  Future<Outfit> updateOutfit(
    int id, {
    String? name,
    String? description,
    String? event,
    String? season,
    List<int>? clothesIds,
    String? thumbnailUrl,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (event != null) body['event'] = event;
    if (season != null) body['season'] = season;
    if (clothesIds != null) body['clothes_ids'] = clothesIds;
    if (thumbnailUrl != null) body['thumbnail_url'] = thumbnailUrl;
    if (isFavorite != null) body['is_favorite'] = isFavorite;

    final response = await _api.put('/outfits/$id', body: body);
    return Outfit.fromJson(response['outfit']);
  }

  // Удалить образ
  Future<void> deleteOutfit(int id) async {
    await _api.delete('/outfits/$id');
  }

  // Добавить/убрать из избранного
  Future<Outfit> toggleFavorite(int id, bool isFavorite) async {
    return await updateOutfit(id, isFavorite: isFavorite);
  }

  // Сгенерировать образ на основе погоды
  Future<Map<String, dynamic>> generateOutfit({
    String event = 'casual',
    double? temp,
    String? date,
  }) async {
    final body = <String, dynamic>{
      'event': event,
    };
    if (temp != null) body['temp'] = temp;
    if (date != null) body['date'] = date;

    final response = await _api.post('/outfits/generate', body: body);
    return {
      'clothesIds': List<int>.from(response['clothesIds'] ?? []),
      'season': response['season'],
      'event': response['event'],
      'temp': response['temp'],
    };
  }

  // Получить образы на дату
  Future<List<Outfit>> getOutfitsByDate(String date) async {
    final response = await _api.get('/outfits/date/$date');
    final outfits = response['outfits'] as List;
    return outfits.map((e) => Outfit.fromJson(e)).toList();
  }

  // Получить образы за период
  Future<List<Outfit>> getOutfitsByDateRange(String startDate, String endDate) async {
    // Можно реализовать на бэкенде или фильтровать локально
    final response = await _api.get('/outfits');
    final outfits = response['outfits']['items'] as List;
    return outfits.map((e) => Outfit.fromJson(e)).toList();
  }
}

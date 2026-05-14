import '../models/outfit.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class OutfitService {
  final ApiService _api = ApiService();

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
    return PaginationData.fromJson(response, (json) => Outfit.fromJson(json), 'outfits');
  }

  Future<Outfit> getOutfitById(int id) async {
    final response = await _api.get('/outfits/$id');
    return Outfit.fromJson(response['outfit']);
  }

  Future<Outfit> createOutfit({
    required String name,
    String? description,
    String event = 'casual',
    String? season,
    int? tempMin,
    int? tempMax,
    List<String> whereToWear = const [],
    List<int> clothesIds = const [],
    String? thumbnailUrl,
  }) async {
    final response = await _api.post('/outfits', body: {
      'name': name,
      'description': description,
      'event': event,
      'season': season,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'where_to_wear': whereToWear,
      'clothes_ids': clothesIds,
      'thumbnail_url': thumbnailUrl,
    });
    return Outfit.fromJson(response['outfit']);
  }

  Future<Outfit> updateOutfit(
    int id, {
    String? name,
    String? description,
    String? event,
    String? season,
    int? tempMin,
    int? tempMax,
    List<String>? whereToWear,
    List<int>? clothesIds,
    String? thumbnailUrl,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (event != null) body['event'] = event;
    if (season != null) body['season'] = season;
    if (tempMin != null) body['temp_min'] = tempMin;
    if (tempMax != null) body['temp_max'] = tempMax;
    if (whereToWear != null) body['where_to_wear'] = whereToWear;
    if (clothesIds != null) body['clothes_ids'] = clothesIds;
    if (thumbnailUrl != null) body['thumbnail_url'] = thumbnailUrl;
    if (isFavorite != null) body['is_favorite'] = isFavorite;

    final response = await _api.put('/outfits/$id', body: body);
    return Outfit.fromJson(response['outfit']);
  }

  Future<void> deleteOutfit(int id) async {
    await _api.delete('/outfits/$id');
  }

  Future<Outfit> toggleFavorite(int id, bool isFavorite) async {
    return await updateOutfit(id, isFavorite: isFavorite);
  }
}

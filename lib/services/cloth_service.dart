import '../models/cloth.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class ClothService {
  final ApiService _api = ApiService();

  
  Future<PaginationData<Cloth>> getClothes({
    String? type,
    String? event,
    String? color,
    String? material,
    String? season,
    int? ownerId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type;
    if (event != null) queryParams['event'] = event;
    if (color != null) queryParams['color'] = color;
    if (material != null) queryParams['material'] = material;
    if (season != null) queryParams['season'] = season;
    if (ownerId != null) queryParams['owner_id'] = ownerId.toString();

    final response = await _api.get('/clothes', queryParams: queryParams);
    return PaginationData.fromJson(
      response,
      (json) => Cloth.fromJson(json),
      'clothes',
    );
  }

  
  Future<Cloth> getClothById(int id) async {
    final response = await _api.get('/clothes/$id');
    return Cloth.fromJson(response['cloth']);
  }

  
  Future<PaginationData<Cloth>> getMyClothes({
    String? type,
    String? event,
    String? color,
    String? material,
    String? season,
    bool? isFavorite,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type;
    if (event != null) queryParams['event'] = event;
    if (color != null) queryParams['color'] = color;
    if (material != null) queryParams['material'] = material;
    if (season != null) queryParams['season'] = season;
    if (isFavorite != null) queryParams['is_favorite'] = isFavorite.toString();

    final response = await _api.get('/clothes/user/me', queryParams: queryParams);
    return PaginationData.fromJson(
      response,
      (json) => Cloth.fromJson(json),
      'clothes',
    );
  }

  
  Future<List<Cloth>> getClothesByTypeAndEvent(String type, String event) async {
    final response = await _api.get('/clothes/type/$type/event/$event');
    final clothes = response['clothes'] as List;
    return clothes.map((e) => Cloth.fromJson(e)).toList();
  }

  
  
  Future<Map<String, String?>> processClothImage({
    required List<int> imageBytes,
    required String filename,
  }) async {
    final response = await _api.uploadBytes(
      '/upload/processCloth',
      imageBytes,
      filename,
    );
    return {
      'imageUrl': response['imageUrl'] as String?,
      'processedImageUrl': response['processedImageUrl'] as String?,
    };
  }

  
  Future<Cloth> createClothFromUrls({
    required String imageUrl,
    String? processedImageUrl,
    required String type,
    String? name,
    String? category,
    String? brandNames,
    String? descriptions,
    String event = 'casual',
    String? season,
    String? size,
  }) async {
    final response = await _api.post('/clothes', body: {
      'image_urls': imageUrl,
      'processed_image_url': processedImageUrl,
      'type': type,
      'name': name,
      'category': category,
      'brand_names': brandNames,
      'descriptions': descriptions,
      'event': event,
      'season': season,
      'size': size,
    });
    return Cloth.fromJson(response['cloth']);
  }

  
  Future<Cloth> createClothFromBytes({
    required List<int> imageBytes,
    required String filename,
    required String type,
    String? brandNames,
    String? descriptions,
    String event = 'casual',
    String? color,
    String? material,
    String? season,
    String? size,
  }) async {
    final fields = <String, String>{
      'type': type,
      'event': event,
    };
    if (brandNames != null) fields['brand_names'] = brandNames;
    if (descriptions != null) fields['descriptions'] = descriptions;
    if (color != null) fields['color'] = color;
    if (material != null) fields['material'] = material;
    if (season != null) fields['season'] = season;
    if (size != null) fields['size'] = size;

    final response = await _api.uploadBytes(
      '/upload/uploadImage',
      imageBytes,
      filename,
      fields: fields,
    );

    return Cloth.fromJson(response['cloth']);
  }

  
  Future<Cloth> updateCloth(
    int id, {
    String? name,
    String? category,
    String? brandNames,
    String? descriptions,
    String? type,
    String? event,
    String? season,
    String? size,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (brandNames != null) body['brand_names'] = brandNames;
    if (descriptions != null) body['descriptions'] = descriptions;
    if (type != null) body['type'] = type;
    if (event != null) body['event'] = event;
    if (season != null) body['season'] = season;
    if (size != null) body['size'] = size;
    if (isFavorite != null) body['is_favorite'] = isFavorite;

    final response = await _api.put('/clothes/$id', body: body);
    return Cloth.fromJson(response['cloth']);
  }

  
  Future<void> deleteCloth(int id) async {
    await _api.delete('/clothes/$id');
  }

  
  Future<Cloth> toggleFavorite(int id, bool isFavorite) async {
    return await updateCloth(id, isFavorite: isFavorite);
  }

  
  Future<Map<String, dynamic>> getClothesStats() async {
    final response = await _api.get('/clothes/stats/me');
    return {
      'total': response['total'],
      'byType': response['byType'],
      'byEvent': response['byEvent'],
      'byColor': response['byColor'],
    };
  }

  
  Future<Map<String, List<String>>> getFilterOptions() async {
    
    return {
      'types': Cloth.types,
      'events': Cloth.events,
      'seasons': Cloth.seasons,
    };
  }
}

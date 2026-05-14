import 'package:geolocator/geolocator.dart';
import '../models/outfit.dart';
import '../models/weather.dart';
import 'api_service.dart';
// ignore_for_file: avoid_print

class WeatherService {
  final ApiService _api = ApiService();

  
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    
    return await Geolocator.getCurrentPosition();
  }

  
  Future<Weather?> getWeatherByLocation(double lat, double lon) async {
    try {
      final response = await _api.get('/weather/current', queryParams: {
        'lat': lat.toString(),
        'lon': lon.toString(),
      });

      if (response == null || response['weather'] == null) {
        return null;
      }

      return Weather.fromJson(response['weather']);
    } catch (e) {
      print('Error getting weather: $e');
      return null;
    }
  }

  
  Future<Weather?> getCurrentWeather() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return await getWeatherByLocation(position.latitude, position.longitude);
  }

  
  Future<Weather?> getWeatherByCity(String city) async {
    try {
      final response = await _api.get('/weather/city/$city');

      if (response == null || response['weather'] == null) {
        return null;
      }

      return Weather.fromJson(response['weather']);
    } catch (e) {
      print('Error getting weather by city: $e');
      return null;
    }
  }

  
  Future<Map<String, dynamic>?> getForecast(double lat, double lon) async {
    try {
      final response = await _api.get('/weather/forecast', queryParams: {
        'lat': lat.toString(),
        'lon': lon.toString(),
      });

      return response['forecast'];
    } catch (e) {
      print('Error getting forecast: $e');
      return null;
    }
  }

  
  Future<Map<String, dynamic>?> getWeatherRecommendation({
    double? lat,
    double? lon,
    String event = 'casual',
  }) async {
    try {
      final queryParams = <String, String>{
        'event': event,
      };
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lon != null) queryParams['lon'] = lon.toString();

      final response = await _api.get('/weather/recommend', queryParams: queryParams);

      return {
        'weather': response['weather'] != null
            ? Weather.fromJson(response['weather'])
            : null,
        'recommendations': response['recommendations'] != null
            ? WeatherRecommendation.fromJson(response['recommendations'])
            : null,
        'availableClothes': response['availableClothes'],
        'recommendedOutfit': response['recommendedOutfit'] != null
            ? (response['recommendedOutfit'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [],
      };
    } catch (e) {
      print('Error getting weather recommendation: $e');
      return null;
    }
  }

  
  Future<Map<String, dynamic>?> getRecommendationWithLocation({
    String event = 'casual',
  }) async {
    final position = await getCurrentPosition();
    if (position == null) {
      return await getWeatherRecommendation(event: event);
    }

    return await getWeatherRecommendation(
      lat: position.latitude,
      lon: position.longitude,
      event: event,
    );
  }

  /// Основной метод для страницы погоды — возвращает образы с ai_tags
  Future<Map<String, dynamic>?> getWeatherRecommendations() async {
    try {
      final position = await getCurrentPosition();

      final queryParams = <String, String>{};
      if (position != null) {
        queryParams['lat'] = position.latitude.toString();
        queryParams['lon'] = position.longitude.toString();
      }

      final response = await _api.get('/weather/recommend', queryParams: queryParams);
      if (response == null) return null;

      return {
        'weather': response['weather'] != null
            ? Weather.fromJson(response['weather'])
            : null,
        'suggestions': response['recommendations'] != null
            ? List<String>.from(
                (response['recommendations']['suggestions'] as List? ?? []))
            : <String>[],
        'outfits': response['outfits'] != null
            ? (response['outfits'] as List)
                .map((e) => Outfit.fromJson(e as Map<String, dynamic>))
                .toList()
            : <Outfit>[],
        'unanalyzed_count': response['unanalyzed_count'] as int? ?? 0,
      };
    } catch (e) {
      print('Error getting weather recommendations: $e');
      return null;
    }
  }
}

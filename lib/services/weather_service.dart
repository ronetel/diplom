import 'package:geolocator/geolocator.dart';
import '../models/weather.dart';
import 'api_service.dart';

class WeatherService {
  final ApiService _api = ApiService();

  // Получить текущую позицию пользователя
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем включена ли геолокация
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Проверяем разрешения
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

    // Получаем позицию
    return await Geolocator.getCurrentPosition();
  }

  // Получить погоду по координатам
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

  // Получить текущую погоду
  Future<Weather?> getCurrentWeather() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return await getWeatherByLocation(position.latitude, position.longitude);
  }

  // Получить погоду по названию города
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

  // Получить прогноз на 5 дней
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

  // Получить рекомендации образа на основе погоды
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

  // Получить рекомендации с автоматическим определением локации
  Future<Map<String, dynamic>?> getRecommendationWithLocation({
    String event = 'casual',
  }) async {
    final position = await getCurrentPosition();
    if (position == null) {
      // Если нет геолокации, получаем без координат
      return await getWeatherRecommendation(event: event);
    }

    return await getWeatherRecommendation(
      lat: position.latitude,
      lon: position.longitude,
      event: event,
    );
  }
}

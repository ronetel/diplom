class Weather {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final String description;
  final String icon;
  final String main;
  final double windSpeed;
  final int windDeg;
  final int clouds;
  final String cityName;
  final String country;

  Weather({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.main,
    required this.windSpeed,
    required this.windDeg,
    required this.clouds,
    required this.cityName,
    required this.country,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temp: (json['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),
      tempMin: (json['main']?['temp_min'] ?? 0).toDouble(),
      tempMax: (json['main']?['temp_max'] ?? 0).toDouble(),
      humidity: json['main']?['humidity'] ?? 0,
      description: json['weather']?[0]?['description'] ?? '',
      icon: json['weather']?[0]?['icon'] ?? '',
      main: json['weather']?[0]?['main'] ?? '',
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      windDeg: json['wind']?['deg'] ?? 0,
      clouds: json['clouds']?['all'] ?? 0,
      cityName: json['name'] ?? '',
      country: json['sys']?['country'] ?? '',
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get tempFormatted => '${temp.round()}°C';

  String get feelsLikeFormatted => 'Ощущается как ${feelsLike.round()}°C';

  // Определение сезона на основе температуры
  String get season {
    if (temp < 5) return 'winter';
    if (temp < 15) return 'autumn';
    if (temp < 25) return 'spring';
    return 'summer';
  }

  String get seasonLabel {
    switch (season) {
      case 'winter':
        return 'Зима';
      case 'autumn':
        return 'Осень';
      case 'spring':
        return 'Весна';
      case 'summer':
        return 'Лето';
      default:
        return '';
    }
  }

  // Рекомендации по одежде на основе погоды
  List<String> get clothingSuggestions {
    final suggestions = <String>[];

    if (temp < 0) {
      suggestions.add('Теплая зимняя куртка');
      suggestions.add('Шапка и шарф');
      suggestions.add('Теплые перчатки');
      suggestions.add('Зимняя обувь');
    } else if (temp < 10) {
      suggestions.add('Куртка или пальто');
      suggestions.add('Свитер или худи');
      suggestions.add('Закрытая обувь');
    } else if (temp < 20) {
      suggestions.add('Легкая куртка или кардиган');
      suggestions.add('Лонгслив или футболка');
      suggestions.add('Джинсы или брюки');
    } else if (temp < 30) {
      suggestions.add('Футболка или майка');
      suggestions.add('Шорты или легкие брюки');
      suggestions.add('Открытая обувь');
    } else {
      suggestions.add('Максимально легкая одежда');
      suggestions.add('Светлые ткани');
      suggestions.add('Головной убор от солнца');
    }

    if (humidity > 80) {
      suggestions.add('Возьмите зонт');
    }

    if (windSpeed > 10) {
      suggestions.add('Ветрозащитная одежда');
    }

    return suggestions;
  }
}

class WeatherRecommendation {
  final double temp;
  final String season;
  final List<String> suggestions;
  final String event;

  WeatherRecommendation({
    required this.temp,
    required this.season,
    required this.suggestions,
    required this.event,
  });

  factory WeatherRecommendation.fromJson(Map<String, dynamic> json) {
    return WeatherRecommendation(
      temp: (json['temp'] ?? 0).toDouble(),
      season: json['season'] ?? 'all-season',
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : [],
      event: json['event'] ?? 'casual',
    );
  }
}

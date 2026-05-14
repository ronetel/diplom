class WeatherPreset {
  final String label;
  final String emoji;
  final int min;
  final int max;

  const WeatherPreset(this.label, this.emoji, this.min, this.max);
}

const List<WeatherPreset> weatherPresets = [
  WeatherPreset('Жара',      '🥵', 30,  50),
  WeatherPreset('Жарко',     '☀️', 25,  30),
  WeatherPreset('Тепло',     '🌤', 18,  25),
  WeatherPreset('Прохладно', '🌥', 10,  18),
  WeatherPreset('Холодно',   '🧥',  0,  10),
  WeatherPreset('Мороз',     '❄️', -30,  0),
];

const List<String> whereOptions = [
  'Работа',
  'Учёба',
  'Свидание',
  'Прогулка',
  'Вечеринка',
  'Фитнес',
  'Дом',
  'Пляж',
  'Поход',
  'Торжество',
  'Шопинг',
  'Кафе / ресторан',
  'Кино / театр',
  'Спорт',
  'Путешествие',
];

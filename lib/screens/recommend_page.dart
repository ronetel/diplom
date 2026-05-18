import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/outfit.dart';
import '../models/weather.dart';
import '../providers/auth_provider.dart';
import '../services/weather_service.dart';
import '../services/api_service.dart';
import 'outfit_detail_page.dart';
import 'profile_page.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final WeatherService _weatherService = WeatherService();
  final ApiService _api = ApiService();

  Weather? _weather;
  List<String> _suggestions = [];
  List<Outfit> _outfits = [];
  int _unanalyzedCount = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _weatherService.getWeatherRecommendations();

      if (result == null) {
        setState(() {
          _isLoading = false;
          _error = 'Не удалось получить данные';
        });
        return;
      }

      setState(() {
        _weather = result['weather'] as Weather?;
        _suggestions = List<String>.from(result['suggestions'] ?? []);
        _outfits = List<Outfit>.from(result['outfits'] ?? []);
        _unanalyzedCount = result['unanalyzed_count'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeAll() async {
    setState(() => _isAnalyzing = true);
    try {
      await _api.post('/weather/analyze-all', body: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Анализ запущен. Обновите страницу через несколько секунд.')),
      );
      await Future.delayed(const Duration(seconds: 3));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода и образы'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage:
                  user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null
                  ? Text((user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12))
                  : null,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_weather != null) _buildWeatherCard(),
        const SizedBox(height: 12),
        if (_suggestions.isNotEmpty) _buildSuggestionsCard(),
        const SizedBox(height: 12),
        if (_unanalyzedCount > 0) _buildAnalyzeBanner(),
        const SizedBox(height: 12),
        _buildOutfitsSection(),
      ],
    );
  }

  Widget _buildWeatherCard() {
    final w = _weather!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.network(w.iconUrl, width: 64, height: 64,
                    errorBuilder: (context2, err, stack) =>
                        const Icon(Icons.wb_sunny, size: 64)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.tempFormatted,
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(w.cityName,
                          style: Theme.of(context).textTheme.bodyLarge),
                      Text(w.description.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _weatherDetail(Icons.water_drop, '${w.humidity}%', 'Влажность'),
                _weatherDetail(
                    Icons.air, '${w.windSpeed.toStringAsFixed(1)} м/с', 'Ветер'),
                _weatherDetail(Icons.cloud, '${w.clouds}%', 'Облачность'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Что надеть',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ..._suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeBanner() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$_unanalyzedCount образов ещё не проанализированы ИИ',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(
                    onPressed: _analyzeAll,
                    child: const Text('Анализировать'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitsSection() {
    if (_outfits.isEmpty) {
      final hasUnanalyzed = _unanalyzedCount > 0;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                hasUnanalyzed ? Icons.auto_awesome : Icons.style_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                hasUnanalyzed
                    ? 'Образы ещё не проанализированы ИИ'
                    : _weather != null
                        ? 'Нет подходящих образов для текущей погоды'
                        : 'Нет образов для отображения',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                hasUnanalyzed
                    ? 'Нажмите "Анализировать" выше, чтобы ИИ подобрал образы по погоде'
                    : 'Создайте образы с фото, и ИИ подберёт подходящие по погоде',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.style, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Подходящие образы (${_outfits.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        ..._outfits.map(_buildOutfitCard),
      ],
    );
  }

  Widget _buildOutfitCard(Outfit outfit) {
    final tags = outfit.aiTags;
    final hasAiDescription =
        tags != null && (tags['ai_description'] as String?)?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OutfitDetailPage(outfit: outfit)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (outfit.thumbnailUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  outfit.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context2, err, stack) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.style, size: 48, color: Colors.grey[400]),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          outfit.displayName,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (outfit.isFavorite)
                        const Icon(Icons.favorite, size: 16, color: Colors.red),
                    ],
                  ),

                  // AI description
                  if (hasAiDescription) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tags['ai_description'] as String,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (outfit.weatherLabel.isNotEmpty)
                        _chip(Icons.thermostat, outfit.weatherLabel),
                      if (tags != null) ...[
                        _chip(
                          _warmthIcon(tags['warmth_level'] as String? ?? ''),
                          _warmthLabel(tags['warmth_level'] as String? ?? ''),
                        ),
                        if ((tags['weather_suitable'] as List?)?.isNotEmpty ==
                            true)
                          ...(tags['weather_suitable'] as List)
                              .take(2)
                              .map((w) => _chip(
                                  _weatherIcon(w as String),
                                  _weatherLabel(w))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  IconData _warmthIcon(String level) {
    switch (level) {
      case 'cold':
        return Icons.ac_unit;
      case 'cool':
        return Icons.thermostat_outlined;
      case 'warm':
        return Icons.local_fire_department;
      case 'hot':
        return Icons.whatshot;
      default:
        return Icons.thermostat;
    }
  }

  String _warmthLabel(String level) {
    const labels = {
      'cold': 'Очень тепло',
      'cool': 'Прохладно',
      'moderate': 'Умеренно',
      'warm': 'Тепло',
      'hot': 'Жарко',
    };
    return labels[level] ?? level;
  }

  IconData _weatherIcon(String tag) {
    switch (tag) {
      case 'rainy':
        return Icons.umbrella;
      case 'snowy':
        return Icons.ac_unit;
      case 'windy':
        return Icons.air;
      case 'cloudy':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  String _weatherLabel(String tag) {
    const labels = {
      'sunny': 'Солнечно',
      'cloudy': 'Пасмурно',
      'rainy': 'Дождь',
      'snowy': 'Снег',
      'windy': 'Ветер',
    };
    return labels[tag] ?? tag;
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/outfit_data.dart';
import '../models/cloth.dart';
import '../services/outfit_service.dart';

class OutfitSavePage extends StatefulWidget {
  final String? thumbnailUrl;
  final List<int> clothesIds;

  const OutfitSavePage({
    super.key,
    required this.thumbnailUrl,
    required this.clothesIds,
  });

  @override
  State<OutfitSavePage> createState() => _OutfitSavePageState();
}

class _OutfitSavePageState extends State<OutfitSavePage> {
  final OutfitService _service = OutfitService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedEvent = 'casual';
  String? _selectedSeason;
  WeatherPreset? _selectedWeather;
  final Set<String> _selectedWhere = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите название образа')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createOutfit(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        event: _selectedEvent,
        season: _selectedSeason,
        tempMin: _selectedWeather?.min,
        tempMax: _selectedWeather?.max,
        whereToWear: _selectedWhere.toList(),
        clothesIds: widget.clothesIds,
        thumbnailUrl: widget.thumbnailUrl,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Образ сохранён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сохранить образ'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Сохранить',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          if (widget.thumbnailUrl != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                  placeholder: (c, u) =>
                      const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  errorWidget: (c, u, e) =>
                      const SizedBox(height: 220, child: Center(child: Icon(Icons.image_not_supported))),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
            ),

          const SizedBox(height: 20),

          
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Название образа *',
              hintText: 'Например: Летний офис',
              prefixIcon: Icon(Icons.title_outlined),
            ),
          ),
          const SizedBox(height: 14),

          
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Заметки, повод...',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 20),

          
          const _Title('Событие'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(
              Cloth.events.length,
              (i) => ChoiceChip(
                label: Text(Cloth.eventLabels[i]),
                selected: _selectedEvent == Cloth.events[i],
                onSelected: (s) {
                  if (s) setState(() => _selectedEvent = Cloth.events[i]);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          
          const _Title('Сезон'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Любой'),
                selected: _selectedSeason == null,
                onSelected: (_) => setState(() => _selectedSeason = null),
              ),
              ...List.generate(
                Cloth.seasons.length,
                (i) => ChoiceChip(
                  label: Text(Cloth.seasonLabels[i]),
                  selected: _selectedSeason == Cloth.seasons[i],
                  onSelected: (s) {
                    if (s) setState(() => _selectedSeason = Cloth.seasons[i]);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          
          const _Title('Погода'),
          const SizedBox(height: 4),
          Text('Когда лучше носить этот образ?',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: weatherPresets.map((preset) {
              final selected = _selectedWeather == preset;
              return ChoiceChip(
                avatar: Text(preset.emoji),
                label: Text(
                  '${preset.label}\n${_fmt(preset.min)}…${_fmt(preset.max)}',
                  style: const TextStyle(fontSize: 12, height: 1.2),
                  textAlign: TextAlign.center,
                ),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedWeather = selected ? null : preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          
          const _Title('Куда надеть'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: whereOptions.map((opt) {
              final sel = _selectedWhere.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: sel,
                onSelected: (_) => setState(() {
                  if (sel) {
                    _selectedWhere.remove(opt);
                  } else {
                    _selectedWhere.add(opt);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Сохранить образ', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmt(int t) => t >= 0 ? '+$t°' : '$t°';
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
}

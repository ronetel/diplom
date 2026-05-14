import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/outfit_data.dart';
import '../models/cloth.dart';
import '../models/outfit.dart';
import '../services/outfit_service.dart';

class OutfitDetailPage extends StatefulWidget {
  final Outfit outfit;

  const OutfitDetailPage({super.key, required this.outfit});

  @override
  State<OutfitDetailPage> createState() => _OutfitDetailPageState();
}

class _OutfitDetailPageState extends State<OutfitDetailPage> {
  late Outfit _outfit;

  @override
  void initState() {
    super.initState();
    _outfit = widget.outfit;
  }

  Future<void> _openEdit() async {
    final updated = await showModalBottomSheet<Outfit>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditOutfitSheet(outfit: _outfit),
    );
    if (updated != null) setState(() => _outfit = updated);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить образ?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await OutfitService().deleteOutfit(_outfit.id);
      if (mounted) Navigator.pop(context, 'deleted');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _openEdit),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _delete),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _outfit.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _outfit.thumbnailUrl!,
                      fit: BoxFit.contain,
                      placeholder: (c, u) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (c, u, e) =>
                          const Center(child: Icon(Icons.image_not_supported, size: 64)),
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: const Center(
                          child: Icon(Icons.checkroom_outlined,
                              size: 80, color: Colors.grey)),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _outfit.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _FavBtn(
                          outfit: _outfit,
                          onChanged: (o) => setState(() => _outfit = o)),
                    ],
                  ),
                  if (_outfit.description != null &&
                      _outfit.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_outfit.description!,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],

                  const SizedBox(height: 16),

                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: _outfit.eventLabel, icon: Icons.event_outlined),
                      if (_outfit.season != null)
                        _InfoChip(
                            label: _outfit.seasonLabel,
                            icon: Icons.wb_sunny_outlined),
                      if (_outfit.weatherLabel.isNotEmpty)
                        _InfoChip(
                            label: _outfit.weatherLabel,
                            icon: Icons.thermostat_outlined),
                    ],
                  ),

                  if (_outfit.whereToWear.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _outfit.whereToWear
                          .map((w) => Chip(
                                label: Text(w,
                                    style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],

                  if (_outfit.clothes != null &&
                      _outfit.clothes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Вещи (${_outfit.clothes!.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _outfit.clothes!.length,
                        itemBuilder: (ctx, i) {
                          final cloth = _outfit.clothes![i];
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(
                                imageUrl:
                                    cloth.processedImageUrl ?? cloth.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => Image.network(
                                    cloth.imageUrl,
                                    fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(_outfit.createdAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return 'Создан ${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}



class _FavBtn extends StatefulWidget {
  final Outfit outfit;
  final ValueChanged<Outfit> onChanged;

  const _FavBtn({required this.outfit, required this.onChanged});

  @override
  State<_FavBtn> createState() => _FavBtnState();
}

class _FavBtnState extends State<_FavBtn> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return IconButton(
      icon: Icon(
          widget.outfit.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.outfit.isFavorite ? Colors.red : null,
          size: 28),
      onPressed: () async {
        setState(() => _loading = true);
        try {
          final updated = await OutfitService()
              .toggleFavorite(widget.outfit.id, !widget.outfit.isFavorite);
          widget.onChanged(updated);
        } catch (_) {}
        if (mounted) setState(() => _loading = false);
      },
    );
  }
}



class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}



class _EditOutfitSheet extends StatefulWidget {
  final Outfit outfit;

  const _EditOutfitSheet({required this.outfit});

  @override
  State<_EditOutfitSheet> createState() => _EditOutfitSheetState();
}

class _EditOutfitSheetState extends State<_EditOutfitSheet> {
  final OutfitService _service = OutfitService();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedEvent;
  late String? _selectedSeason;
  WeatherPreset? _selectedWeather;
  late Set<String> _selectedWhere;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.outfit.name ?? '');
    _descCtrl = TextEditingController(text: widget.outfit.description ?? '');
    _selectedEvent = widget.outfit.event;
    _selectedSeason = widget.outfit.season;
    _selectedWhere = Set.from(widget.outfit.whereToWear);

    if (widget.outfit.tempMin != null && widget.outfit.tempMax != null) {
      try {
        _selectedWeather = weatherPresets.firstWhere(
            (p) => p.min == widget.outfit.tempMin && p.max == widget.outfit.tempMax);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите название')));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _service.updateOutfit(
        widget.outfit.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        event: _selectedEvent,
        season: _selectedSeason,
        tempMin: _selectedWeather?.min,
        tempMax: _selectedWeather?.max,
        whereToWear: _selectedWhere.toList(),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(int t) => t >= 0 ? '+$t°' : '$t°';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Редактировать',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена')),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Название *',
                        prefixIcon: Icon(Icons.title_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Описание',
                        prefixIcon: Icon(Icons.description_outlined)),
                  ),
                  const SizedBox(height: 18),

                  const _SectionTitle('Событие'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
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
                  const SizedBox(height: 18),

                  const _SectionTitle('Сезон'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Любой'),
                        selected: _selectedSeason == null,
                        onSelected: (_) =>
                            setState(() => _selectedSeason = null),
                      ),
                      ...List.generate(
                        Cloth.seasons.length,
                        (i) => ChoiceChip(
                          label: Text(Cloth.seasonLabels[i]),
                          selected: _selectedSeason == Cloth.seasons[i],
                          onSelected: (s) {
                            if (s) {
                              setState(
                                  () => _selectedSeason = Cloth.seasons[i]);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const _SectionTitle('Погода'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: weatherPresets.map((preset) {
                      final sel = _selectedWeather == preset;
                      return ChoiceChip(
                        avatar: Text(preset.emoji),
                        label: Text(
                          '${preset.label}\n${_fmt(preset.min)}…${_fmt(preset.max)}',
                          style: const TextStyle(fontSize: 12, height: 1.2),
                          textAlign: TextAlign.center,
                        ),
                        selected: sel,
                        onSelected: (_) => setState(
                            () => _selectedWeather = sel ? null : preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  const _SectionTitle('Куда надеть'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
}

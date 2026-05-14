import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/clothing_categories.dart';
import '../models/cloth.dart';
import '../services/cloth_service.dart';

class ClothDetailPage extends StatefulWidget {
  final Cloth cloth;

  const ClothDetailPage({super.key, required this.cloth});

  @override
  State<ClothDetailPage> createState() => _ClothDetailPageState();
}

class _ClothDetailPageState extends State<ClothDetailPage> {
  late Cloth _cloth;

  @override
  void initState() {
    super.initState();
    _cloth = widget.cloth;
  }

  Future<void> _openEditSheet() async {
    final updated = await showModalBottomSheet<Cloth>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditClothSheet(cloth: _cloth),
    );
    if (updated != null) {
      setState(() => _cloth = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить вещь?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ClothService().deleteCloth(_cloth.id);
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
    final imageToShow = _cloth.processedImageUrl ?? _cloth.imageUrl;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _openEditSheet,
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _delete,
                tooltip: 'Удалить',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey[100],
                child: CachedNetworkImage(
                  imageUrl: imageToShow,
                  fit: BoxFit.contain,
                  placeholder: (ctx, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (ctx, url, err) =>
                      const Center(child: Icon(Icons.image_not_supported, size: 64)),
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cloth.name != null && _cloth.name!.isNotEmpty) ...[
                              Text(
                                _cloth.name!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (_cloth.category != null)
                              Text(
                                _cloth.category!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _cloth.name != null
                                      ? Colors.grey[600]
                                      : null,
                                  fontWeight: _cloth.name == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      _FavoriteButton(cloth: _cloth, onChanged: (c) => setState(() => _cloth = c)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: _cloth.typeLabel, icon: Icons.checkroom_outlined),
                      _InfoChip(label: _cloth.eventLabel, icon: Icons.event_outlined),
                      if (_cloth.season != null)
                        _InfoChip(label: _cloth.seasonLabel, icon: Icons.wb_sunny_outlined),
                    ],
                  ),

                  if (_cloth.brandNames != null && _cloth.brandNames!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _DetailRow(icon: Icons.label_outline, label: 'Бренд', value: _cloth.brandNames!),
                  ],

                  if (_cloth.size != null && _cloth.size!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.straighten_outlined, label: 'Размер', value: _cloth.size!),
                  ],

                  if (_cloth.descriptions != null && _cloth.descriptions!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Описание',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text(_cloth.descriptions!, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Добавлено ${_formatDate(_cloth.createdAt)}',
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
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}



class _FavoriteButton extends StatefulWidget {
  final Cloth cloth;
  final ValueChanged<Cloth> onChanged;

  const _FavoriteButton({required this.cloth, required this.onChanged});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final updated = await ClothService()
          .toggleFavorite(widget.cloth.id, !widget.cloth.isFavorite);
      widget.onChanged(updated);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      icon: Icon(
        widget.cloth.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: widget.cloth.isFavorite ? Colors.red : null,
        size: 28,
      ),
      onPressed: _toggle,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}



class _EditClothSheet extends StatefulWidget {
  final Cloth cloth;

  const _EditClothSheet({required this.cloth});

  @override
  State<_EditClothSheet> createState() => _EditClothSheetState();
}

class _EditClothSheetState extends State<_EditClothSheet> {
  final ClothService _service = ClothService();
  bool _saving = false;

  late ClothingCategory? _selectedCategory;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _descController;
  late String _selectedEvent;
  late String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.cloth.category != null
        ? ClothingCategories.findByName(widget.cloth.category!)
        : null;
    _nameController = TextEditingController(text: widget.cloth.name ?? '');
    _brandController = TextEditingController(text: widget.cloth.brandNames ?? '');
    _descController = TextEditingController(text: widget.cloth.descriptions ?? '');
    _selectedEvent = widget.cloth.event;
    _selectedSeason = widget.cloth.season;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openCategoryPicker() async {
    final result = await showModalBottomSheet<ClothingCategory>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CategoryPickerSheet(),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _service.updateCloth(
        widget.cloth.id,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        category: _selectedCategory?.name,
        type: _selectedCategory?.type,
        brandNames: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        descriptions: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        event: _selectedEvent,
        season: _selectedSeason,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2)),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Редактировать',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                  
                  GestureDetector(
                    onTap: _openCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedCategory == null
                              ? Colors.grey[400]!
                              : Theme.of(context).colorScheme.primary,
                          width: _selectedCategory == null ? 1 : 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined,
                              color: _selectedCategory == null
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedCategory == null
                                ? Text('Категория',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Категория',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.primary)),
                                      Text(_selectedCategory!.name,
                                          style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  const Text('Событие', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 16),

                  
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      hintText: 'Например: Любимая белая рубашка',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Бренд',
                      hintText: 'Nike, Zara, H&M...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Сезон',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSeason,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Не указан')),
                        ...List.generate(
                          Cloth.seasons.length,
                          (i) => DropdownMenuItem(
                            value: Cloth.seasons[i],
                            child: Text(Cloth.seasonLabels[i]),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedSeason = v),
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Дополнительная информация...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
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



class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet();

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchController = TextEditingController();
  List<ClothingCategory> _filtered = ClothingCategories.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
        _filtered = ClothingCategories.search(_query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('Категория',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск категории...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: isSearching ? _buildFlatList(_filtered) : _buildGroupedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final groups = ClothingCategories.groups;
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (ctx, gi) {
        final group = groups[gi];
        final cats = ClothingCategories.byGroup(group);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(group,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey[600],
                      letterSpacing: 0.5)),
            ),
            ...cats.map((c) => _buildTile(c)),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(List<ClothingCategory> cats) {
    if (cats.isEmpty) {
      return const Center(
          child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: cats.length,
      itemBuilder: (ctx, i) => _buildTile(cats[i]),
    );
  }

  Widget _buildTile(ClothingCategory cat) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(cat.name),
      subtitle: Text(cat.groupName, style: const TextStyle(fontSize: 11)),
      onTap: () => Navigator.pop(context, cat),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

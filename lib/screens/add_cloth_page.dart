import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/clothing_categories.dart';
import '../models/cloth.dart';
import '../services/cloth_service.dart';

class AddClothPage extends StatefulWidget {
  const AddClothPage({super.key});

  @override
  State<AddClothPage> createState() => _AddClothPageState();
}

class _AddClothPageState extends State<AddClothPage> {
  final ClothService _clothService = ClothService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  
  Uint8List? _previewBytes;
  String? _imageUrl;
  String? _processedImageUrl;
  bool _isProcessing = false;
  bool _processingFailed = false;
  bool _isSaving = false;

  
  ClothingCategory? _selectedCategory;
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedEvent = 'casual';
  String? _selectedSeason;

  

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes = bytes;
      _imageUrl = null;
      _processedImageUrl = null;
      _processingFailed = false;
      _isProcessing = true;
    });
    _processPhoto(bytes, picked.name);
  }

  Future<void> _processPhoto(Uint8List bytes, String filename) async {
    try {
      final result = await _clothService.processClothImage(
        imageBytes: bytes,
        filename: filename,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = result['imageUrl'];
        _processedImageUrl = result['processedImageUrl'];
        _isProcessing = false;
        _processingFailed = result['processedImageUrl'] == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingFailed = true;
      });
    }
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
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дождитесь загрузки фото')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _clothService.createClothFromUrls(
        imageUrl: _imageUrl!,
        processedImageUrl: _processedImageUrl,
        type: _selectedCategory!.type,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        category: _selectedCategory!.name,
        brandNames: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        descriptions: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        event: _selectedEvent,
        season: _selectedSeason,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вещь добавлена в гардероб')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isProcessing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить вещь'),
        actions: [
          TextButton(
            onPressed: busy ? null : _save,
            child: busy
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 20),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildEventSection(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Любимая белая рубашка',
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Бренд',
                hintText: 'Nike, Zara, H&M...',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: const InputDecoration(
                labelText: 'Сезон',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Дополнительная информация...',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Сохранить', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildPreview(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_isProcessing)
          _chip(Icons.auto_fix_high, 'Удаляем фон...', Colors.blue)
        else if (_processedImageUrl != null)
          _chip(Icons.check_circle_outline, 'Фон удалён', Colors.green)
        else if (_processingFailed && _imageUrl != null)
          _chip(Icons.info_outline, 'Фон не удалён — сохранён оригинал', Colors.orange),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Галерея'),
                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Камера'),
                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_previewBytes == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Выберите фото вещи', style: TextStyle(color: Colors.grey[500])),
        ],
      );
    }
    if (_isProcessing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_previewBytes!, fit: BoxFit.contain),
          Container(
            color: Colors.black38,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text('Удаляем фон...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
    }
    if (_processedImageUrl != null) {
      return Image.network(
        _processedImageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : Stack(fit: StackFit.expand, children: [
                Image.memory(_previewBytes!, fit: BoxFit.contain),
                const Center(child: CircularProgressIndicator()),
              ]),
        errorBuilder: (ctx, e, s) => Image.memory(_previewBytes!, fit: BoxFit.contain),
      );
    }
    return Image.memory(_previewBytes!, fit: BoxFit.contain);
  }

  Widget _buildCategoryField() {
    return GestureDetector(
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
                color: _selectedCategory == null ? Colors.grey : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCategory == null
                  ? Text('Категория *',
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
    );
  }

  Widget _buildEventSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
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
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Поиск категории...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          Expanded(
            child: isSearching
                ? _buildFlatList(_filtered)
                : _buildGroupedList(),
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
              child: Text(
                group,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
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
        child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: cats.length,
      itemBuilder: (ctx, i) => _buildTile(cats[i]),
    );
  }

  Widget _buildTile(ClothingCategory cat) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Text(cat.name),
      subtitle: Text(cat.groupName,
          style: const TextStyle(fontSize: 11)),
      onTap: () => Navigator.pop(context, cat),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

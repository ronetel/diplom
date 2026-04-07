import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  XFile? _pickedFile;
  List<int>? _imageBytes;
  bool _isLoading = false;

  // Controllers
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _sizeController = TextEditingController();

  // Selected values
  String _selectedType = 'top';
  String _selectedEvent = 'casual';
  String? _selectedSeason;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveCloth() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите изображение')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _pickedFile!.readAsBytes();
      await _clothService.createClothFromBytes(
        imageBytes: bytes,
        filename: _pickedFile!.name,
        type: _selectedType,
        brandNames: _brandController.text.trim(),
        descriptions: _descriptionController.text.trim(),
        event: _selectedEvent,
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        material: _materialController.text.trim().isEmpty
            ? null
            : _materialController.text.trim(),
        season: _selectedSeason,
        size: _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вещь добавлена в гардероб')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить вещь'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCloth,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes! as dynamic,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите чтобы выбрать фото',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Галерея'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _takePhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Камера'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Type selection
            const Text('Тип одежды *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(Cloth.types.length, (index) {
                return ChoiceChip(
                  label: Text(Cloth.typeLabels[index]),
                  selected: _selectedType == Cloth.types[index],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = Cloth.types[index]);
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Event selection
            const Text('Событие', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(Cloth.events.length, (index) {
                return ChoiceChip(
                  label: Text(Cloth.eventLabels[index]),
                  selected: _selectedEvent == Cloth.events[index],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedEvent = Cloth.events[index]);
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Бренд',
                hintText: 'Например: Nike, Zara, H&M',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Дополнительная информация о вещи',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Color
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Цвет',
                hintText: 'Например: Красный, Синий',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Material
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: 'Материал',
                hintText: 'Например: Хлопок, Шерсть',
                prefixIcon: Icon(Icons.texture_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Season
            DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: const InputDecoration(
                labelText: 'Сезон',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Не указан'),
                ),
                ...List.generate(Cloth.seasons.length, (index) {
                  return DropdownMenuItem(
                    value: Cloth.seasons[index],
                    child: Text(Cloth.seasonLabels[index]),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedSeason = value),
            ),
            const SizedBox(height: 16),

            // Size
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Размер',
                hintText: 'Например: M, L, 42',
                prefixIcon: Icon(Icons.straighten_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCloth,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Сохранить',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    super.dispose();
  }
}

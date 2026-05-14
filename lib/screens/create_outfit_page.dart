import 'package:flutter/material.dart';
import '../models/cloth.dart';
import '../services/cloth_service.dart';
import '../services/outfit_service.dart';

class CreateOutfitPage extends StatefulWidget {
  const CreateOutfitPage({super.key});

  @override
  State<CreateOutfitPage> createState() => _CreateOutfitPageState();
}

class _CreateOutfitPageState extends State<CreateOutfitPage> {
  final ClothService _clothService = ClothService();
  final OutfitService _outfitService = OutfitService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Cloth> _clothes = [];
  List<int> _selectedClothes = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  String _selectedEvent = 'casual';
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  Future<void> _loadClothes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _clothService.getMyClothes();
      setState(() {
        _clothes = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _createOutfit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название образа')),
      );
      return;
    }

    if (_selectedClothes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну вещь')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _outfitService.createOutfit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        event: _selectedEvent,
        season: _selectedSeason,
        clothesIds: _selectedClothes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Образ создан')),
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
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleClothSelection(int clothId) {
    setState(() {
      if (_selectedClothes.contains(clothId)) {
        _selectedClothes.remove(clothId);
      } else {
        _selectedClothes.add(clothId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать образ'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _createOutfit,
            child: _isSaving
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClothes,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _clothes.isEmpty
                  ? const Center(
                      child: Text(
                        'У вас пока нет вещей.\nСначала добавьте вещи в гардероб!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Название образа *',
                            hintText: 'Например: Летний прогулочный',
                          ),
                        ),
                        const SizedBox(height: 16),

                        
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Описание',
                            hintText: 'Дополнительная информация',
                          ),
                        ),
                        const SizedBox(height: 16),

                        
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

                        
                        DropdownButtonFormField<String>(
                          value: _selectedSeason,
                          decoration: const InputDecoration(
                            labelText: 'Сезон',
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
                        const SizedBox(height: 24),

                        
                        Text(
                          'Выбрано вещей: ${_selectedClothes.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        
                        const Text(
                          'Выберите вещи для образа:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _clothes.length,
                          itemBuilder: (context, index) {
                            final cloth = _clothes[index];
                            final isSelected = _selectedClothes.contains(cloth.id);
                            return _buildClothSelectableCard(cloth, isSelected);
                          },
                        ),
                      ],
                    ),
    );
  }

  Widget _buildClothSelectableCard(Cloth cloth, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleClothSelection(cloth.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(cloth.imageUrl),
                fit: BoxFit.cover,
              ),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : null,
            ),
          ),
          
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
          
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cloth.typeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

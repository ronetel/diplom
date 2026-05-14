import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/cloth.dart';
import '../services/cloth_service.dart';
import 'add_cloth_page.dart';
import 'cloth_detail_page.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  final ClothService _clothService = ClothService();
  List<Cloth> _clothes = [];
  bool _isLoading = true;
  String? _error;

  
  String _selectedType = 'all';
  String _selectedEvent = 'all';
  bool _showFilters = false;

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
      final response = await _clothService.getMyClothes(
        type: _selectedType == 'all' ? null : _selectedType,
        event: _selectedEvent == 'all' ? null : _selectedEvent,
      );
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой гардероб'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClothPage()),
              );
              _loadClothes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          
          if (_showFilters) _buildFilters(),
          
          Expanded(
            child: _isLoading
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
                              'Ваш гардероб пуст.\nДобавьте первую вещь!',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadClothes,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _clothes.length,
                              itemBuilder: (context, index) {
                                final cloth = _clothes[index];
                                return _buildClothCard(cloth);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Text('Тип одежды:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'Все', _selectedType, (v) {
                setState(() => _selectedType = v);
                _loadClothes();
              }),
              ...List.generate(Cloth.types.length, (index) {
                return _buildFilterChip(
                  Cloth.types[index],
                  Cloth.typeLabels[index],
                  _selectedType,
                  (v) {
                    setState(() => _selectedType = v);
                    _loadClothes();
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text('Событие:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'Все', _selectedEvent, (v) {
                setState(() => _selectedEvent = v);
                _loadClothes();
              }),
              ...List.generate(Cloth.events.length, (index) {
                return _buildFilterChip(
                  Cloth.events[index],
                  Cloth.eventLabels[index],
                  _selectedEvent,
                  (v) {
                    setState(() => _selectedEvent = v);
                    _loadClothes();
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String selectedValue,
    Function(String) onSelected,
  ) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }

  Widget _buildClothCard(Cloth cloth) {
    final imageToShow = cloth.processedImageUrl ?? cloth.imageUrl;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClothDetailPage(cloth: cloth)),
        );
        
        if (result != null) _loadClothes();
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            
            CachedNetworkImage(
              imageUrl: imageToShow,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cloth.name ?? cloth.category ?? cloth.brandNames ?? 'Без названия',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cloth.eventLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (cloth.isFavorite)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

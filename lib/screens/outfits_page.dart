import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../services/outfit_service.dart';
import 'outfit_canvas_page.dart';
import 'outfit_detail_page.dart';

class OutfitsPage extends StatefulWidget {
  const OutfitsPage({super.key});

  @override
  State<OutfitsPage> createState() => _OutfitsPageState();
}

class _OutfitsPageState extends State<OutfitsPage> {
  final OutfitService _service = OutfitService();
  List<Outfit> _outfits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final r = await _service.getMyOutfits();
      setState(() {
        _outfits = r.items;
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
        title: const Text('Мои образы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать образ',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const OutfitCanvasPage()),
              );
              if (created == true) _loadOutfits();
            },
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
                      ElevatedButton(onPressed: _loadOutfits, child: const Text('Повторить')),
                    ],
                  ),
                )
              : _outfits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checkroom_outlined, size: 72, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Образов пока нет.\nСоздайте первый!',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const OutfitCanvasPage()),
                              );
                              if (created == true) _loadOutfits();
                            },
                            icon: const Icon(Icons.brush_outlined),
                            label: const Text('Редактор образа'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOutfits,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _outfits.length,
                        itemBuilder: (ctx, i) => _buildCard(_outfits[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Outfit outfit) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OutfitDetailPage(outfit: outfit)),
        );
        _loadOutfits();
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            
            outfit.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: outfit.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => _placeholder(),
                    errorWidget: (c, u, e) => _emptyCanvas(),
                  )
                : _emptyCanvas(),

            
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
                      outfit.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          outfit.eventLabel,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11),
                        ),
                        if (outfit.weatherLabel.isNotEmpty) ...[
                          Text(' · ',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11)),
                          Text(
                            outfit.weatherLabel,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            
            if (outfit.isFavorite)
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

  Widget _placeholder() => Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _emptyCanvas() => Container(
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 6),
            Text('Нет фото', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../services/post_service.dart';
import '../services/outfit_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final PostService _postService = PostService();
  final OutfitService _outfitService = OutfitService();
  final _contentController = TextEditingController();

  List<Outfit> _outfits = [];
  int? _selectedOutfitId;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() => _isLoading = true);
    try {
      final response = await _outfitService.getMyOutfits();
      setState(() {
        _outfits = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedOutfitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте текст или выберите образ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _postService.createPost(
        outfitId: _selectedOutfitId,
        content: _contentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пост опубликован')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пост'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _createPost,
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
                    'Опубликовать',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Поделитесь своим образом...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                
                const Text(
                  'Прикрепить образ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_outfits.isEmpty)
                  const Text('У вас пока нет сохраненных образов.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _outfits.length,
                    itemBuilder: (context, index) {
                      final outfit = _outfits[index];
                      final isSelected = outfit.id == _selectedOutfitId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: outfit.clothes != null && outfit.clothes!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    outfit.clothes!.first.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          title: Text(outfit.displayName),
                          subtitle: Text(outfit.eventLabel),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedOutfitId =
                                  isSelected ? null : outfit.id;
                            });
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/outfit.dart';
import '../services/post_service.dart';
import '../services/outfit_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final OutfitService _outfitService = OutfitService();
  final ApiService _apiService = ApiService();
  late Future<Post> _postFuture;
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _postFuture = _postService.getPostById(widget.postId);
    _commentsFuture = _postService.getComments(widget.postId);
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isAddingComment = true);
    try {
      await _postService.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      setState(() {
        _commentsFuture = _postService.getComments(widget.postId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _postService.deleteComment(widget.postId, commentId);
      setState(() {
        _commentsFuture = _postService.getComments(widget.postId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      await _postService.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пост удалён')),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  void _showEditPostDialog(Post post) {
    final contentController = TextEditingController(text: post.content);
    final tagsController = TextEditingController(
      text: post.tags.map((t) => '#$t').join(' '),
    );
    final List<File> newImages = [];
    List<String> existingImages = List.from(post.imageUrls);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактировать пост'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Текст поста...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    hintText: '#тег #стиль',
                    labelText: 'Теги',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (existingImages.isNotEmpty || newImages.isNotEmpty) ...[
                  const Text('Фото:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: existingImages.length + newImages.length,
                      itemBuilder: (ctx, i) {
                        final isExisting = i < existingImages.length;
                        final image = isExisting
                            ? existingImages[i]
                            : newImages[i - existingImages.length];
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: isExisting
                                      ? NetworkImage(image as String)
                                      : FileImage(image as File)
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setDialogState(() {
                                  if (isExisting) {
                                    existingImages.removeAt(i);
                                  } else {
                                    newImages.removeAt(i - existingImages.length);
                                  }
                                }),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage(imageQuality: 85);
                    if (picked.isNotEmpty) {
                      setDialogState(() {
                        newImages.addAll(picked.map((x) => File(x.path)));
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Добавить фото'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        
                        final uploadedUrls = <String>[];
                        for (final file in newImages) {
                          final bytes = await file.readAsBytes();
                          final result = await _apiService.uploadBytes(
                            '/upload/uploadPostImage',
                            bytes,
                            'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          uploadedUrls.add(result['imageUrl'] as String);
                        }

                        final tags = tagsController.text
                            .split(' ')
                            .map((t) => t.replaceAll('#', '').trim())
                            .where((t) => t.isNotEmpty)
                            .toList();

                        await _postService.updatePost(
                          post.id,
                          content: contentController.text.trim().isEmpty
                              ? null
                              : contentController.text.trim(),
                          imageUrls: [...existingImages, ...uploadedUrls],
                          tags: tags,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          _refreshPost();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Пост обновлён')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshPost() {
    setState(() {
      _postFuture = _postService.getPostById(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Пост')),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _postFuture = _postService.getPostById(widget.postId);
                    }),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final post = snapshot.data!;
          final currentUser = context.watch<AuthProvider>().currentUser;
          final isOwnPost = currentUser?.id == post.authorId;

          return ListView(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: post.authorAvatarUrl != null
                            ? NetworkImage(post.authorAvatarUrl!)
                            : null,
                        child: post.authorAvatarUrl == null
                            ? Text(post.authorUsername?[0].toUpperCase() ?? 'U')
                            : null,
                      ),
                      title: Text(post.authorUsername ?? 'Пользователь'),
                      subtitle: Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: isOwnPost
                          ? PopupMenuButton<String>(
                              tooltip: 'Действия',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditPostDialog(post);
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Удалить пост?'),
                                      content: const Text(
                                          'Это действие нельзя отменить.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Отмена'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deletePost(post);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Удалить'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Редактировать'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Удалить',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                    
                    if (post.content != null && post.content!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(post.content!),
                      ),
                    
                    if (post.imageUrls.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          itemCount: post.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: post.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Center(child: Icon(Icons.error)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    if (post.outfit != null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Образ: ${post.outfit!.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (post.outfit!.clothes != null &&
                                post.outfit!.clothes!.isNotEmpty)
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.outfit!.clothes!.length,
                                  itemBuilder: (context, index) {
                                    final cloth = post.outfit!.clothes![index];
                                    return Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(
                                        right: 8,
                                        top: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        image: DecorationImage(
                                          image: NetworkImage(cloth.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            post.isLiked == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post.isLiked == true ? Colors.red : null,
                          ),
                          onPressed: () {
                            
                          },
                        ),
                        Text('${post.likesCount}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.comment_outlined),
                        Text('${post.commentsCount}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Комментарии (${post.commentsCount})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: currentUser.avatarUrl != null
                            ? NetworkImage(currentUser.avatarUrl!)
                            : null,
                        child: currentUser.avatarUrl == null
                            ? Text(currentUser.username[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Добавить комментарий...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: _isAddingComment
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: _addComment,
                                  ),
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                    ],
                  ),
                ),
              
              FutureBuilder<List<Comment>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ошибка загрузки комментариев: ${snapshot.error}',
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Нет комментариев'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isAuthor = currentUser?.id == comment.authorId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.authorAvatarUrl != null
                              ? NetworkImage(comment.authorAvatarUrl!)
                              : null,
                          child: comment.authorAvatarUrl == null
                              ? Text(
                                  comment.authorUsername?[0].toUpperCase() ??
                                      'U',
                                )
                              : null,
                        ),
                        title: Text(comment.authorUsername ?? 'Пользователь'),
                        subtitle: Text(comment.content),
                        trailing: isAuthor
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Удалить комментарий?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Отмена'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteComment(comment.id);
                                          },
                                          child: const Text('Удалить'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} д. назад';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ч. назад';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}

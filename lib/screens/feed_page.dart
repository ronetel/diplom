import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/outfit.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/outfit_service.dart';
import '../services/post_service.dart';
import 'post_detail_page.dart';
import 'user_profile_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  late TabController _tabController;

  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];
  bool _isLoadingAll = true;
  bool _isLoadingFollowing = false;
  bool _followingEverLoaded = false;
  String? _errorAll;
  String? _errorFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Перезагружаем подписки каждый раз при переключении на вкладку.
  /// Это покрывает случай «подписался на кого-то → вернулся → нажал «Подписки»».
  void _onTabChanged() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _loadFollowing();
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoadingAll = true;
      _errorAll = null;
    });
    try {
      final r = await _postService.getFeed();
      setState(() {
        _allPosts = r.items;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        _errorAll = e.toString();
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoadingFollowing = true;
      _errorFollowing = null;
    });
    try {
      final r = await _postService.getFeed(feed: 'following');
      setState(() {
        _followingPosts = r.items;
        _isLoadingFollowing = false;
        _followingEverLoaded = true;
      });
    } catch (e) {
      setState(() {
        _errorFollowing = e.toString();
        _isLoadingFollowing = false;
      });
    }
  }

  Future<void> _toggleLike(Post post, bool isFollowingTab) async {
    try {
      if (post.isLiked == true) {
        await _postService.unlikePost(post.id);
      } else {
        await _postService.likePost(post.id);
      }
      if (isFollowingTab) {
        _loadFollowing();
      } else {
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Поиск пользователей',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _UserSearchSheet(
                onUserTap: (userId) {
                  Navigator.pop(context);
                  _openUserProfile(userId);
                },
              ),
            ),
          ),
          if (currentUser != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: currentUser.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: currentUser.avatarUrl != null
                      ? NetworkImage(currentUser.avatarUrl!)
                      : null,
                  child: currentUser.avatarUrl == null
                      ? Text(
                          currentUser.username.isNotEmpty
                              ? currentUser.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        )
                      : null,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Подписки'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(
            posts: _allPosts,
            isLoading: _isLoadingAll,
            error: _errorAll,
            onRefresh: _loadAll,
            isFollowingTab: false,
          ),
          _buildFeedList(
            posts: _followingPosts,
            isLoading: _isLoadingFollowing || !_followingEverLoaded,
            error: _errorFollowing,
            onRefresh: _loadFollowing,
            isFollowingTab: true,
            emptyMessage:
                'Здесь будут посты людей,\nна которых вы подписаны',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedList({
    required List<Post> posts,
    required bool isLoading,
    required String? error,
    required Future<void> Function() onRefresh,
    required bool isFollowingTab,
    String emptyMessage =
        'Лента пуста.\nСтаньте первым кто поделится образом!',
  }) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRefresh, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: 400,
              child: Center(
                child: Text(emptyMessage, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (ctx, i) => _buildPostCard(posts[i], isFollowingTab),
      ),
    );
  }

  Widget _buildPostCard(Post post, bool isFollowingTab) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isOwnPost = currentUser?.id == post.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(post.authorId),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: post.authorAvatarUrl != null
                        ? NetworkImage(post.authorAvatarUrl!)
                        : null,
                    child: post.authorAvatarUrl == null
                        ? Text(
                            (post.authorUsername ?? 'U')[0].toUpperCase())
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(post.authorId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorUsername ?? 'Пользователь',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwnPost)
                  PopupMenuButton<String>(
                    tooltip: 'Действия',
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _postService.deletePost(post.id);
                        _loadAll();
                        _loadFollowing();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Удалить')),
                    ],
                  ),
              ],
            ),
          ),

          
          _buildPostMedia(post),

          
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.isLiked == true ? Colors.red : null,
                  ),
                  onPressed: () => _toggleLike(post, isFollowingTab),
                ),
                Text('${post.likesCount}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PostDetailPage(postId: post.id)),
                  ),
                ),
                Text('${post.commentsCount}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${post.authorUsername ?? ''} ',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.content!),
                  ],
                ),
              ),
            ),

          
          if (post.tags.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Wrap(
                spacing: 4,
                children: post.tags
                    .map((t) => Text('#$t',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13)))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(Post post) {
    
    if (post.imageUrls.length > 1) {
      return SizedBox(
        height: 320,
        child: PageView.builder(
          itemCount: post.imageUrls.length,
          itemBuilder: (ctx, i) => CachedNetworkImage(
            imageUrl: post.imageUrls[i],
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (ctx, url) =>
                Container(height: 320, color: Colors.grey[200]),
            errorWidget: (ctx, url, err) =>
                Container(height: 320, color: Colors.grey[200]),
          ),
        ),
      );
    }

    
    if (post.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: post.imageUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (ctx, url) =>
            Container(height: 300, color: Colors.grey[200]),
        errorWidget: (ctx, url, err) =>
            Container(height: 300, color: Colors.grey[200]),
      );
    }

    
    if (post.outfit != null) {
      final outfit = post.outfit!;
      if (outfit.thumbnailUrl != null) {
        return CachedNetworkImage(
          imageUrl: outfit.thumbnailUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (ctx, url) =>
              Container(height: 300, color: Colors.grey[200]),
          errorWidget: (ctx, url, err) =>
              Container(height: 300, color: Colors.grey[200]),
        );
      }
      
      if (outfit.clothes != null && outfit.clothes!.isNotEmpty) {
        return Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Образ: ${outfit.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: outfit.clothes!.length,
                  itemBuilder: (ctx, i) {
                    final cloth = outfit.clothes![i];
                    return Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _openUserProfile(int userId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)));
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatePostSheet(
        onPosted: () {
          _loadAll();
          _loadFollowing();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} д. назад';
    if (diff.inHours > 0) return '${diff.inHours} ч. назад';
    if (diff.inMinutes > 0) return '${diff.inMinutes} мин. назад';
    return 'Только что';
  }
}



class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _CreatePostSheet({required this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final PostService _postService = PostService();
  final OutfitService _outfitService = OutfitService();
  final ApiService _apiService = ApiService();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _picker = ImagePicker();

  List<Outfit> _outfits = [];
  int? _selectedOutfitId;
  final List<File> _selectedImages = [];
  bool _isLoadingOutfits = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    try {
      final r = await _outfitService.getMyOutfits();
      setState(() {
        _outfits = r.items;
        _isLoadingOutfits = false;
      });
    } catch (_) {
      setState(() => _isLoadingOutfits = false);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked.map((x) => File(x.path)));
        });
      }
    } else {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _selectedImages.add(File(picked.path)));
      }
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty &&
        _selectedOutfitId == null &&
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте текст, фото или образ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      
      final imageUrls = <String>[];
      for (final file in _selectedImages) {
        final bytes = await file.readAsBytes();
        final result = await _apiService.uploadBytes(
          '/upload/uploadPostImage',
          bytes,
          'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageUrls.add(result['imageUrl'] as String);
      }

      final tags = _tagsController.text
          .split(' ')
          .map((t) => t.replaceAll('#', '').trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await _postService.createPost(
        outfitId: _selectedOutfitId,
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        tags: tags,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPosted();
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Новый пост',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Опубликовать'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Поделитесь своим образом...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: '#стиль #лето #casual',
                      labelText: 'Теги',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Галерея'),
                          onPressed: () => _pickImages(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Камера'),
                          onPressed: () => _pickImages(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),

                  
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(i)),
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
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text('Прикрепить образ:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  
                  if (_isLoadingOutfits)
                    const Center(child: CircularProgressIndicator())
                  else if (_outfits.isEmpty)
                    Text('Нет сохранённых образов',
                        style: TextStyle(color: Colors.grey[600]))
                  else
                    ...(_outfits.map((outfit) {
                      final isSelected = outfit.id == _selectedOutfitId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          dense: true,
                          leading: outfit.clothes != null &&
                                  outfit.clothes!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    outfit.clothes!.first.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          title: Text(outfit.displayName),
                          subtitle: Text(outfit.eventLabel,
                              style: const TextStyle(fontSize: 12)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary)
                              : null,
                          onTap: () => setState(() => _selectedOutfitId =
                              isSelected ? null : outfit.id),
                        ),
                      );
                    })),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}



class _UserSearchSheet extends StatefulWidget {
  final ValueChanged<int> onUserTap;
  const _UserSearchSheet({required this.onUserTap});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final FollowService _followService = FollowService();
  final _searchController = TextEditingController();
  List<User> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onChanged);
  }

  void _onChanged() {
    final q = _searchController.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final users = await _followService.searchUsers(q);
      if (mounted && _lastQuery == q) {
        setState(() => _results = users);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Поиск по нику...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _lastQuery.length < 2
                              ? 'Введите минимум 2 символа'
                              : 'Ничего не найдено',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final user = _results[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(user.username[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user.username),
                            onTap: () => widget.onUserTap(user.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

class ModeratorPanelPage extends StatefulWidget {
  const ModeratorPanelPage({super.key});

  @override
  State<ModeratorPanelPage> createState() => _ModeratorPanelPageState();
}

class _ModeratorPanelPageState extends State<ModeratorPanelPage> {
  int _selectedTab = 0;

  // Posts tab state
  final _postService = PostService();
  List<Post> _posts = [];
  bool _postsLoading = true;
  String? _postsError;

  // Users tab state
  final _authService = AuthService();
  List<User> _users = [];
  bool _usersLoading = true;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUsers();
  }

  Future<void> _loadPosts() async {
    setState(() { _postsLoading = true; _postsError = null; });
    try {
      final response = await _postService.getFeed(limit: 100);
      setState(() { _posts = response.items; _postsLoading = false; });
    } catch (e) {
      setState(() { _postsError = e.toString(); _postsLoading = false; });
    }
  }

  Future<void> _loadUsers() async {
    setState(() { _usersLoading = true; _usersError = null; });
    try {
      final response = await _authService.getAllUsers(limit: 100);
      setState(() { _users = response.items; _usersLoading = false; });
    } catch (e) {
      setState(() { _usersError = e.toString(); _usersLoading = false; });
    }
  }

  Future<void> _hidePost(Post post) async {
    try {
      await _postService.hidePost(post.id, !post.isHidden);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(post.isHidden ? 'Пост показан' : 'Пост скрыт'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _banUser(User user) async {
    if (user.isBanned) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.unbanUser(user.id);
      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь разблокирован')),
          );
        }
      }
      return;
    }

    final banType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заблокировать ${user.username}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('24 часа'), onTap: () => Navigator.pop(context, 'temporary')),
            ListTile(title: const Text('На неделю'), onTap: () => Navigator.pop(context, 'period')),
            ListTile(title: const Text('Навсегда'), onTap: () => Navigator.pop(context, 'permanent')),
          ],
        ),
      ),
    );
    if (banType == null || !mounted) return;

    DateTime? banUntil;
    if (banType == 'temporary') banUntil = DateTime.now().add(const Duration(days: 1));
    if (banType == 'period') banUntil = DateTime.now().add(const Duration(days: 7));

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.banUser(
      user.id, banType,
      banUntil: banUntil?.toIso8601String(),
      reason: 'Заблокирован модератором',
    );
    if (success) {
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь заблокирован')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель модератора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _loadPosts(); _loadUsers(); },
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTab(0, 'Посты', Icons.post_add)),
              Expanded(child: _buildTab(1, 'Пользователи', Icons.people)),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedTab == 0 ? _buildPostsTab() : _buildUsersTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_postsLoading) return const Center(child: CircularProgressIndicator());
    if (_postsError != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ошибка: $_postsError'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadPosts, child: const Text('Повторить')),
        ],
      ));
    }
    if (_posts.isEmpty) {
      return const Center(child: Text('Постов нет'));
    }
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: post.isHidden ? Colors.red.withOpacity(0.08) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: post.authorAvatarUrl != null
                    ? NetworkImage(post.authorAvatarUrl!) : null,
                child: post.authorAvatarUrl == null
                    ? Text((post.authorUsername ?? 'U')[0].toUpperCase()) : null,
              ),
              title: Text(
                post.authorUsername ?? 'Пользователь',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.content != null && post.content!.isNotEmpty)
                    Text(post.content!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (post.isHidden) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red, borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Скрыт', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ]),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  post.isHidden ? Icons.visibility : Icons.visibility_off,
                  color: post.isHidden ? Colors.green : Colors.red,
                ),
                tooltip: post.isHidden ? 'Показать' : 'Скрыть',
                onPressed: () => _hidePost(post),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_usersLoading) return const Center(child: CircularProgressIndicator());
    if (_usersError != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ошибка: $_usersError'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadUsers, child: const Text('Повторить')),
        ],
      ));
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Пользователей нет'));
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: user.isBanned ? Colors.red.withOpacity(0.08) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _roleColor(user.role),
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(user.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)) : null,
              ),
              title: Text(user.username),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role), borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_roleLabel(user.role),
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    if (user.isBanned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red, borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Заблокирован',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ]),
                ],
              ),
              trailing: user.role == 'admin'
                  ? null
                  : IconButton(
                      icon: Icon(
                        user.isBanned ? Icons.lock_open : Icons.block,
                        color: user.isBanned ? Colors.green : Colors.red,
                      ),
                      tooltip: user.isBanned ? 'Разблокировать' : 'Заблокировать',
                      onPressed: () => _banUser(user),
                    ),
            ),
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'moderator': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Админ';
      case 'moderator': return 'Модератор';
      default: return 'Пользователь';
    }
  }
}

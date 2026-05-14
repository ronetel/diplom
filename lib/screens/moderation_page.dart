import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../models/user.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _getTabCount(),
      vsync: this,
    );
  }

  int _getTabCount() {
    final role =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.role;
    return role == 'admin' ? 4 : 3;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Модерация'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Посты'),
            const Tab(text: 'Комментарии'),
            const Tab(text: 'Пользователи'),
            if (isAdmin) const Tab(text: 'Логи'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostsTab(isAdmin: isAdmin),
          _CommentsTab(isAdmin: isAdmin),
          _UsersTab(isAdmin: isAdmin),
          if (isAdmin) const _LogsTab(),
        ],
      ),
    );
  }
}




class _PostsTab extends StatefulWidget {
  final bool isAdmin;
  const _PostsTab({required this.isAdmin});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final _service = AdminService();
  final _searchCtrl = TextEditingController();
  List<AdminPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String search = ''}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getPosts(search: search);
      setState(() { _posts = result.posts; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _toggleHide(AdminPost post) async {
    String? reason;
    if (!post.isHidden) {
      reason = await _showReasonDialog(context, 'Причина скрытия (необязательно)');
      if (reason == null) return;
    }
    try {
      await _service.hidePost(post.id, !post.isHidden, reason: reason?.isEmpty == true ? null : reason);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _editContent(AdminPost post) async {
    final ctrl = TextEditingController(text: post.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать пост'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _service.editPostContent(post.id, result);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(AdminPost post) async {
    final ok = await _showConfirmDialog(context, 'Удалить пост?',
        'Это действие необратимо. Пост и все его комментарии будут удалены.');
    if (!ok) return;
    try {
      await _service.deletePost(post.id);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Поиск по автору или тексту',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load();
                      })
                  : null,
            ),
            onSubmitted: (v) => _load(search: v),
            onChanged: (v) {
              if (v.isEmpty) _load();
              setState(() {});
            },
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(child: Text('Нет постов'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(search: _searchCtrl.text),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _posts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final post = _posts[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: CircleAvatar(
              backgroundImage: post.authorAvatarUrl != null
                  ? NetworkImage(post.authorAvatarUrl!)
                  : null,
              child: post.authorAvatarUrl == null
                  ? Text(post.authorUsername[0].toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    post.authorUsername,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (post.isHidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('скрыт',
                        style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.content != null && post.content!.isNotEmpty)
                  Text(
                    post.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  '${post.likesCount} лайков · ${post.commentsCount} комментариев · '
                  '${_formatDate(post.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (post.reportReason != null)
                  Text('Причина: ${post.reportReason}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Действия',
              onSelected: (v) {
                if (v == 'hide') _toggleHide(post);
                if (v == 'edit') _editContent(post);
                if (v == 'delete') _delete(post);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'hide',
                  child: Text(post.isHidden ? 'Показать' : 'Скрыть'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}




class _CommentsTab extends StatefulWidget {
  final bool isAdmin;
  const _CommentsTab({required this.isAdmin});

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  final _service = AdminService();
  final _searchCtrl = TextEditingController();
  List<AdminComment> _comments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String search = ''}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getComments(search: search);
      setState(() { _comments = result.comments; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _toggleHide(AdminComment c) async {
    try {
      await _service.hideComment(c.id, !c.isHidden);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _edit(AdminComment c) async {
    final ctrl = TextEditingController(text: c.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать комментарий'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _service.editComment(c.id, result);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(AdminComment c) async {
    final ok = await _showConfirmDialog(context, 'Удалить комментарий?', c.content);
    if (!ok) return;
    try {
      await _service.deleteComment(c.id);
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Поиск по автору или тексту',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchCtrl.clear(); _load(); })
                  : null,
            ),
            onSubmitted: (v) => _load(search: v),
            onChanged: (v) { if (v.isEmpty) _load(); setState(() {}); },
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_comments.isEmpty) return const Center(child: Text('Нет комментариев'));

    return RefreshIndicator(
      onRefresh: () => _load(search: _searchCtrl.text),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _comments.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = _comments[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: CircleAvatar(
              backgroundImage: c.authorAvatarUrl != null
                  ? NetworkImage(c.authorAvatarUrl!)
                  : null,
              child: c.authorAvatarUrl == null
                  ? Text(c.authorUsername[0].toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(c.authorUsername,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (c.isHidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('скрыт',
                        style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  'Пост #${c.postId} · ${_formatDate(c.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Действия',
              onSelected: (v) {
                if (v == 'hide') _toggleHide(c);
                if (v == 'edit') _edit(c);
                if (v == 'delete') _delete(c);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'hide',
                    child: Text(c.isHidden ? 'Показать' : 'Скрыть')),
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
        },
      ),
    );
  }
}




class _UsersTab extends StatefulWidget {
  final bool isAdmin;
  const _UsersTab({required this.isAdmin});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _service = AdminService();
  final _searchCtrl = TextEditingController();
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String? _roleFilter;

  static const _roleLabels = {
    'user': 'Пользователь',
    'moderator': 'Модератор',
    'admin': 'Администратор',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String search = ''}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getUsers(search: search, role: _roleFilter);
      setState(() { _users = result.users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _showBanDialog(User user) async {
    final reasonCtrl = TextEditingController();
    String? selectedDuration = '7d';
    DateTime? customDate;

    final durations = {
      '1d': '1 день',
      '7d': '7 дней',
      '30d': '30 дней',
      'perm': 'Навсегда',
      'custom': 'Выбрать дату...',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Заблокировать ${user.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Причина блокировки *',
                    border: OutlineInputBorder(),
                    hintText: 'Обязательное поле',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Срок блокировки:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: selectedDuration ?? '',
                  onChanged: (v) async {
                    if (v == 'custom') {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setDlgState(() {
                          customDate = picked;
                          selectedDuration = 'custom';
                        });
                      }
                    } else {
                      setDlgState(() { selectedDuration = v; customDate = null; });
                    }
                  },
                  child: Column(
                    children: durations.entries.map((e) => RadioListTile<String>(
                      value: e.key,
                      title: Text(e.value),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    )).toList(),
                  ),
                ),
                if (selectedDuration == 'custom' && customDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'До: ${_formatDate(customDate!)}',
                      style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Укажите причину блокировки')));
                  return;
                }
                if (selectedDuration == 'custom' && customDate == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Выберите дату окончания блокировки')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Заблокировать'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    DateTime? banUntil;
    switch (selectedDuration) {
      case '1d': banUntil = DateTime.now().add(const Duration(days: 1)); break;
      case '7d': banUntil = DateTime.now().add(const Duration(days: 7)); break;
      case '30d': banUntil = DateTime.now().add(const Duration(days: 30)); break;
      case 'perm': banUntil = null; break;
      case 'custom': banUntil = customDate; break;
    }

    try {
      await _service.banUser(user.id, banUntil: banUntil, reason: reasonCtrl.text.trim());
      _showSuccess('Пользователь заблокирован');
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _unban(User user) async {
    final ok = await _showConfirmDialog(
        context, 'Разблокировать ${user.username}?', 'Пользователь получит доступ к аккаунту.');
    if (!ok) return;
    try {
      await _service.unbanUser(user.id);
      _showSuccess('Пользователь разблокирован');
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _changeRole(User user) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Роль для ${user.username}'),
        children: _roleLabels.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.key),
                  child: Row(
                    children: [
                      if (user.role == e.key) const Icon(Icons.check, size: 16),
                      if (user.role != e.key) const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(e.value),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (result == null || result == user.role) return;
    try {
      await _service.changeRole(user.id, result);
      _showSuccess('Роль изменена');
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteUser(User user) async {
    final ok = await _showConfirmDialog(
        context, 'Удалить аккаунт ${user.username}?',
        'Все данные пользователя будут удалены. Это действие необратимо.');
    if (!ok) return;
    try {
      await _service.deleteUser(user.id);
      _showSuccess('Аккаунт удалён');
      _load(search: _searchCtrl.text);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Поиск по имени или email',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchCtrl.clear(); _load(); })
                  : null,
            ),
            onSubmitted: (v) => _load(search: v),
            onChanged: (v) { if (v.isEmpty) _load(); setState(() {}); },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Роль: '),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Все'),
                  selected: _roleFilter == null,
                  onSelected: (_) { setState(() => _roleFilter = null); _load(search: _searchCtrl.text); },
                ),
                const SizedBox(width: 4),
                ..._roleLabels.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: _roleFilter == e.key,
                    onSelected: (_) {
                      setState(() => _roleFilter = _roleFilter == e.key ? null : e.key);
                      _load(search: _searchCtrl.text);
                    },
                  ),
                )),
              ],
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_users.isEmpty) return const Center(child: Text('Нет пользователей'));

    return RefreshIndicator(
      onRefresh: () => _load(search: _searchCtrl.text),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _users.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final user = _users[i];
          final isCurrentAdmin = user.role == 'admin';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(user.username[0].toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _RoleBadge(role: user.role),
                if (user.isBanned) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('бан',
                        style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (user.isBanned && user.banReason != null)
                  Text('Причина бана: ${user.banReason}',
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                if (user.isBanned && user.banUntil != null)
                  Text('До: ${_formatDate(user.banUntil!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                Text('Постов: ${user.postsCount ?? 0}  •  '
                    'Зарегистрирован: ${_formatDate(user.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            trailing: isCurrentAdmin
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Действия',
                    onSelected: (v) {
                      if (v == 'ban') _showBanDialog(user);
                      if (v == 'unban') _unban(user);
                      if (v == 'role') _changeRole(user);
                      if (v == 'delete') _deleteUser(user);
                    },
                    itemBuilder: (_) => [
                      if (!user.isBanned)
                        const PopupMenuItem(
                            value: 'ban',
                            child: Text('Заблокировать',
                                style: TextStyle(color: Colors.orange))),
                      if (user.isBanned)
                        const PopupMenuItem(
                            value: 'unban', child: Text('Разблокировать')),
                      if (widget.isAdmin)
                        const PopupMenuItem(
                            value: 'role', child: Text('Изменить роль')),
                      if (widget.isAdmin)
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить аккаунт',
                                style: TextStyle(color: Colors.red))),
                    ],
                  ),
          );
        },
      ),
    );
  }
}




class _LogsTab extends StatefulWidget {
  const _LogsTab();

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  final _service = AdminService();
  final _searchCtrl = TextEditingController();
  final _actorCtrl = TextEditingController();
  List<LogEntry> _logs = [];
  List<String> _actionTypes = [];
  bool _loading = true;
  String? _error;
  String? _actionFilter;

  static const _actionLabels = <String, String>{
    'HIDE_POST': 'Скрытие поста',
    'SHOW_POST': 'Показ поста',
    'EDIT_POST': 'Ред. поста',
    'DELETE_POST': 'Удаление поста',
    'HIDE_COMMENT': 'Скрытие комм.',
    'SHOW_COMMENT': 'Показ комм.',
    'EDIT_COMMENT': 'Ред. комм.',
    'DELETE_COMMENT': 'Удаление комм.',
    'BAN_USER': 'Блокировка',
    'UNBAN_USER': 'Разблокировка',
    'CHANGE_ROLE': 'Смена роли',
    'DELETE_USER': 'Удаление акк.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _actorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getLogs(
        action: _actionFilter,
        actor: _actorCtrl.text.isNotEmpty ? _actorCtrl.text : null,
        search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      );
      setState(() {
        _logs = result.logs;
        _actionTypes = result.actionTypes;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Color _actionColor(String action) {
    if (action.startsWith('DELETE')) return Colors.red.shade700;
    if (action.startsWith('BAN')) return Colors.orange.shade800;
    if (action.startsWith('UNBAN')) return Colors.green.shade700;
    if (action.startsWith('HIDE')) return Colors.orange.shade600;
    if (action.startsWith('CHANGE')) return Colors.blue.shade700;
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Поиск по тексту',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                ),
                onSubmitted: (_) => _load(),
                onChanged: (v) { if (v.isEmpty) _load(); setState(() {}); },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _actorCtrl,
                decoration: InputDecoration(
                  hintText: 'Фильтр по модератору',
                  prefixIcon: const Icon(Icons.person_search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _actorCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear),
                          onPressed: () { _actorCtrl.clear(); _load(); })
                      : null,
                ),
                onSubmitted: (_) => _load(),
                onChanged: (v) { if (v.isEmpty) _load(); setState(() {}); },
              ),
            ],
          ),
        ),
        if (_actionTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _actionFilter == null,
                    onSelected: (_) { setState(() => _actionFilter = null); _load(); },
                  ),
                  const SizedBox(width: 4),
                  ..._actionTypes.map((a) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(_actionLabels[a] ?? a, style: const TextStyle(fontSize: 12)),
                      selected: _actionFilter == a,
                      selectedColor: _actionColor(a).withValues(alpha: 0.2),
                      onSelected: (_) {
                        setState(() => _actionFilter = _actionFilter == a ? null : a);
                        _load();
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_logs.isEmpty) return const Center(child: Text('Нет записей в журнале'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _logs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final log = _logs[i];
          final color = _actionColor(log.action);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_actionIcon(log.action), color: color, size: 20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _actionLabels[log.action] ?? log.action,
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.actorUsername ?? 'Система',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.targetName != null)
                  Text('Объект: ${log.targetName}',
                      style: const TextStyle(fontSize: 12)),
                if (log.details != null)
                  Text(log.details!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text(
                  _formatDateFull(log.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _actionIcon(String action) {
    if (action.contains('POST')) return Icons.article;
    if (action.contains('COMMENT')) return Icons.comment;
    if (action == 'BAN_USER') return Icons.block;
    if (action == 'UNBAN_USER') return Icons.check_circle;
    if (action == 'CHANGE_ROLE') return Icons.manage_accounts;
    if (action == 'DELETE_USER') return Icons.person_remove;
    return Icons.history;
  }
}




class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case 'admin':
        color = Colors.purple;
        label = 'Админ';
        break;
      case 'moderator':
        color = Colors.blue;
        label = 'Модер';
        break;
      default:
        color = Colors.grey;
        label = 'Юзер';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

Future<bool> _showConfirmDialog(
    BuildContext context, String title, String body) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Подтвердить'),
        ),
      ],
    ),
  );
  return result == true;
}

Future<String?> _showReasonDialog(BuildContext context, String hint) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Причина'),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Применить')),
      ],
    ),
  );
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

String _formatDateFull(DateTime dt) {
  return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import 'login_page.dart';
import 'post_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _followService = FollowService();
  final _postService = PostService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  User? _user;
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isFollowLoading = false;
  bool _isUploadingAvatar = false;

  bool get _isOwnProfile =>
      context.read<AuthProvider>().currentUser?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _followService.getUserProfile(widget.userId);
      List<Post> posts = [];
      try {
        final postsData = await _postService.getUserPosts(widget.userId);
        posts = postsData.items;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _user = profile;
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      final me = context.read<AuthProvider>().currentUser;
      if (me != null && me.id == widget.userId) {
        setState(() {
          _user = me;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final avatarUrl = await _authService.uploadAvatar(bytes, picked.name);
      if (!mounted) return;
      await context.read<AuthProvider>().updateProfile(avatarUrl: avatarUrl);
      if (!mounted) return;
      setState(() => _user = _user?.copyWith(avatarUrl: avatarUrl));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    setState(() => _isFollowLoading = true);
    try {
      final nowFollowing = _user!.isFollowing
          ? await _followService.unfollowUser(widget.userId)
          : await _followService.followUser(widget.userId);
      setState(() {
        final delta = nowFollowing ? 1 : -1;
        _user = _user!.copyWith(
          isFollowing: nowFollowing,
          followersCount: (_user!.followersCount ?? 0) + delta,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SettingsSheet(
        onUsernameChange: _showChangeUsernameDialog,
        onPasswordChange: _showChangePasswordDialog,
      ),
    );
  }

  void _showChangeUsernameDialog() {
    final ctrl = TextEditingController(text: _user?.username ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сменить никнейм'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Новый никнейм'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              final authProvider = context.read<AuthProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final ok = await authProvider.updateProfile(username: val);
              if (!mounted) return;
              nav.pop();
              if (ok) {
                setState(() => _user = _user?.copyWith(username: val));
                messenger.showSnackBar(
                    const SnackBar(content: Text('Никнейм обновлён')));
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final email = context.read<AuthProvider>().currentUser?.email ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        email: email,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароль успешно изменён')),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Нет')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _showFollowList({required bool followers}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<List<User>>(
        future: followers
            ? _followService.getFollowers(widget.userId)
            : _followService.getFollowing(widget.userId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  followers ? 'Подписчики' : 'Подписки',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Text(
                          followers ? 'Нет подписчиков' : 'Нет подписок',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: users[i].avatarUrl != null
                                ? NetworkImage(users[i].avatarUrl!)
                                : null,
                            child: users[i].avatarUrl == null
                                ? Text(users[i].username[0].toUpperCase())
                                : null,
                          ),
                          title: Text(users[i].username),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfilePage(userId: users[i].id),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Не удалось загрузить профиль'),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    final ownProfile = _isOwnProfile;
    final user = _user!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              actions: ownProfile
                  ? [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Настройки',
                        onPressed: _showSettingsSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Выйти',
                        onPressed: _logout,
                      ),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(user, ownProfile),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Публикации (${_posts.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            _posts.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          ownProfile
                              ? 'У вас пока нет публикаций'
                              : 'Нет публикаций',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildPostCard(_posts[i]),
                      childCount: _posts.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildHeader(User user, bool ownProfile) {
    return Container(
      padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          GestureDetector(
            onTap: ownProfile && !_isUploadingAvatar
                ? _pickAndUploadAvatar
                : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.3),
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: _isUploadingAvatar
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : user.avatarUrl == null
                          ? Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                ),
                if (ownProfile)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 13, color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                if (ownProfile)
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75)),
                  ),
                const SizedBox(height: 10),

                
                Row(
                  children: [
                    _statItem('${user.postsCount ?? 0}', 'постов', null),
                    const SizedBox(width: 16),
                    _statItem(
                      '${user.followersCount ?? 0}',
                      'подписчиков',
                      () => _showFollowList(followers: true),
                    ),
                    const SizedBox(width: 16),
                    _statItem(
                      '${user.followingCount ?? 0}',
                      'подписок',
                      () => _showFollowList(followers: false),
                    ),
                  ],
                ),

                
                if (!ownProfile) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _isFollowLoading ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isFollowing
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white,
                        foregroundColor: user.isFollowing
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: _isFollowLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : Text(
                              user.isFollowing
                                  ? 'Вы подписаны'
                                  : 'Подписаться',
                              style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, VoidCallback? onTap) {
    final w = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: w) : w;
  }

  

  Widget _buildPostCard(Post post) {
    final previewUrl = post.imageUrls.isNotEmpty
        ? post.imageUrls.first
        : post.outfit?.thumbnailUrl;

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
        );
        if (deleted == true && mounted) _load();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (previewUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: previewUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (c, u) =>
                      Container(height: 220, color: Colors.grey[100]),
                  errorWidget: (c, u, e) =>
                      Container(height: 220, color: Colors.grey[100]),
                ),
              ),
            if (post.content != null && post.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(post.content!,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.favorite,
                      size: 16,
                      color:
                          post.isLiked == true ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(_fmtDate(post.createdAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays} д. назад';
    if (diff.inHours > 0) return '${diff.inHours} ч. назад';
    if (diff.inMinutes > 0) return '${diff.inMinutes} мин. назад';
    return 'Только что';
  }
}



class _SettingsSheet extends StatelessWidget {
  final VoidCallback onUsernameChange;
  final VoidCallback onPasswordChange;

  const _SettingsSheet({
    required this.onUsernameChange,
    required this.onPasswordChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Настройки',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Сменить никнейм'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            onUsernameChange();
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Сменить пароль'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            onPasswordChange();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const _ChangePasswordSheet({required this.email, required this.onSuccess});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _authService = AuthService();

  // Step 1
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Step 2
  final List<TextEditingController> _codeCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendCooldown = 0;
  bool _resending = false;

  int _step = 1;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    for (final c in _codeCtrl) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _codeCtrl.map((c) => c.text).join();

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.requestPasswordChangeCode(_currentPassCtrl.text);
      if (!mounted) return;
      setState(() { _step = 2; _resendCooldown = 60; });
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_code.length < 6) {
      setState(() => _error = 'Введите все 6 цифр');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().changePassword(
        _currentPassCtrl.text,
        _newPassCtrl.text,
        _code,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await _authService.requestPasswordChangeCode(_currentPassCtrl.text);
      if (!mounted) return;
      setState(() => _resendCooldown = 60);
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown > 0) _startCooldown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepDot(active: _step == 1, done: _step > 1),
              const SizedBox(width: 8),
              Container(width: 32, height: 2,
                  color: _step > 1 ? colorScheme.primary : Colors.grey[300]),
              const SizedBox(width: 8),
              _StepDot(active: _step == 2, done: false),
            ],
          ),
          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _step == 1
                ? _buildStep1(key: const ValueKey(1))
                : _buildStep2(key: const ValueKey(2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1({Key? key}) {
    return Form(
      key: _formKey,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text('Смена пароля',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Шаг 1 из 2 — введите пароли',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 24),

          _PassField(
            controller: _currentPassCtrl,
            label: 'Текущий пароль',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (v) => (v == null || v.isEmpty) ? 'Введите текущий пароль' : null,
          ),
          const SizedBox(height: 12),
          _PassField(
            controller: _newPassCtrl,
            label: 'Новый пароль',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Введите новый пароль';
              if (v.length < 6) return 'Минимум 6 символов';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _PassField(
            controller: _confirmPassCtrl,
            label: 'Подтвердите новый пароль',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) => v != _newPassCtrl.text ? 'Пароли не совпадают' : null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendCode(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _loading ? null : _sendCode,
            icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined, size: 18),
            label: const Text('Получить код на почту',
                style: TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 4),
          Text('Код придёт на ${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStep2({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text('Введите код',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Шаг 2 из 2 — код отправлен на\n${widget.email}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => _buildDigit(i)),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сменить пароль', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: (_resending || _resendCooldown > 0) ? null : _resend,
          child: _resending
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_resendCooldown > 0
                  ? 'Отправить повторно ($_resendCooldown с)'
                  : 'Отправить код повторно'),
        ),
      ],
    );
  }

  Widget _buildDigit(int index) {
    return Container(
      width: 44, height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _codeCtrl[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (v.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          if (index == 5 && v.isNotEmpty) _confirm();
        },
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = (active || done)
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[300]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: done
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _authService = AuthService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.getAllUsers();
      setState(() {
        _users = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: const Text('Вы уверены, что хотите удалить этого пользователя? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteUser(userId);

    if (success) {
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь удален')),
        );
      }
    }
  }

  Future<void> _changeUserRole(User user) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить роль для ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Пользователь'),
              leading: Radio<String>(
                value: 'user',
                groupValue: user.role,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, 'user'),
            ),
            ListTile(
              title: const Text('Модератор'),
              leading: Radio<String>(
                value: 'moderator',
                groupValue: user.role,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, 'moderator'),
            ),
            ListTile(
              title: const Text('Администратор'),
              leading: Radio<String>(
                value: 'admin',
                groupValue: user.role,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, 'admin'),
            ),
          ],
        ),
      ),
    );

    if (selectedRole == null || selectedRole == user.role) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserRole(user.id, selectedRole);

    if (success) {
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Роль изменена')),
        );
      }
    }
  }

  Future<void> _banUser(User user) async {
    final banType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заблокировать ${user.username}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Временно (24 часа)'),
              onTap: () => Navigator.pop(context, 'temporary'),
            ),
            ListTile(
              title: const Text('На неделю'),
              onTap: () => Navigator.pop(context, 'period'),
            ),
            ListTile(
              title: const Text('Навсегда'),
              onTap: () => Navigator.pop(context, 'permanent'),
            ),
          ],
        ),
      ),
    );

    if (banType == null) return;

    DateTime? banUntil;
    if (banType == 'temporary') {
      banUntil = DateTime.now().add(const Duration(days: 1));
    } else if (banType == 'period') {
      banUntil = DateTime.now().add(const Duration(days: 7));
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.banUser(
      user.id,
      banType,
      banUntil: banUntil?.toIso8601String(),
      reason: 'Заблокирован администратором',
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
        title: const Text('Панель администратора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role),
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(user.username),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleLabel(user.role),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (user.isBanned) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Заблокирован',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Действия',
                          onSelected: (value) {
                            switch (value) {
                              case 'role':
                                _changeUserRole(user);
                                break;
                              case 'ban':
                                _banUser(user);
                                break;
                              case 'delete':
                                _deleteUser(user.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'role',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings),
                                  SizedBox(width: 8),
                                  Text('Изменить роль'),
                                ],
                              ),
                            ),
                            if (!user.isBanned)
                              const PopupMenuItem(
                                value: 'ban',
                                child: Row(
                                  children: [
                                    Icon(Icons.block, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Заблокировать', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Удалить', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Админ';
      case 'moderator':
        return 'Модератор';
      default:
        return 'Пользователь';
    }
  }
}

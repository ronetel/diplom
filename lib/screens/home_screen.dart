import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'closet_page.dart';
import 'outfits_page.dart';
import 'feed_page.dart';
import 'recommend_page.dart';
import 'moderation_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) return;

    await authProvider.init();

    if (authProvider.currentUser == null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading || authProvider.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = authProvider.currentUser!.role;

    if (role == 'admin') return _buildAdminLayout();
    if (role == 'moderator') return _buildModeratorLayout();
    return _buildUserLayout();
  }

  // ─── Пользователь ────────────────────────────────────────────────────────
  Widget _buildUserLayout() {
    final pages = const [
      RecommendPage(),
      ClosetPage(),
      OutfitsPage(),
      FeedPage(),
    ];
    return Scaffold(
      body: pages[_selectedIndex.clamp(0, pages.length - 1)],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, 3),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Погода',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Гардероб',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Образы',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Лента',
          ),
        ],
      ),
    );
  }

  // ─── Модератор / Администратор ───────────────────────────────────────────
  Widget _buildModeratorLayout() => _buildStaffLayout();
  Widget _buildAdminLayout() => _buildStaffLayout();

  Widget _buildStaffLayout() {
    final pages = [
      const ModerationPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: pages[_selectedIndex.clamp(0, pages.length - 1)],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, 1),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Модерация',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

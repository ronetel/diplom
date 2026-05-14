import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'user_profile_page.dart';



class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return UserProfilePage(userId: userId);
  }
}

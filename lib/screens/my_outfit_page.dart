import 'package:flutter/material.dart';

class MyOutfitPage extends StatelessWidget {
  const MyOutfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои луки')),
      body: const Center(child: Text('Здесь будут отображаться ваши луки')),
    );
  }
}

import 'package:flutter/material.dart';

/// 单字详情页面 - 占位页面
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单字详情')),
      body: const Center(child: Text('单字详情')),
    );
  }
}

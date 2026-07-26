import 'package:flutter/material.dart';

/// 古籍修复首页 - 占位页面
class RestorationScreen extends StatelessWidget {
  const RestorationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('古籍修复')),
      body: const Center(child: Text('古籍修复功能')),
    );
  }
}

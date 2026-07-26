import 'package:flutter/material.dart';

/// 风格迁移首页 - 占位页面
class StylizationScreen extends StatelessWidget {
  const StylizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('风格迁移')),
      body: const Center(child: Text('风格迁移')),
    );
  }
}

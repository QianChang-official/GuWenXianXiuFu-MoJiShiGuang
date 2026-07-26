import 'package:flutter/material.dart';

/// 实体详情页面 - 占位页面
class EntityDetailScreen extends StatelessWidget {
  const EntityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('实体详情')),
      body: const Center(child: Text('实体详情')),
    );
  }
}

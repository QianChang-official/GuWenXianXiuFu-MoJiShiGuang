import 'package:flutter/material.dart';

/// 知识图谱首页 - 占位页面
class KgScreen extends StatelessWidget {
  const KgScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('知识图谱')),
      body: const Center(child: Text('知识图谱')),
    );
  }
}

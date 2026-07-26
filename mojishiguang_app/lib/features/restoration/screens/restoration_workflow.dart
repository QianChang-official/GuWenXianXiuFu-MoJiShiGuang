import 'package:flutter/material.dart';

/// 修复工作流页面 - 占位页面
class RestorationWorkflow extends StatelessWidget {
  const RestorationWorkflow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修复工作流')),
      body: const Center(child: Text('修复工作流')),
    );
  }
}

import 'package:flutter/material.dart';

/// OCR 文字识别首页 - 占位页面
class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文字识别')),
      body: const Center(child: Text('OCR 文字识别')),
    );
  }
}

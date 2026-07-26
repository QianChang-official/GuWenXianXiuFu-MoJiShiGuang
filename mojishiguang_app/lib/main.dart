import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// 「墨迹时光」应用入口
///
/// 初始化 Riverpod ProviderScope 作为全局状态管理容器，
/// 加载 MaterialApp.router 配置，启动跨平台三端兼容的移动应用。
///
/// ## 启动流程
/// 1. WidgetsFlutterBinding — 确保 Flutter 引擎初始化
/// 2. ProviderScope — 注入全局 Riverpod 状态管理
/// 3. MoJiShiGuangApp — 应用根组件（GoRouter 路由 + 双主题 + 国际化）
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MoJiShiGuangApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 「墨迹时光」主页
///
/// 底部导航栏包含四大核心模块入口，每个模块集成多篇前沿论文技术。
/// 采用 Material 3 设计语言，适配 iOS/Android/HarmonyOS 平台导航规范。
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.auto_fix_high_outlined),
      selectedIcon: Icon(Icons.auto_fix_high),
      label: '修复工坊',
    ),
    NavigationDestination(
      icon: Icon(Icons.text_snippet_outlined),
      selectedIcon: Icon(Icons.text_snippet),
      label: '智能识别',
    ),
    NavigationDestination(
      icon: Icon(Icons.hub_outlined),
      selectedIcon: Icon(Icons.hub),
      label: '知识图谱',
    ),
    NavigationDestination(
      icon: Icon(Icons.brush_outlined),
      selectedIcon: Icon(Icons.brush),
      label: '墨池体验',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // 各模块页面由 GoRouter ShellRoute 管理
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/restoration');
              break;
            case 1:
              context.go('/ocr');
              break;
            case 2:
              context.go('/kg');
              break;
            case 3:
              context.go('/stylization');
              break;
          }
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 72,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
    );
  }
}

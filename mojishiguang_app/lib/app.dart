import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 「墨迹时光」应用入口组件
///
/// 墨迹时光 —— 基于多模态 AI 的碑帖/古籍残片智能修复与数字人文互动平台。
/// 
/// ## 跨平台支持
/// - **iOS**: CoreML + ANE 神经网络加速，Metal 图像渲染
/// - **Android**: NNAPI + GPU Delegate 硬件加速，Material You 动态颜色
/// - **HarmonyOS**: MindSpore Lite + 方舟编译器异构计算
///
/// ## 四大核心模块
/// 1. **AI 残片修复大师** — 集成 LaMa/MAT/RePaint/Edge-Connect 等 35+ 篇论文
/// 2. **古籍甲骨文智能识别** — 集成 DBNet++/TrOCR/ABINet/PARSeq 等 30+ 篇论文
/// 3. **时空对话·知识图谱** — 集成 TransE/RotatE/CompGCN/GATv2 等 25+ 篇论文
/// 4. **墨池体验·风格迁移** — 集成 AdaIN/CycleGAN/CalliGAN/CAST 等 22+ 篇论文
class MoJiShiGuangApp extends ConsumerWidget {
  const MoJiShiGuangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '墨迹时光',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}

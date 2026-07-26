import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/restoration/screens/restoration_screen.dart';
import '../../features/restoration/screens/restoration_workflow.dart';
import '../../features/ocr/screens/ocr_screen.dart';
import '../../features/ocr/screens/character_detail_screen.dart';
import '../../features/kg/screens/kg_screen.dart';
import '../../features/kg/screens/entity_detail_screen.dart';
import '../../features/stylization/screens/stylization_screen.dart';
import '../../features/stylization/screens/calligraphy_compare_screen.dart';
import '../../features/home/home_screen.dart';
import '../constants/app_constants.dart';

/// 墨迹时光应用路由配置
class AppRouter {
  AppRouter._();

  /// 创建 GoRouter 实例
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppConstants.routeHome,
      routes: [
        // ── ShellRoute: 底部导航栏布局 ──
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return ScaffoldWithNavBar(child: child);
          },
          routes: <RouteBase>[
            GoRoute(
              path: AppConstants.routeHome,
              builder: (BuildContext context, GoRouterState state) =>
                  const HomeScreen(),
            ),
            GoRoute(
              path: AppConstants.routeRestoration,
              builder: (BuildContext context, GoRouterState state) =>
                  const RestorationScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'workflow',
                  builder: (BuildContext context, GoRouterState state) =>
                      const RestorationWorkflow(),
                ),
              ],
            ),
            GoRoute(
              path: AppConstants.routeOcr,
              builder: (BuildContext context, GoRouterState state) =>
                  const OcrScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'detail',
                  builder: (BuildContext context, GoRouterState state) =>
                      const CharacterDetailScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppConstants.routeKg,
              builder: (BuildContext context, GoRouterState state) =>
                  const KgScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'entity',
                  builder: (BuildContext context, GoRouterState state) =>
                      const EntityDetailScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppConstants.routeStylization,
              builder: (BuildContext context, GoRouterState state) =>
                  const StylizationScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'compare',
                  builder: (BuildContext context, GoRouterState state) =>
                      const CalligraphyCompareScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Riverpod Provider for GoRouter
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter();
});

/// 带底部导航栏的页面脚手架
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 根据当前路由路径确定选中索引
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith(AppConstants.routeRestoration)) {
      currentIndex = 1;
    } else if (location.startsWith(AppConstants.routeOcr)) {
      currentIndex = 2;
    } else if (location.startsWith(AppConstants.routeKg)) {
      currentIndex = 3;
    } else if (location.startsWith(AppConstants.routeStylization)) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          switch (index) {
            case 0:
              context.go(AppConstants.routeHome);
              break;
            case 1:
              context.go(AppConstants.routeRestoration);
              break;
            case 2:
              context.go(AppConstants.routeOcr);
              break;
            case 3:
              context.go(AppConstants.routeKg);
              break;
            case 4:
              context.go(AppConstants.routeStylization);
              break;
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restore_outlined),
            activeIcon: Icon(Icons.restore),
            label: '修复',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_snippet_outlined),
            activeIcon: Icon(Icons.text_snippet),
            label: '识别',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree),
            label: '图谱',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush_outlined),
            activeIcon: Icon(Icons.brush),
            label: '风格',
          ),
        ],
      ),
    );
  }
}
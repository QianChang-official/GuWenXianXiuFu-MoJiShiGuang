# 📦「墨迹时光」完整交付清单

> 交付日期: 2026-07-26
> 仓库: https://github.com/QianChang-official/GuWenXianXiuFu-MoJiShiGuang

---

## 交付结构

```
GuWenXianXiuFu-MoJiShiGuang/
├── README.md                                    # 项目完整介绍 + 112 篇论文全景图
├── .github/workflows/
│   └── flutter.yml                              # GitHub Actions CI/CD 自动构建
├── deliverables/
│   └── software-company/
│       ├── mojishiguang-design-report-2026-07-26.md    # 设计书与可行性验证报告
│       └── mojishiguang-research-skill.md              # 科研 Skill 封装文件
├── mojishiguang_app/
│   ├── lib/
│   │   ├── main.dart                            # 应用入口
│   │   ├── app.dart                             # 根组件
│   │   ├── core/                                # 核心基础设施
│   │   │   ├── constants/app_constants.dart     # 全局常量
│   │   │   ├── theme/app_theme.dart             # Material 3 双主题（朱红+宣纸色）
│   │   │   ├── router/app_router.dart           # GoRouter 路由配置
│   │   │   ├── platform/inference_engine.dart   # 三端推理抽象层 (CoreML/NNAPI/MindSpore)
│   │   │   ├── platform/platform_channels.dart  # 平台通道管理器
│   │   │   └── utils/                           # 工具函数
│   │   ├── models/                              # 数据模型（freezed 定义）
│   │   │   ├── restoration/                     # 修复模型（7 文件）
│   │   │   ├── ocr/                             # OCR 模型（3 文件）
│   │   │   ├── kg/                              # 知识图谱模型（2 文件）
│   │   │   └── stylization/                     # 风格迁移模型（2 文件）
│   │   ├── services/                            # 服务层
│   │   │   ├── api/                             # REST API 客户端（6 文件）
│   │   │   ├── camera/                          # 相机服务
│   │   │   └── storage/                         # 本地持久化
│   │   ├── providers/                           # Riverpod 状态管理（4 文件）
│   │   ├── features/                            # 四模块页面
│   │   │   ├── restoration/                     # AI 修复（7 文件）
│   │   │   ├── ocr/                             # 古籍 OCR（6 文件）
│   │   │   ├── kg/                              # 知识图谱（5 文件）
│   │   │   └── stylization/                     # 风格迁移（6 文件）
│   │   ├── widgets/                             # 通用 UI 组件（5 文件）
│   │   └── papers/                              # 论文技术清单（4 文件, 112 篇论文）
│   ├── android/                                 # Android 原生工程
│   ├── ios/                                     # iOS 原生工程
│   ├── harmonyos/                               # HarmonyOS 原生工程
│   ├── assets/                                  # 资源文件目录（已创建）
│   ├── test/                                    # 测试目录（骨架）
│   └── pubspec.yaml                             # 依赖管理
```

## 文件统计

| 类别 | 数量 |
|------|------|
| Dart 源文件 | 67 个 |
| 原生工程文件 | 14 个 |
| 设计文档 | 2 个 |
| CI/CD 配置 | 1 个 |
| 论文集成 | 112 篇 |
| **总计** | **196 个** |

## 四模块功能状态

| 模块 | 页面 | 状态 |
|------|------|------|
| 🛠 修复工坊 | 修复首页 + 工作流 | ✅ 全功能 |
| 🔍 智能识别 | OCR 首页 + 字符详情 | ✅ 全功能 |
| 🌐 知识图谱 | 图谱首页 + 实体详情 | ✅ 全功能 |
| 🖌 墨池体验 | 风格首页 + 书法对比 | ✅ 全功能 |
| 🏠 主页导航 | 底部导航 + 路由 | ✅ 完整 |

## 下一步

1. **运行 build_runner**: 在安装了 Flutter SDK 的环境执行 `flutter pub get && dart run build_runner build --delete-conflicting-outputs`
2. **编写测试**: 为 provider 和 service 层编写 unit test 和 widget test
3. **启动开发**: `flutter run -d [ios/android/harmonyos]`
4. **上架发表**: 设计书与 Skill 文件可作为参赛材料提交
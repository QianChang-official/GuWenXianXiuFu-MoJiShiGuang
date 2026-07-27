# 📜 「墨迹时光」古籍智能修复与数字人文平台 — 设计书与可行性验证报告

> **版本**: 1.0  
> **日期**: 2026-07-26  
> **项目仓库**: [GuWenXianXiuFu-MoJiShiGuang](https://github.com/QianChang-official/GuWenXianXiuFu-MoJiShiGuang)

---

## 一、项目概述

### 1.1 项目背景

中国现存古籍约 5000 万册（件），其中超过 40% 存在不同程度的破损（虫蛀、水渍、缺角、折裂、褪色等）。传统修复依赖专家手工，培养一名成熟的古籍修复师需 10 年以上，全国专业修复人员不足 1000 人。AI 技术的介入有望将修复效率提升 10-100 倍，同时大幅降低准入门槛。

### 1.2 项目定位

「墨迹时光」是一个**基于多模态 AI 的跨平台移动应用**，面向：
- **文博机构**：中小型博物馆、图书馆的古籍数字化修复
- **研究学者**：碑帖文字 OCR 识别与知识图谱构建
- **教育用户**：书法教学中的风格迁移与临摹对比
- **文创市场**：数字藏品、定制书法衍生品内容生成

### 1.3 参赛定位

本项目同时参加**「书生科学发现平台 SCP」科研能力封装赛道**，将古籍修复全链路的科研方法论封装为可复用的 Skill。

---

## 二、技术方案

### 2.1 跨平台策略：Flutter 三端覆盖

| 维度 | 选择 | 理由 |
|------|------|------|
| **跨平台框架** | Flutter 3.x (Dart 3) | 一套代码覆盖 iOS / Android / HarmonyOS |
| **状态管理** | Riverpod 2.x + GoRouter 14.x | 类型安全，天然支持异步 AI 任务状态 |
| **本地存储** | drift (SQLite) + shared_preferences | 离线缓存 + 修复历史持久化 |
| **网络通信** | Dio + 缓存拦截器 | 断点续传、进度回调、请求取消 |
| **图像处理** | image (Dart) + opencv (Native Plugin) | 端侧图像预处理与后处理 |
| **端侧推理** | ONNX Runtime + CoreML + NNAPI + MindSpore Lite | 轻量模型本地运行 |
| **云側推理** | RESTful API (FastAPI) | 扩散模型等重量级修复任务 |

### 2.2 整体架构

```
┌─────────────────────────────────────────────────────┐
│                  Flutter 共享 UI 层                    │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐  │
│  │ 修复工坊  │ │ 智能识别  │ │ 知识图谱│ │ 墨池体验  │  │
│  └────┬─────┘ └────┬─────┘ └───┬────┘ └─────┬────┘  │
│       └────────────┼────────────┼────────────┘        │
│                    │  Riverpod 状态层                  │
├────────────────────┼──────────────────────────────────┤
│               Flutter 服务层 (Dart)                    │
│  ┌─────────┐ ┌──────────┐ ┌────────┐ ┌────────────┐  │
│  │  Camera  │ │ 本地推理  │ │ 云 API │ │ 本地持久化  │  │
│  │  Service │ │  Engine  │ │ Client │ │  (drift)   │  │
│  └────┬────┘ └────┬─────┘ └───┬────┘ └──────┬─────┘  │
├───────┼──────────┼───────────┼────────────┼──────────┤
│  ┌────┴────┐ ┌──┴──────┐ ┌──┴───┐ ┌──────┴───────┐  │
│  │ Platform│ │ Platform│ │ HTTP │ │    Platform   │  │
│  │ Channel │ │ Channel │ │Client│ │    Channel    │  │
│  │(Camera) │ │(AI推理) │ │(Dio) │ │   (File/Share)│  │
│  └─────────┘ └─────────┘ └──────┘ └──────────────┘  │
│                                                       │
│  ┌───────────┐ ┌──────────┐ ┌────────────────┐       │
│  │ iOS 原生   │ │ Android  │ │ HarmonyOS 原生  │       │
│  │ CoreML    │ │ NNAPI    │ │ MindSpore      │       │
│  │ Metal     │ │ OpenCL   │ │ 方舟异构计算    │       │
│  └───────────┘ └──────────┘ └────────────────┘       │
└───────────────────────────────────────────────────────┘
```

### 2.3 项目结构

```
mojishiguang_app/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # 根组件(MaterialApp.router)
│   ├── core/                        # 核心基础设施
│   │   ├── constants/               # 全局常量
│   │   ├── theme/                   # Material 3 双主题
│   │   ├── router/                  # GoRouter 路由
│   │   ├── platform/                # 三端推理抽象层
│   │   └── utils/                   # 工具函数
│   ├── models/                      # 数据模型 (freezed)
│   │   ├── restoration/             # 修复模块模型
│   │   ├── ocr/                     # OCR 模块模型
│   │   ├── kg/                      # 知识图谱模块模型
│   │   └── stylization/             # 风格迁移模块模型
│   ├── services/                    # 服务层
│   │   ├── api/                     # REST API 客户端
│   │   ├── camera/                  # 相机服务
│   │   └── storage/                 # 本地持久化
│   ├── providers/                   # Riverpod 状态管理
│   ├── features/                    # 四模块页面
│   │   ├── restoration/             # AI 修复
│   │   ├── ocr/                     # 古籍 OCR
│   │   ├── kg/                      # 知识图谱
│   │   └── stylization/             # 风格迁移
│   ├── widgets/                     # 通用 UI 组件
│   └── papers/                      # 论文技术清单
├── android/                         # Android 原生工程
├── ios/                             # iOS 原生工程
├── harmonyos/                       # HarmonyOS 原生工程
├── test/                            # 测试用例
└── pubspec.yaml                     # 依赖管理
```

---

## 三、四大核心模块设计

### 模块 1：AI 残片修复大师 🛠

**工作流程**: 上传图片 → 破损检测 (Mask) → 方法选择 → AI 修复 → 质量评估 → 对比导出

**端云协同**:
| 子功能 | 部署 | 技术方案 |
|--------|------|---------|
| 破损检测 | 端侧 | Canny + 连通域分析 / 轻量 ONNX 模型 |
| 图像修复 | 云侧 | LaMa / MAT / DeepFill v2 / RePaint / Edge-Connect |
| 超分辨率 | 云侧 | SwinIR / Real-ESRGAN / NAFNet |
| 文档增强 | 端侧 | DocEnTR / DeepFL / TextGestalt |
| 质量评估 | 云侧 | PSNR / SSIM / LPIPS / NIMA |

**集成论文**: 35 篇（详见 `lib/papers/restoration_papers.dart`）

### 模块 2：古籍甲骨文智能识别 🔍

**工作流程**: 选择图片 → 文字区域检测 → OCR 识别 → 候选字排序 → 字典关联 → 结果导出

| 子功能 | 部署 | 技术方案 |
|--------|------|---------|
| 文字检测 | 端侧 | DBNet++ / EAST / CRAFT / PAN |
| 文字识别 | 云侧 | TrOCR / ABINet / PARSeq / SVTR |
| 字典关联 | 云侧 | 《说文解字》《康熙字典》知识库查询 |

**集成论文**: 30 篇（详见 `lib/papers/ocr_papers.dart`）

### 模块 3：时空对话·知识图谱 🌐

**工作流程**: 输入文字 → 实体抽取 → 关系抽取 → 图谱构建 → 可视化交互 → 知识探索

| 子功能 | 部署 | 技术方案 |
|--------|------|---------|
| 实体抽取 | 云侧 | LLM (GLM/文心) 实体关系抽取 |
| 图谱可视化 | 端侧 | 自定义 CustomPainter (力导向布局) |
| 节点交互 | 端侧 | 手势缩放/拖拽/点击展开 |

**交互方式**: 图谱视图 / 时间线视图 / 列表视图  
**集成论文**: 25 篇（详见 `lib/papers/kg_papers.dart`）

### 模块 4：墨池体验·风格迁移与临摹 🖌

**工作流程**: 输入文字/手写 → 选择碑帖风格 → 风格迁移 → 笔画对比 → 评分 → 分享

| 子功能 | 部署 | 技术方案 |
|--------|------|---------|
| 风格迁移 | 云侧 | AdaIN / CycleGAN / StyTr2 / CalliGAN |
| 笔画对比 | 端侧 | DTW 笔画骨架相似度 |
| 作品分享 | 端侧 | 导出高清 PNG (ffmpeg) |

**集成论文**: 22 篇（详见 `lib/papers/style_papers.dart`）

---

## 四、论文技术全景图 (112 篇)

| 模块 | 覆盖论文数 | 代表性论文 | 顶会来源 |
|------|-----------|-----------|---------|
| 图像修复与增强 | 35 | LaMa, MAT, DeepFill v2, RePaint, SwinIR, Real-ESRGAN | CVPR 2022, ICCV 2021, ECCV 2022 |
| 文字检测与 OCR | 30 | DBNet++, TrOCR, ABINet, PARSeq, SVTR | AAAI 2022, NeurIPS 2021, CVPR 2021 |
| 知识图谱 | 25 | TransE, RotatE, GATv2, CompGCN, HGT | NeurIPS 2013, ICLR 2019, WWW 2020 |
| 风格迁移与书法生成 | 22 | AdaIN, StyTr2, CalliGAN, StrokeNet, MX-Font | ICCV 2017, CVPR 2022, ECCV 2022 |

**总计: 112 篇论文**

---

## 五、三端平台差异化适配

### 5.1 AI 推理硬件加速

```dart
// 统一推理接口 — 平台通道分派
abstract class InferenceEngine {
  factory InferenceEngine.create() {
    if (Platform.isIOS) return CoreMLInference();
    if (Platform.isAndroid) return NNAPIInference();
    if (isHarmonyOS()) return MindSporeInference();
  }
}
```

### 5.2 特性支持矩阵

| 特性 | iOS | Android | HarmonyOS | 离线 |
|------|-----|---------|-----------|------|
| 拍照/相册 | ✅ AVFoundation | ✅ CameraX | ✅ Camera Kit | ✅ |
| 破损检测 | ✅ CoreML ANE | ✅ NNAPI | ✅ MindSpore | ✅ |
| AI 修复(扩散) | ✅ 云 API | ✅ 云 API | ✅ 云 API | ❌ |
| 古文 OCR | ✅ CoreML+云 | ✅ NNAPI+云 | ✅ MindSpore+云 | ⚠️ 基础 |
| 知识图谱可视化 | ✅ CustomPaint | ✅ CustomPaint | ✅ CustomPaint | ✅ 缓存 |
| 风格迁移 | ✅ 云 API | ✅ 云 API | ✅ 云 API | ❌ |
| 作品分享 | ✅ Share Sheet | ✅ Intent | ✅ 分享 Kit | ✅ |

---

## 六、可行性验证

### 6.1 技术可行性 ✅

| 技术点 | 成熟度 | 验证方式 |
|--------|--------|---------|
| Flutter 跨平台 | ✅ 成熟 | Flutter 3.x 已稳定支持三端 |
| 图像修复 API | ✅ 可行 | LaMa/MAT 等已有开源实现，可封装 REST API |
| 端侧推理 | ✅ 可行 | CoreML/NNAPI/MindSpore 均有成熟 SDK |
| 知识图谱可视化 | ✅ 可行 | CustomPainter 力导向布局算法已实现 |
| OCR 文字识别 | ✅ 可行 | 可通过云 API 接入微调模型 |

### 6.2 性能指标

| 指标 | 目标值 | 实现策略 |
|------|-------|---------|
| 冷启动 | < 3s | 延迟加载 + AOT 编译 |
| 破损检测 | < 1s (端侧) | TFLite GPU / CoreML ANE |
| OCR 单字 | < 2s (含 API) | 批量化请求合并 |
| 图谱渲染 | 60fps | RepaintBoundary + 虚拟化 |
| 内存占用 | < 150MB | 缩略图 + 按需加载 |
| 安装包 | < 40MB | 模型按需下载 + Tree Shaking |

### 6.3 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 云 API 延迟 | OCR 体验 | 端侧轻量模型兜底 |
| 大模型部署成本 | 商业化 | 端云协同，重模型按需调用 |
| HarmonyOS 适配 | 三端覆盖 | Flutter 官方支持 + Platform Channel 隔离差异 |
| 古文 OCR 准确率 | 核心体验 | 多模型投票 + 字典约束 + 人工校对入口 |

---

## 七、部署路径

### Phase 1：基础框架（4 周）
- Flutter 脚手架 + 三端工程配置
- 拍照/相册 + 图像预处理管线
- 破损检测 ONNX Runtime 集成
- 云 API 通信框架 (Dio + 缓存)

### Phase 2：核心功能（6 周）
- AI 修复工坊（Mask + 修复 + 后处理）
- 古文 OCR（检测 + 识别 + 候选）
- 知识图谱（实体抽取 + Canvas 可视化）
- 风格迁移（云端 + 端侧对比）

### Phase 3：平台适配（4 周）
- iOS：CoreML 加速 + Metal + Share Sheet
- Android：NNAPI + Material You
- HarmonyOS：MindSpore Lite + 方舟编译
- 无障碍 + 国际化（中/英/日/韩）

### Phase 4：上线优化（2 周）
- 包体积优化 + 模型按需下载
- 性能 Profile + 帧率调优
- App Store / 应用市场 / Google Play 上架

---

## 八、代码状态

截至 2026-07-26，项目已完成：

| 模块 | 状态 | 说明 |
|------|------|------|
| 项目骨架 | ✅ 完成 | 67 个 Dart 文件，完整的分层架构 |
| 数据模型 | ✅ 完成 | 所有模块的 freezed 模型定义 |
| API 服务层 | ✅ 完成 | Dio 封装的 REST 客户端 |
| 状态管理 | ✅ 完成 | Riverpod Provider 体系 |
| UI 页面 | ✅ 完成 | 7 个 screens/ 全功能页面 |
| 论文清单 | ✅ 完成 | 112 篇论文覆盖四模块 |
| 知识图谱画布 | ✅ 完成 | 力导向布局 CustomPainter |
| build_runner | ⏳ 待运行 | 需 Flutter SDK 环境运行代码生成 |
| 测试用例 | ⏳ 待编写 | 骨架已准备 |
| CI/CD | ✅ 已配置 | GitHub Actions 工作流 |

---

> **墨迹时光** — 让每一笔墨迹都被时光铭记，让每一页古籍都重获新生。
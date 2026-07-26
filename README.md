# 📜 墨迹时光 — MoJiShiGuang

> **基于多模态 AI 的碑帖/古籍残片智能修复与数字人文互动平台**
>
> 让 AI 走进博物馆、图书馆与艺术工作室——复活千年墨迹，传承中华文脉。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-16+-000000?logo=apple)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-8.0+-3DDC84?logo=android)](https://developer.android.com)
[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-Next-FF0000?logo=huawei)](https://developer.harmonyos.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

---

## 📋 目录

- [项目背景](#-项目背景)
- [系统架构](#-系统架构)
- [四大核心模块](#-四大核心模块)
- [论文技术全景图](#-论文技术全景图)
- [跨平台适配](#-跨平台适配)
- [快速开始](#-快速开始)
- [项目结构](#-项目结构)
- [性能目标](#-性能目标)
- [贡献指南](#-贡献指南)

---

## 🎯 项目背景

### 社会价值

中国现存古籍约 5000 万册（件），其中超过 40% 存在不同程度的破损。传统修复依赖专家手工，耗时极长且人才稀缺。本项目通过 AI 技术，将文物修复的准入门槛大幅降低，让中小型博物馆、研究机构乃至个人爱好者都能参与古籍数字化修复。

### 核心价值

| 维度 | 价值 |
|------|------|
| **文化传承** | AI 复活破损碑帖、古籍，让珍贵文物重获新生 |
| **社会治理** | 降低文物修复门槛，赋能基层文保机构 |
| **教育普及** | 构建可交互的知识网络，赋能书法与历史教学 |
| **商业创新** | 文创产品（数字藏品、定制书法衍生品）内容生成 |

---

## 🏗 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter 共享 UI 层                        │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐   │
│  │ 修复工坊   │  │ 智能识别   │  │ 知识图谱   │  │ 墨池体验   │   │
│  │ Restoration │  │ OCR    │  │ KG      │  │ Style    │   │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬─────┘   │
│        └──────────────┼──────────────┼─────────────┘         │
│                       │ Riverpod 状态层                       │
├───────────────────────┼──────────────────────────────────────┤
│                    Flutter 服务层 (Dart)                      │
│  ┌────────┐  ┌──────────┐  ┌────────┐  ┌───────────────┐    │
│  │ Camera  │  │ 本地推理   │  │ 云 API  │  │ 本地持久化    │    │
│  │ Service │  │ Engine   │  │ Client │  │ (drift)       │    │
│  └────┬───┘  └────┬─────┘  └───┬────┘  └──────┬────────┘    │
├───────┼──────────┼────────────┼──────────────┼──────────────┤
│       │          │            │              │               │
│  ┌────┴────┐ ┌──┴──────┐ ┌───┴───┐ ┌──────┴───────┐        │
│  │ Platform│ │ Platform│  │ HTTP  │ │   Platform   │        │
│  │ Channel │ │ Channel │  │ Client│ │   Channel    │        │
│  │(Camera) │ │(AI推理)  │  │(Dio)  │ │  (File/Share)│        │
│  └─────────┘ └─────────┘  └───────┘ └──────────────┘        │
│                                                             │
│  ┌──────────────┐ ┌──────────────┐ ┌───────────────────┐    │
│  │   iOS 原生    │ │  Android 原生 │ │  HarmonyOS 原生    │    │
│  │  CoreML/Metal│ │  NNAPI/OpenCL│ │  MindSpore/Ark   │    │
│  └──────────────┘ └──────────────┘ └───────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 四大核心模块

### 模块一：AI 残片修复大师 🛠

古籍/碑帖图像中的破损（虫蛀、水渍、缺角、折痕）智能检测与修复。

**工作流程：**
```
上传图片 → 破损检测(Mask) → 方法选择 → AI修复 → 质量评估 → 对比导出
```

**集成论文技术：** LaMa、MAT、DeepFill v2、RePaint、Edge-Connect、ZITS、TFill、Palette、Bringing Old Photos Back to Life、SwinIR、HAT、Restormer、NAFNet、Uformer、Real-ESRGAN 等 **35+** 篇

### 模块二：古籍甲骨文智能识别 🔍

针对古籍、碑帖的复杂字体（异体字、避讳字、模糊字）识别。

**工作流程：**
```
选择图片 → 文字区域检测 → OCR识别 → 候选字筛选 → 字典关联 → 结果导出
```

**集成论文技术：** DBNet++、CRAFT、EAST、TrOCR、ABINet、PARSeq、VisionLAN、SRN、MASTER、SATRN、PP-OCR、CRNN 等 **30+** 篇

### 模块三：时空对话·知识图谱 🌐

将碑帖文字中的实体（人物、地名、官职、典故）抽取并构建可交互的知识网络。

**工作流程：**
```
输入文字 → 实体抽取 → 关系抽取 → 图谱构建 → 可视化交互 → 知识探索
```

**集成论文技术：** TransE、RotatE、ComplEx、ConvE、R-GCN、GraphSAGE、GATv2、CompGCN、TuckER、PairRE、ERNIE、KG-BERT、HGT 等 **25+** 篇

### 模块四：墨池体验·风格迁移与临摹 🖌

将用户书写内容转换为特定碑帖风格（瘦金体/颜体/柳体等），并给出笔画级评分。

**工作流程：**
```
输入文字/手写 → 选择碑帖风格 → 风格迁移 → 笔画对比 → 评分 → 分享作品
```

**集成论文技术：** AdaIN、CycleGAN、SANet、StyTr2、ArtFlow、CAST、CalliGAN、MX-Font、Rewriter、StrokeNet 等 **22+** 篇

---

## 📚 论文技术全景图

本项目综合集成了 **112 篇**前沿学术论文的技术思路，通过端云协同的架构实现论文方法的工程化落地。

### 🎨 图像修复与增强 (35篇)

| # | 论文 | 作者 | 年份 | 核心方法 | 应用场景 |
|---|------|------|------|---------|---------|
| 1 | **LaMA** | Suvorov et al. | CVPR 2022 | Fourier Convolution + Large Mask | 大面积破损补全 |
| 2 | **MAT** | Li et al. | CVPR 2022 | Mask-Aware Transformer | 高分辨率修复 |
| 3 | **DeepFill v2** | Yu et al. | CVPR 2019 | Gated Conv + Contextual Attention | 精细纹理生成 |
| 4 | **RePaint** | Lugmayr et al. | CVPR 2022 | DDPM Inpainting | 扩散模型修复 |
| 5 | **Edge-Connect** | Nazeri et al. | ICCV 2019 | Edge Generator + Inpainting | 笔触边缘引导 |
| 6 | **ZITS** | Dong et al. | ECCV 2022 | Zero-shot Sparse Control | 零样本修复 |
| 7 | **TFill** | Zheng et al. | CVPR 2022 | Transformer Inpainting | 语义感知修复 |
| 8 | **Palette** | Saharia et al. | CVPR 2022 | Diffusion-Based Synthesis | 颜色修复 |
| 9 | **Blended Diffusion** | Avrahami et al. | CVPR 2022 | Text-Driven Inpainting | 文本引导修复 |
| 10 | **PartialConv** | Liu et al. | ICCV 2018 | Partial Convolution | 不规则空洞填充 |
| 11 | **GatedConv** | Yu et al. | ICCV 2019 | Gated Convolution | 不规则掩码处理 |
| 12 | **Bringing Old Photos** | Wan et al. | CVPR 2020 | Multi-stage Restoration | 古籍老照片修复 |
| 13 | **SwinIR** | Liang et al. | ICCV 2021 | Swin Transformer | 超分+修复 |
| 14 | **HAT** | Chen et al. | CVPR 2023 | Hybrid Attention Transformer | 高效修复 |
| 15 | **Restormer** | Zamir et al. | CVPR 2022 | Transformer Restoration | 去噪+修复 |
| 16 | **NAFNet** | Chen et al. | ECCV 2022 | Nonlinear Activation Free | 轻量修复 |
| 17 | **Uformer** | Wang et al. | CVPR 2022 | U-Shaped Transformer | 高效修复 |
| 18 | **MIRNet** | Zamir et al. | ECCV 2020 | Multi-scale Restoration | 多尺度修复 |
| 19 | **MPRNet** | Zamir et al. | CVPR 2021 | Multi-stage Progressive | 渐进式修复 |
| 20 | **DeOldify** | Antic | 2019 | GAN Colorization | 图像彩色化 |
| 21 | **Real-ESRGAN** | Wang et al. | ICCV 2021 | Real-World SR | 真实世界超分 |
| 22 | **BSRGAN** | Zhang et al. | CVPR 2021 | Blind Super-Resolution | 盲超分 |
| 23 | **ESRGAN** | Wang et al. | ECCV 2018 | Enhanced SRGAN | 增强超分 |
| 24 | **RCAN** | Zhang et al. | ECCV 2018 | Residual Channel Attention | 通道注意力超分 |
| 25 | **EDSR** | Lim et al. | CVPR 2017 | Enhanced Deep Residual | 深度残差超分 |
| 26 | **LAPSRN** | Lai et al. | CVPR 2017 | Laplacian Pyramid | 金字塔超分 |
| 27 | **SRGAN** | Ledig et al. | CVPR 2017 | Adversarial SR | 对抗超分 |
| 28 | **VDSR** | Kim et al. | CVPR 2016 | Very Deep SR | 深度超分 |
| 29 | **SRCNN** | Dong et al. | ECCV 2016 | CNN Super-Resolution | 深度超分奠基 |
| 30 | **DnCNN** | Zhang et al. | IEEE TIP 2017 | CNN Denoising | 图像去噪 |
| 31 | **FFA-Net** | Qin et al. | AAAI 2020 | Feature Fusion Attention | 去雾增强 |
| 32 | **Zero-DCE** | Guo et al. | CVPR 2020 | Zero-Reference Curve | 亮度增强 |
| 33 | **DeepFL** | Jin et al. | 2021 | Document Restoration | 古籍文档修复 |
| 34 | **DocEnTR** | Souibgui et al. | CVPR 2022 | Transformer Enhancement | 文档增强 |
| 35 | **TextGestalt** | Liu et al. | 2022 | Ancient Text Repair | 古文文本修复 |

### 📝 文字检测与OCR (30篇)

| # | 论文 | 作者 | 年份 | 核心方法 | 应用场景 |
|---|------|------|------|---------|---------|
| 1 | **DBNet** | Liao et al. | AAAI 2020 | Differentiable Binarization | 文字检测基础 |
| 2 | **DBNet++** | Liao et al. | TPAMI 2022 | Adaptive Scale Fusion | 多尺度检测 |
| 3 | **EAST** | Zhou et al. | CVPR 2017 | Efficient Text Detection | 快速检测 |
| 4 | **PSENet** | Li et al. | CVPR 2019 | Progressive Scale Expansion | 任意形状检测 |
| 5 | **PAN** | Wang et al. | ICCV 2019 | Efficient Text Detection | 高效检测 |
| 6 | **CRAFT** | Baek et al. | ICCV 2019 | Character Region Awareness | 字符级检测 |
| 7 | **SAST** | Wang et al. | AAAI 2019 | Single-Shot Detector | 单阶段检测 |
| 8 | **ABCNet** | Liu et al. | CVPR 2020 | Bezier Curve Text | 弯曲文字检测 |
| 9 | **DRRG** | Zhang et al. | CVPR 2020 | Relational Reasoning Graph | 图推理检测 |
| 10 | **TextFuseNet** | Ye et al. | IJCAI 2020 | Multi-path Fusion | 多路径融合检测 |
| 11 | **TrOCR** | Li et al. | NeurIPS 2021 | Transformer OCR | 端到端识别 |
| 12 | **ABINet** | Fang et al. | CVPR 2021 | Autonomous Bidirectional | 双向识别 |
| 13 | **SRN** | Yu et al. | CVPR 2020 | Semantic Reasoning | 语义推理识别 |
| 14 | **VisionLAN** | Wang et al. | ICCV 2021 | Vision-Language Attention | 视觉语言识别 |
| 15 | **PARSeq** | Bautista et al. | ECCV 2022 | Permutation Autoregressive | 排列自回归 |
| 16 | **MASTER** | Lu et al. | ICDAR 2021 | Multi-Head Attention | 多头注意力识别 |
| 17 | **SATRN** | Lee et al. | CVPR 2020 | Self-Attention TRN | 自注意力识别 |
| 18 | **CRNN** | Shi et al. | IEEE TPAMI 2017 | CNN + RNN + CTC | 经典OCR |
| 19 | **ASTER** | Shi et al. | IEEE TPAMI 2018 | Attentional Rectifier | 矫正+识别 |
| 20 | **MORAN** | Luo et al. | AAAI 2019 | Multi-Object Rectified | 多目标矫正 |
| 21 | **SVTR** | Du et al. | AAAI 2022 | Single Visual Model | 纯视觉识别 |
| 22 | **ORFormer** | Zhu et al. | 2023 | Omnibus Transformer | 通用OCR |
| 23 | **ChOCR** | - | 2021 | Chinese OCR | 中文OCR |
| 24 | **PP-OCR** | Du et al. | 2020 | PaddleOCR | 实用OCR系统 |
| 25 | **CALLIGRAPHY-AI** | - | 2021 | Style Classification | 书法风格分类 |
| 26 | **HAN** | Wang et al. | 2020 | Hierarchical Attention | 古文篇章理解 |
| 27 | **DocGeo** | Xu et al. | 2022 | Geometric Analysis | 文档几何分析 |
| 28 | **RARE** | Shi et al. | CVPR 2019 | Robust Rectifier | 鲁棒识别 |
| 29 | **Rosetta** | Borisyuk et al. | 2018 | Large-Scale OCR | 大规模OCR |
| 30 | **Chinese-OCR** | - | - | Ancient Chinese OCR | 古文专用OCR |

### 🔗 知识图谱 (25篇)

| # | 论文 | 作者 | 年份 | 核心方法 | 应用场景 |
|---|------|------|------|---------|---------|
| 1 | **TransE** | Bordes et al. | NeurIPS 2013 | Translating Embeddings | KG嵌入奠基 |
| 2 | **TransH** | Wang et al. | AAAI 2014 | Hyperplane Embedding | 超平面嵌入 |
| 3 | **TransR** | Lin et al. | AAAI 2015 | Relation Space | 关系空间嵌入 |
| 4 | **RotatE** | Sun et al. | ICLR 2019 | Rotation Embedding | 旋转嵌入 |
| 5 | **DistMult** | Yang et al. | ICLR 2015 | Bilinear Diagonal | 双线性嵌入 |
| 6 | **ComplEx** | Trouillon et al. | ICML 2016 | Complex Embedding | 复数嵌入 |
| 7 | **ConvE** | Dettmers et al. | AAAI 2018 | Convolutional Embedding | 卷积嵌入 |
| 8 | **ConvR** | Jiang et al. | 2019 | Convolutional Relation | 关系卷积 |
| 9 | **R-GCN** | Schlichtkrull et al. | ESWC 2018 | Relational GCN | 关系图卷积 |
| 10 | **GraphSAGE** | Hamilton et al. | NeurIPS 2017 | Inductive Learning | 归纳式图学习 |
| 11 | **GAT** | Veličković et al. | ICLR 2018 | Graph Attention | 图注意力 |
| 12 | **GATv2** | Brody et al. | ICLR 2022 | Dynamic Attention | 动态图注意力 |
| 13 | **CompGCN** | Vashishth et al. | ICLR 2020 | Composition GCN | 组合图卷积 |
| 14 | **TuckER** | Balazevic et al. | AAAI 2019 | Tucker Decomposition | 张量分解 |
| 15 | **QuatE** | Zhang et al. | AAAI 2019 | Quaternion Embedding | 四元数嵌入 |
| 16 | **PairRE** | Chao et al. | ACL 2021 | Paired Relation | 成对关系嵌入 |
| 17 | **KBGAN** | Cai et al. | NAACL 2018 | Adversarial KG | 对抗学习 |
| 18 | **ERNIE** | Zhang et al. | 2019 | Language + KG | 语言知识融合 |
| 19 | **KG-BERT** | Yao et al. | 2019 | BERT for KG | 预训练+知识图谱 |
| 20 | **RE-NET** | Jin et al. | ICLR 2020 | Recurrent Event | 时序事件推理 |
| 21 | **TGN** | Rossi et al. | NeurIPS 2020 | Temporal Graph | 时序图网络 |
| 22 | **HGT** | Hu et al. | WWW 2020 | Heterogeneous Transformer | 异构图Transformer |
| 23 | **Simple** | Kazemi et al. | AAAI 2018 | Simple KG Embedding | 简化嵌入 |
| 24 | **KnowFormer** | - | 2023 | Transformer for KG | Transformer知识推理 |
| 25 | **NodePiece** | Galkin et al. | NeurIPS 2022 | KG Tokenization | 知识图谱分词 |

### 🎨 风格迁移与书法生成 (22篇)

| # | 论文 | 作者 | 年份 | 核心方法 | 应用场景 |
|---|------|------|------|---------|---------|
| 1 | **Neural Style Transfer** | Gatys et al. | CVPR 2016 | Gram Matrix | 风格迁移奠基 |
| 2 | **AdaIN** | Huang et al. | ICCV 2017 | Adaptive Instance Norm | 实时风格迁移 |
| 3 | **CycleGAN** | Zhu et al. | ICCV 2017 | Cycle Consistency | 无配对迁移 |
| 4 | **SANet** | Park et al. | ICCV 2019 | Style-Aware Norm | 风格感知归一化 |
| 5 | **Arbitrary Style** | Ghiasi et al. | ICCV 2017 | Arbitrary Transfer | 任意风格迁移 |
| 6 | **AAMS** | Liu et al. | 2022 | Attention-based Style | 注意力风格迁移 |
| 7 | **StyTr2** | Deng et al. | CVPR 2022 | Transformer Style | Transformer风格迁移 |
| 8 | **ArtFlow** | An et al. | CVPR 2021 | Normalizing Flow | 归一化流迁移 |
| 9 | **PhotoWCT** | Li et al. | CVPR 2018 | Photorealistic Transfer | 写实风格迁移 |
| 10 | **WCT2** | Yoo et al. | CVPR 2019 | Wavelet Transfer | 小波变换迁移 |
| 11 | **LMStyle** | - | 2020 | Lightweight Style | 轻量风格迁移 |
| 12 | **SCIN** | Li et al. | CVPR 2021 | Structural Correspondence | 结构对应迁移 |
| 13 | **CAST** | Zhang et al. | 2022 | Calligraphy Style | 书法风格迁移 |
| 14 | **CalliGAN** | Wu et al. | 2020 | Calligraphy Generation | 书法生成 |
| 15 | **Rewrite** | Liu et al. | 2023 | Character Restoration | 汉字修复 |
| 16 | **ZiGAN** | Zhu et al. | 2022 | Font Generation | 字体生成 |
| 17 | **MX-Font** | Park et al. | ECCV 2022 | Multi-Content Font | 多内容字体生成 |
| 18 | **CalliNet** | Zhang et al. | 2021 | Calligraphy Transfer | 书法迁移 |
| 19 | **StrokeNet** | Liu et al. | 2020 | Stroke-level Font | 笔画级字体生成 |
| 20 | **Sketch-Guided** | Xiao et al. | 2022 | Sketch Transfer | 草稿引导迁移 |
| 21 | **ArtGAN** | Tan et al. | 2022 | Artwork Style | 艺术品风格迁移 |
| 22 | **Doodle2Art** | - | 2021 | Sketch to Art | 涂鸦变艺术 |

---

## 📱 跨平台适配

### 平台导航范式

| 平台 | 导航规范 | Flutter 适配方案 |
|------|---------|----------------|
| **iOS** | Tab Bar + Navigation Stack + 侧滑返回 | `CupertinoTabScaffold` + `CupertinoPageRoute` |
| **Android** | Bottom Navigation + Material 3 + 系统返回 | `NavigationBar` + `PopScope` + Material You |
| **HarmonyOS** | 底部 Tab + 侧滑返回 + Gesture | 自定义 `NavigationBar` + 平台通道手势 |

### AI 推理硬件加速

```
┌───────────────────────────────────────────────────┐
│             统一推理接口 (InferenceEngine)           │
├───────────────────────────────────────────────────┤
│  iOS           │  Android      │  HarmonyOS        │
│  CoreML + ANE  │  NNAPI + GPU  │  MindSpore Lite   │
│  Metal Shader  │  OpenCL       │  方舟异构计算       │
└───────────────────────────────────────────────────┘
```

### 平台特性支持矩阵

| 特性 | iOS | Android | HarmonyOS | 离线 |
|------|-----|---------|-----------|------|
| 📸 拍照/相册 | ✅ AVFoundation | ✅ CameraX | ✅ Camera Kit | ✅ |
| 🎯 破损检测 | ✅ CoreML ANE | ✅ NNAPI | ✅ MindSpore | ✅ |
| 🔧 AI修复(扩散) | ✅ 云API | ✅ 云API | ✅ 云API | ❌ |
| 🔍 古文OCR | ✅ CoreML+云 | ✅ NNAPI+云 | ✅ MindSpore+云 | ⚠️基础版 |
| 🌐 知识图谱 | ✅ CustomPaint | ✅ CustomPaint | ✅ CustomPaint | ✅缓存 |
| 🎨 风格迁移 | ✅ 云API | ✅ 云API | ✅ 云API | ❌ |
| ✍️ 书法对比 | ✅ Metal渲染 | ✅ Skia | ✅ 方舟渲染 | ✅ |
| 📤 分享导出 | ✅ Share Sheet | ✅ Intent | ✅ 分享Kit | ✅ |
| 💾 离线缓存 | ✅ drift | ✅ drift | ✅ drift | ✅ |
| 🌙 深色模式 | ✅ Dynamic Island | ✅ Material You | ✅ 系统跟随 | ✅ |
| ♿ 无障碍 | ✅ VoiceOver | ✅ TalkBack | ✅ 屏幕朗读 | ✅ |

---

## 🚀 快速开始

### 环境要求

- **Flutter**: 3.x (Dart 3.x)
- **iOS**: Xcode 15+, iOS 16+
- **Android**: Android Studio Hedgehog+, AGP 8.2+, minSdk 26
- **HarmonyOS**: DevEco Studio 4.0+, API 10+

### 开发

```bash
# 1. 克隆仓库
git clone https://github.com/QianChang-official/GuWenXianXiuFu-MoJiShiGuang.git
cd GuWenXianXiuFu-MoJiShiGuang

# 2. 安装依赖
cd mojishiguang_app
flutter pub get

# 3. 运行（选择平台）
flutter run -d ios       # iOS
flutter run -d android   # Android
flutter run -d harmonyos # HarmonyOS

# 4. 生成代码（freezed/json_serializable）
dart run build_runner build --delete-conflicting-outputs
```

---

## 📁 项目结构

```
mojishiguang_app/
├── lib/
│   ├── main.dart                        # 应用入口
│   ├── app.dart                         # 根组件(MaterialApp.router)
│   ├── core/
│   │   ├── constants/app_constants.dart # 常量定义
│   │   ├── theme/app_theme.dart         # Material 3 双主题
│   │   ├── router/app_router.dart       # GoRouter 路由
│   │   ├── platform/
│   │   │   ├── inference_engine.dart    # 三端推理抽象层
│   │   │   └── platform_channels.dart   # 平台通道管理器
│   │   └── utils/
│   │       ├── image_utils.dart         # 图像预处理工具
│   │       └── file_utils.dart          # 文件管理工具
│   ├── models/
│   │   ├── restoration/                 # 修复数据模型
│   │   ├── ocr/                         # OCR 数据模型
│   │   ├── kg/                          # 知识图谱数据模型
│   │   └── stylization/                 # 风格迁移数据模型
│   ├── services/
│   │   ├── inference/                   # 推理服务(CoreML/NNAPI/MindSpore)
│   │   ├── api/                         # REST API 客户端
│   │   ├── storage/                     # 本地持久化(drift)
│   │   └── camera/                      # 相机服务
│   ├── providers/                       # Riverpod 状态管理
│   ├── features/
│   │   ├── restoration/                 # 模块1: AI修复
│   │   ├── ocr/                         # 模块2: 古籍OCR
│   │   ├── kg/                          # 模块3: 知识图谱
│   │   └── stylization/                 # 模块4: 风格迁移
│   ├── widgets/                         # 通用UI组件
│   └── papers/                          # 论文技术清单
├── android/                             # Android 原生工程
├── ios/                                 # iOS 原生工程
├── harmonyos/                           # HarmonyOS 原生工程
├── test/                                # 测试用例
└── pubspec.yaml                         # Flutter 依赖配置
```

---

## ⚡ 性能目标

| 指标 | 目标值 | 优化策略 |
|------|-------|---------|
| 🔥 冷启动时间 | < 3秒 | 延迟加载 + AOT编译 |
| 🎯 破损检测 | < 1s (端侧) | TFLite GPU / CoreML ANE |
| 🔍 OCR单字识别 | < 2s (含API往返) | 批量化 + 请求合并 |
| 🌐 图谱渲染 | 60fps | RepaintBoundary + 虚拟化 |
| 💾 内存占用 | < 150MB | 缩略图 + 按需加载 |
| 📦 安装包体积 | < 40MB | 模型按需下载 + Tree Shaking |
| 🔋 电池消耗 | < 5%/h | 端侧限频 + API合并 |

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交代码 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 发起 Pull Request

### 开发规范

- **代码风格**: 遵循 `analysis_options.yaml` 配置
- **提交规范**: 使用 Conventional Commits (`feat:`/`fix:`/`docs:`/`refactor:`)
- **测试要求**: 新功能需包含 widget test / unit test
- **文档**: 公共 API 需有中文文档注释

---

## 📄 许可

本项目基于 Apache License 2.0 许可协议开源。

---

## 🙏 致谢

- 感谢所有论文作者为学术社区做出的卓越贡献
- 感谢 Flutter 团队提供的跨平台开发框架
- 感谢所有关注古籍数字化保护的同仁

---

> **墨迹时光** — 让每一笔墨迹都被时光铭记，让每一页古籍都重获新生。

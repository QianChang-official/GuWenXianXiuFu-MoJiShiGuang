---
name: mojishiguang-ancient-text-restoration
description: "古籍智能修复与数字人文分析 Skill — 封装古籍文献修复科研全链路：从图像采集、破损检测、AI 修复、文字识别到知识图谱构建"
author: "墨迹时光团队"
version: "1.0.0"
---

# 📜 古籍智能修复与数字人文分析 Skill

> **书生科学发现平台 SCP — 科研能力封装赛道**  
> 将古籍修复与数字人文研究中的核心方法论封装为可复用的标准化 Skill

---

## 一、能力概述

本 Skill 覆盖古籍文献修复与数字人文研究的完整科研链路：

```
文献调研 → 图像采集 → 破损检测 → 方法选型 → AI 修复 → 
质量评估 → 文字识别 → 知识图谱 → 成果撰写 → 论文发表
```

## 二、使用场景

| 场景 | 目标用户 | 输入 | 输出 |
|------|---------|------|------|
| 古籍数字化修复 | 文博机构研究员 | 古籍扫描件/照片 | 修复后图像 + 质量评估报告 |
| 碑帖文字识别 | 历史研究者 | 碑帖图片 | 识别文字 + 字典释义 |
| 历史知识图谱 | 人文学者 | 碑帖文本 | 可视化知识网络 |
| 书法风格分析 | 书法研究者 | 书法作品 | 风格分析 + 临摹评分 |

---

## 三、科研工作流（详细步骤）

### Step 1：文献调研

```python
# 1.1 确定研究方向
topic = "古籍图像修复与数字人文分析"

# 1.2 关键词生成
keywords = [
    "ancient document restoration",
    "image inpainting calligraphy",
    "Chinese ancient OCR",
    "historical knowledge graph",
    "calligraphy style transfer"
]

# 1.3 论文检索（建议数据库）
databases = [
    "arXiv (cs.CV, cs.CL)",
    "CVF Open Access (CVPR/ICCV)",
    "ACL Anthology",
    "Google Scholar"
]

# 1.4 论文筛选标准
criteria = {
    "顶会优先": ["CVPR", "ICCV", "ECCV", "NeurIPS", "AAAI", "ICLR"],
    "时间范围": "2016-2026",
    "相关性": "图像修复/OCR/知识图谱/风格迁移",
    "代码开源": "优先选择有开源实现的工作"
}
```

### Step 2：图像采集与预处理

```
输入：古籍扫描件 / 碑帖照片 / 手机拍摄
输出：规范化图像 + 破损标注

预处理管线:
1. 灰度化 + 直方图均衡化
2. 几何校正（透视变换）
3. 去噪（高斯滤波 / 中值滤波）
4. 对比度增强（CLAHE）
5. 色彩校正（白平衡 / 色调映射）
```

### Step 3：破损检测与 Mask 生成

```python
# 破损检测方法论（端侧轻量方案）
method = "Canny 边缘检测 + 自适应阈值 + 连通域分析"
# 或使用轻量 UNet 模型（ONNX Runtime 推理）

# 破损类型分类
damage_types = {
    "worm_eaten": "虫蛀",
    "water_stain": "水渍",
    "missing_corner": "缺角",
    "fold_crack": "折裂",
    "fuzzy": "模糊/褪色",
    "stain": "污渍"
}

# 输出: DamageMask (binary mask + 破损区域列表)
```

### Step 4：修复方法选型

| 破损类型 | 推荐方法 | 论文来源 | 部署位置 |
|---------|---------|---------|---------|
| 大面积缺损 | LaMa | Suvorov et al., CVPR 2022 | 云侧 |
| 高精度语义修复 | MAT | Li et al., CVPR 2022 | 云侧 |
| 局部划痕 | DeepFill v2 | Yu et al., ICCV 2019 | 端侧 |
| 笔触边缘引导 | Edge-Connect | Nazeri et al., ICCV 2019 | 端侧 |
| 扩散模型修复 | RePaint | Lugmayr et al., CVPR 2022 | 云侧 |
| 古文文字修复 | TextGestalt | Liu et al., NeurIPS 2022 | 云侧 |
| 超分增强 | SwinIR | Liang et al., ICCV 2021 | 云侧 |
| 端侧轻量修复 | NAFNet | Chen et al., ECCV 2022 | 端侧 |

**选型策略**：
- 小面积破损（<5% 面积）→ 端侧方法（DeepFill v2 / Edge-Connect）
- 大面积破损（>5% 面积）→ 云侧方法（LaMa / MAT）
- 需要多样本探索 → 扩散模型（RePaint）
- 古文文字恢复 → TextGestalt（语义引导）

### Step 5：AI 修复执行

```python
def execute_restoration(image, mask, method, params):
    """
    执行 AI 修复
    Args:
        image: 输入图像
        mask: 破损检测 Mask
        method: 修复方法标识
        params: 方法参数
    Returns:
        restored: 修复后图像
        metrics: 质量评估指标
        processing_time: 处理耗时
    """
    # 1. 预处理（resize, normalize）
    # 2. 模型推理（端侧/云侧）
    # 3. 后处理（色调匹配, 风格一致性）
    # 4. 质量评估（PSNR, SSIM, LPIPS）
    return restored, metrics, processing_time
```

### Step 6：质量评估

```python
# 客观指标
metrics = {
    "PSNR": "峰值信噪比 (>30dB 为良好)",
    "SSIM": "结构相似性 (>0.85 为良好)",
    "LPIPS": "感知相似度 (<0.1 为良好)",
    "FID": "Frechet 距离 (<50 为良好)",
    "NIMA": "无参考图像质量评分 (0-100)"
}

# 古籍专用指标
ancient_metrics = {
    "text_readability": "文本可读性评分 (基于 OCR 置信度)",
    "stroke_continuity": "笔触连续性评分",
    "color_consistency": "色彩一致性评分"
}
```

### Step 7：文字识别与字典关联

```python
# OCR 流程
def ancient_ocr_pipeline(image):
    # 1. 文字区域检测（DBNet++ / EAST / CRAFT）
    regions = detect_text_regions(image)
    
    # 2. 文字识别（TrOCR / ABINet / PARSeq）
    text = recognize_text(regions)
    
    # 3. 候选字排序
    candidates = rank_candidates(text)
    
    # 4. 字典关联（《说文解字》《康熙字典》等）
    dictionary_lookup(candidates)
    
    return text, candidates
```

### Step 8：知识图谱构建

```python
# 实体关系抽取流程
def build_knowledge_graph(text):
    # 1. LLM 实体抽取（人物/地名/官职/朝代/文献/事件）
    entities = extract_entities(text)
    
    # 2. 关系抽取（师从/友人/父子/任职/创作等 11 种关系）
    relations = extract_relations(entities)
    
    # 3. 图谱构建与可视化
    graph = KnowledgeGraph(entities=entities, relations=relations)
    
    # 4. 力导向布局 + CustomPainter 渲染
    visualize_graph(graph)
    
    return graph
```

### Step 9：风格迁移与书法分析

```python
def calligraphy_style_transfer(input_image, target_style):
    """
    碑帖风格迁移
    支持风格：瘦金体/颜体/柳体/欧体/赵体/王羲之行书等
    """
    # 1. 风格编码（AdaIN / StyTr2）
    style_code = encode_style(target_style)
    
    # 2. 风格迁移
    result = transfer_style(input_image, style_code)
    
    # 3. 笔画对比评分（DTW 骨架相似度）
    score = compare_strokes(input_image, result)
    
    return result, score
```

### Step 10：成果撰写模板

```markdown
# 论文标题：基于多模态 AI 的古籍残片智能修复方法研究

## 摘要
[300 字以内，概述研究背景、方法、实验和结论]

## 1. 引言
- 古籍修复现状与挑战（引用统计数据）
- 现有方法的局限性
- 本文贡献

## 2. 相关工作
- 图像修复方法综述（LaMa/MAT/RePaint 等）
- 古文 OCR 方法综述（DBNet++/TrOCR/ABINet 等）
- 知识图谱方法综述（TransE/RotatE/GAT 等）

## 3. 方法
### 3.1 端云协同修复框架
### 3.2 破损检测与自适应方法选型
### 3.3 古文 OCR 识别与字典约束
### 3.4 知识图谱构建与可视化

## 4. 实验
### 4.1 数据集
### 4.2 评价指标
### 4.3 实验结果与分析
### 4.4 消融实验

## 5. 结论与展望

## 参考文献
[112 篇参考文献，按模块分类]
```

---

## 四、技术栈速查

| 类别 | 推荐选型 |
|------|---------|
| 图像修复 (云侧) | LaMa / MAT / RePaint / Palette |
| 图像修复 (端侧) | DeepFill v2 / Edge-Connect / NAFNet |
| 超分辨率 | SwinIR / Real-ESRGAN / HAT |
| 文档增强 | DocEnTR / TextGestalt / DeepFL |
| 文字检测 | DBNet++ / EAST / CRAFT |
| 文字识别 | TrOCR / ABINet / PARSeq |
| 知识图谱嵌入 | TransE / RotatE / ComplEx |
| 图神经网络 | GATv2 / R-GCN / CompGCN |
| 风格迁移 | AdaIN / StyTr2 / SANet |
| 书法生成 | CalliGAN / StrokeNet / MX-Font |

---

## 五、实验评估模板

### 数据集准备
```
1. 获取古籍扫描件（建议从公开数字图书馆获取）
2. 人工标注破损区域（建议使用 LabelMe 或 COCO Annotator）
3. 划分训练/验证/测试集（8:1:1）
```

### 评估指标模板
```python
results = {
    "method": "LaMa",
    "psnr": 32.5,
    "ssim": 0.912,
    "lpips": 0.045,
    "fid": 42.3,
    "nima": 78.5,
    "text_readability": 0.89,
    "avg_latency_ms": 850,
    "model_size_mb": 78.5
}
```

---

## 六、常见问题

### Q1: 古籍 OCR 准确率低怎么处理？
- 增加字典约束（《说文解字》词汇表）
- 使用多模型投票（TrOCR + ABINet + PARSeq 集成）
- 引入上下文语言模型排序候选字

### Q2: 修复结果有伪影怎么办？
- 使用后处理（色调匹配 + 风格一致性调整）
- 尝试不同的修复方法（扩散模型通常更平滑）
- 调整 mask dilation 参数

### Q3: 没有 GPU 怎么跑修复？
- 端侧轻量模型：DeepFill v2 (42MB), NAFNet (18MB)
- 使用 CPU 推理（ONNX Runtime CPU backend）
- 批量小图处理

---

## 七、参考论文

完整 112 篇论文清单见项目 `lib/papers/` 目录下的以下文件：
- `restoration_papers.dart` — 图像修复与增强（35 篇）
- `ocr_papers.dart` — 文字检测与 OCR（30 篇）
- `kg_papers.dart` — 知识图谱（25 篇）
- `style_papers.dart` — 风格迁移与书法生成（22 篇）

---

> 本 Skill 由「墨迹时光」团队维护，适用于古籍数字化保护与数字人文分析的科研工作流。
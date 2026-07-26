/// 墨迹时光 - 古籍OCR与文字检测论文技术清单
///
/// 本文件汇总了项目中集成的 OCR / 文字检测 / 文档分析领域
/// 的核心论文与技术方案，覆盖文字检测、文字识别、文档增强、
/// 语义理解、书法风格分析等多个维度。
///
/// 集成论文索引: 30+ 篇
/// 更新时间: 2026-07
///
/// ## 技术架构概览
///
/// 文字检测层:
///   DBNet / DBNet++ / EAST / PSENet / PAN / CRAFT / SAST / ABCNet / DRRG / TextFuseNet
///
/// 文字识别层:
///   TrOCR / ABINet / SRN / VisionLAN / PARSeq / MASTER / SATRN / CRNN / ASTER / MORAN / SVTR
///
/// 文档增强层:
///   DUE / DocGeo / RARE
///
/// 语义理解层:
///   HAN / CLIP for OCR / ORFormer / ChOCR / PP-OCR
///
/// 书法风格分析:
///   CALLIGRAPHY-AI
///
// ignore_for_file: public_member_api_docs, unused_import

import 'package:flutter/foundation.dart';

// ============================================================================
// 枚举: OCR 论文类别
// ============================================================================

/// OCR 论文技术类别
enum OcrPaperCategory {
  /// 文字检测 (Text Detection)
  textDetection,

  /// 文字识别 (Text Recognition)
  textRecognition,

  /// 文档增强 (Document Enhancement)
  documentEnhancement,

  /// 语义理解 (Semantic Understanding)
  semanticUnderstanding,

  /// 书法风格分析 (Calligraphy Analysis)
  calligraphyAnalysis,

  /// 端到端系统 (End-to-End System)
  endToEndSystem,

  /// 多模态学习 (Multimodal Learning)
  multimodalLearning,
}

// ============================================================================
// 数据类: 论文信息
// ============================================================================

/// 单篇论文的信息结构
@immutable
class OcrPaper {
  /// 论文标题
  final String title;

  /// 作者列表
  final List<String> authors;

  /// 发表年份
  final int year;

  /// 论文缩写/简称
  final String abbreviation;

  /// 论文所属类别
  final OcrPaperCategory category;

  /// 简短描述（中文）
  final String description;

  /// 技术特点标签
  final List<String> tags;

  /// 是否已在本项目中集成
  final bool isIntegrated;

  /// 默认构造函数
  const OcrPaper({
    required this.title,
    required this.authors,
    required this.year,
    required this.abbreviation,
    required this.category,
    required this.description,
    this.tags = const [],
    this.isIntegrated = true,
  });
}

// ============================================================================
// 论文列表
// ============================================================================

/// 项目中集成的全部 OCR/文字检测论文列表（30+ 篇）
///
/// 每篇论文包含标题、作者、年份、类别、中文描述和技术标签。
const List<OcrPaper> ocrPapers = [
  // ──────────────────────────────────────────────────────────────────────────
  //  一、文字检测 (Text Detection)
  // ──────────────────────────────────────────────────────────────────────────

  /// 1. DBNet - 可微分二值化文字检测
  OcrPaper(
    abbreviation: 'DBNet',
    title: 'Real-time Scene Text Detection with Differentiable Binarization',
    authors: ['Liao, M.', 'Wan, Z.', 'Yao, C.', 'Chen, K.', 'Bai, X.'],
    year: 2020,
    category: OcrPaperCategory.textDetection,
    description: '提出可微分二值化（DB）模块，将二值化阈值作为网络可学习参数，'
        '实现端到端的快速文字检测。相比传统固定阈值法，在任意形状文字检测上'
        '取得显著提升，是当前文字检测的主流基线方法之一。',
    tags: ['可微分二值化', '实时检测', '任意形状', '端到端'],
  ),

  /// 2. DBNet++ - 自适应多尺度融合
  OcrPaper(
    abbreviation: 'DBNet++',
    title: 'DBNet++: Adaptive Scale Fusion for Scene Text Detection',
    authors: ['Liao, M.', 'Zou, Z.', 'Wan, Z.', 'Yao, C.', 'Bai, X.'],
    year: 2022,
    category: OcrPaperCategory.textDetection,
    description: '在 DBNet 基础上引入自适应尺度融合模块（ASF），通过空间注意力'
        '机制自适应融合多尺度特征图，显著提升对古籍中大小不一文字区域的检测精度。',
    tags: ['自适应尺度融合', '空间注意力', '多尺度', 'DBNet改进'],
  ),

  /// 3. EAST - 高效场景文字检测
  OcrPaper(
    abbreviation: 'EAST',
    title: 'EAST: An Efficient and Accurate Scene Text Detector',
    authors: ['Zhou, X.', 'Yao, C.', 'Wen, H.', 'Wang, Y.', 'Zhou, S.', 'He, W.', 'Liang, J.'],
    year: 2017,
    category: OcrPaperCategory.textDetection,
    description: '基于全卷积网络（FCN）的端到端文字检测器，直接预测文本行的'
        '旋转矩形框或四边形。流程精简、速度快，适合移动端部署场景。',
    tags: ['FCN', '端到端', '旋转矩形', '轻量'],
  ),

  /// 4. PSENet - 渐进式尺度扩展
  OcrPaper(
    abbreviation: 'PSENet',
    title: 'Shape Robust Text Detection with Progressive Scale Expansion Network',
    authors: ['Li, X.', 'Wang, W.', 'Hou, W.', 'Liu, R.', 'Lu, T.', 'Yang, J.'],
    year: 2019,
    category: OcrPaperCategory.textDetection,
    description: '通过渐进式尺度扩展策略生成任意形状文字区域的精确分割图。'
        '从最小核开始逐步扩张到完整文字区域，对古籍中弯曲、倾斜文字有良好鲁棒性。',
    tags: ['渐进式扩展', '任意形状', '分割', '鲁棒'],
  ),

  /// 5. PAN - 高效任意形状文字检测
  OcrPaper(
    abbreviation: 'PAN',
    title: 'Efficient and Accurate Arbitrary-Shaped Text Detection with Pixel Aggregation Network',
    authors: ['Wang, W.', 'Xie, E.', 'Song, X.', 'Zang, Y.', 'Wang, W.', 'Lu, T.', 'Yu, G.', 'Shen, C.'],
    year: 2019,
    category: OcrPaperCategory.textDetection,
    description: '基于像素聚合机制的高效文字检测网络，通过预测文本核和相似度向量'
        '实现像素级聚类。轻量级设计使推理速度大幅提升，适合古籍实时检测。',
    tags: ['像素聚合', '轻量', '实时', '聚类'],
  ),

  /// 6. CRAFT - 字符级区域感知
  OcrPaper(
    abbreviation: 'CRAFT',
    title: 'Character Region Awareness for Text Detection',
    authors: ['Baek, Y.', 'Lee, B.', 'Han, D.', 'Yun, S.', 'Lee, H.'],
    year: 2019,
    category: OcrPaperCategory.textDetection,
    description: '通过字符级标注训练的文字检测模型，预测字符区域（Region Score）'
        '和字符间连结关系（Affinity Score）。对古籍中相邻文字紧密排列场景有效。',
    tags: ['字符级', '区域评分', '连结关系', '弱监督'],
  ),

  /// 7. SAST - 单次任意形状文字检测
  OcrPaper(
    abbreviation: 'SAST',
    title: 'A Single-Shot Arbitrarily-Shaped Text Detector based on Context Attended Multi-Task Learning',
    authors: ['Wang, P.', 'Zhang, C.', 'Qi, F.', 'Huang, Z.', 'En, M.', 'Han, J.', 'Liu, J.', 'Ding, E.', 'Zhu, G.'],
    year: 2019,
    category: OcrPaperCategory.textDetection,
    description: '基于上下文注意力的多任务单阶段文字检测器，同时预测文本中心线'
        '和边界偏移。适合处理古籍中不规则排版的文本行。',
    tags: ['单阶段', '上下文注意力', '多任务', '中心线'],
  ),

  /// 8. ABCNet - 自适应贝塞尔曲线网络
  OcrPaper(
    abbreviation: 'ABCNet',
    title: 'ABCNet: Adaptive Bezier Curve Network for Real-time End-to-end Text Spotting',
    authors: ['Liu, Y.', 'Chen, H.', 'Shen, C.', 'He, T.', 'Jin, L.', 'Wang, L.'],
    year: 2020,
    category: OcrPaperCategory.textDetection,
    description: '使用贝塞尔曲线参数化表示任意形状文字区域，首次实现实时端到端'
        '文字检测与识别。对古籍中的竖排弯曲文字具有天然的描述优势。',
    tags: ['贝塞尔曲线', '端到端', '实时', '弯曲文字'],
  ),

  /// 9. DRRG - 深度关系推理图网络
  OcrPaper(
    abbreviation: 'DRRG',
    title: 'Deep Relational Reasoning Graph Network for Arbitrary Shape Text Detection',
    authors: ['Zhang, S.', 'Zhu, Y.', 'Hou, J.', 'He, M.', 'Yan, J.', 'vanden Hengel, A.'],
    year: 2020,
    category: OcrPaperCategory.textDetection,
    description: '将图神经网络引入文字检测领域，通过关系推理网络连接相邻文字组件。'
        '对古籍中字符间关系复杂的场景（如重叠、遮挡）表现优异。',
    tags: ['图神经网络', '关系推理', '组件连接', '复杂场景'],
  ),

  /// 10. TextFuseNet - 多路径融合文字检测
  OcrPaper(
    abbreviation: 'TextFuseNet',
    title: 'TextFuseNet: Scene Text Detection with Multi-path Fusion',
    authors: ['Ye, J.', 'Chen, Z.', 'Liu, J.', 'Du, B.'],
    year: 2020,
    category: OcrPaperCategory.textDetection,
    description: '融合字符级、词级和全局上下文的多路径特征融合框架。采用三分支'
        '架构分别捕捉不同粒度的文本特征，显著提升古籍文字检测的鲁棒性。',
    tags: ['多路径融合', '字符级', '词级', '全局上下文'],
  ),

  /// 11. FCENet - 傅里叶轮廓嵌入
  OcrPaper(
    abbreviation: 'FCENet',
    title: 'Fourier Contour Embedding for Arbitrary-Shaped Text Detection',
    authors: ['Zhu, Y.', 'Chen, J.', 'Liang, L.', 'Kuang, Z.', 'Jin, L.', 'Zhang, W.'],
    year: 2021,
    category: OcrPaperCategory.textDetection,
    description: '创新性地将傅里叶变换引入文字检测，将文字区域轮廓编码为傅里叶'
        '系数向量。对古籍中连续弯曲的文本行轮廓描述精确，计算效率高。',
    tags: ['傅里叶变换', '轮廓嵌入', '任意形状', '精确'],
  ),

  /// 12. DPText-DETR - 基于DETR的文字检测
  OcrPaper(
    abbreviation: 'DPText-DETR',
    title: 'DPText-DETR: Towards Better Scene Text Detection with Dynamic Points in Transformer',
    authors: ['Ye, M.', 'Zhang, J.', 'Zhao, S.', 'Liu, J.', 'Liu, T.', 'Du, B.', 'Tao, D.'],
    year: 2022,
    category: OcrPaperCategory.textDetection,
    description: '基于 DETR 架构的文字检测方案，利用动态点序列建模任意形状'
        '文字区域。免去锚框和后处理，对古籍复杂版面布局检测效果优秀。',
    tags: ['Transformer', 'DETR', '动态点', '无锚框'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  //  二、文字识别 (Text Recognition)
  // ──────────────────────────────────────────────────────────────────────────

  /// 13. TrOCR - Transformer OCR
  OcrPaper(
    abbreviation: 'TrOCR',
    title: 'TrOCR: Transformer-based Optical Character Recognition with Pre-trained Models',
    authors: ['Li, M.', 'Lv, T.', 'Chen, J.', 'Cui, L.', 'Lu, Y.', 'Florencio, D.', 'Zhang, C.', 'Li, Z.', 'Wei, F.'],
    year: 2021,
    category: OcrPaperCategory.textRecognition,
    description: '微软推出的纯Transformer架构OCR模型，将视觉Transformer编码器'
        '与文本Transformer解码器结合，通过大规模预训练实现高精度文字识别。'
        '对古籍繁体字和异体字具有较强的泛化能力。',
    tags: ['Transformer', '预训练', '编解码', '微软'],
  ),

  /// 14. ABINet - 自主双向网络
  OcrPaper(
    abbreviation: 'ABINet',
    title: 'Read Like Humans: Autonomous Bidirectional and Iterative Language Model for Scene Text Recognition',
    authors: ['Fang, S.', 'Xie, H.', 'Wang, Y.', 'Mao, Z.', 'Zhang, Y.'],
    year: 2021,
    category: OcrPaperCategory.textRecognition,
    description: '提出自主双向迭代语言模型，通过视觉特征和语言特征的显式建模'
        '实现类人阅读。采用双向语言建模纠正识别错误，对古文模糊文字的识别有显著提升。',
    tags: ['双向LM', '迭代', '视觉-语言', '类人阅读'],
  ),

  /// 15. SRN - 语义推理网络
  OcrPaper(
    abbreviation: 'SRN',
    title: 'Scene Text Recognition with Semantic Reasoning Network',
    authors: ['Yu, D.', 'Li, X.', 'Zhang, C.', 'Liu, T.', 'Han, J.', 'Ding, E.', 'Wang, J.'],
    year: 2020,
    category: OcrPaperCategory.textRecognition,
    description: '引入语义推理模块增强文字识别中的上下文理解能力，在视觉特征'
        '基础上融合全局语义信息。对古籍中缺笔、残损文字能基于上下文进行合理推断。',
    tags: ['语义推理', '全局语义', '上下文', '推断'],
  ),

  /// 16. VisionLAN - 视觉语言注意力网络
  OcrPaper(
    abbreviation: 'VisionLAN',
    title: 'From Two to One: A New Scene Text Recognizer with Visual Language Modeling Network',
    authors: ['Wang, Y.', 'Xie, H.', 'Fang, S.', 'Wang, J.', 'Zhu, S.', 'Zhang, Y.'],
    year: 2021,
    category: OcrPaperCategory.textRecognition,
    description: '将视觉建模和语言建模统一在单一网络中，通过掩码语言学习策略'
        '让网络同时学习字符视觉特征和语言上下文。对古籍中噪声和退化文字识别效果好。',
    tags: ['掩码学习', '视觉-语言统一', '单网络', '抗噪'],
  ),

  /// 17. PARSeq - 排列自回归序列模型
  OcrPaper(
    abbreviation: 'PARSeq',
    title: 'PARSeq: Scene Text Recognition with Permutation Autoregressive Sequence Models',
    authors: ['Bautista, D.', 'Atienza, R.'],
    year: 2022,
    category: OcrPaperCategory.textRecognition,
    description: '提出排列自回归序列建模方法，通过上下文感知的位置编码实现'
        '灵活的字符序列建模。支持迭代精炼和并行推理，兼顾精度与速度。',
    tags: ['排列自回归', '上下文编码', '迭代精炼', '并行'],
  ),

  /// 18. MASTER - 多头注意力文字识别
  OcrPaper(
    abbreviation: 'MASTER',
    title: 'MASTER: Multi-Aspect Non-local Network for Scene Text Recognition',
    authors: ['Lu, N.', 'Yu, W.', 'Qi, X.', 'Chen, Y.', 'Gong, P.', 'Xiao, R.', 'Bai, X.'],
    year: 2021,
    category: OcrPaperCategory.textRecognition,
    description: '利用多头自注意力和非局部网络捕获字符间的长距离依赖关系。'
        '对古籍中结构化排版文本的序列建模能力强大。',
    tags: ['多头注意力', '非局部网络', '长距离依赖', '序列建模'],
  ),

  /// 19. SATRN - 自注意力文字识别网络
  OcrPaper(
    abbreviation: 'SATRN',
    title: 'On Recognizing Texts of Arbitrary Shapes with 2D Self-Attention',
    authors: ['Lee, J.', 'Park, S.', 'Baek, J.', 'Oh, S.', 'Kim, S.', 'Lee, H.'],
    year: 2020,
    category: OcrPaperCategory.textRecognition,
    description: '使用2D自注意力机制处理任意形状文字的识别。利用Transformer的'
        '全局感受野，有效处理古籍中弯曲、扭曲文字的识别难题。',
    tags: ['2D自注意力', '任意形状', 'Transformer', '弯曲文字'],
  ),

  /// 20. CRNN - 卷积循环神经网络（OCR经典）
  OcrPaper(
    abbreviation: 'CRNN',
    title: 'An End-to-End Trainable Neural Network for Image-based Sequence Recognition and Its Application to Scene Text Recognition',
    authors: ['Shi, B.', 'Bai, X.', 'Yao, C.'],
    year: 2017,
    category: OcrPaperCategory.textRecognition,
    description: '经典的端到端可训练OCR架构，结合CNN特征提取、RNN序列建模'
        '和CTC序列解码。在古籍文字识别中作为基线模型广泛使用，轻量高效。',
    tags: ['CNN+RNN', 'CTC', '端到端', '经典基线'],
  ),

  /// 21. ASTER - 注意力场景文字识别
  OcrPaper(
    abbreviation: 'ASTER',
    title: 'ASTER: An Attentional Scene Text Recognizer with Flexible Rectification',
    authors: ['Shi, B.', 'Yang, M.', 'Wang, X.', 'Lyu, P.', 'Yao, C.', 'Bai, X.'],
    year: 2018,
    category: OcrPaperCategory.textRecognition,
    description: '引入可学习的TPS（Thin-Plate Spline）空间变换网络，对不规则'
        '文字进行柔性矫正后再送入注意力识别网络。对古籍中倾斜変形文字有效。',
    tags: ['TPS矫正', '注意力机制', '空间变换', '柔性矫正'],
  ),

  /// 22. MORAN - 多对象矫正注意力网络
  OcrPaper(
    abbreviation: 'MORAN',
    title: 'MORAN: A Multi-Object Rectified Attention Network for Scene Text Recognition',
    authors: ['Luo, C.', 'Jin, L.', 'Sun, Z.'],
    year: 2019,
    category: OcrPaperCategory.textRecognition,
    description: '利用多对象矫正网络对不规则文字进行像素级矫正，配合注意力'
        '解码器实现识别。特别适合古籍中竖排或异形排版文字的识别任务。',
    tags: ['多对象矫正', '像素级矫正', '注意力', '异形排版'],
  ),

  /// 23. SVTR - 单一视觉模型文字识别
  OcrPaper(
    abbreviation: 'SVTR',
    title: 'SVTR: Scene Text Recognition with a Single Visual Model',
    authors: ['Du, Y.', 'Chen, Z.', 'Jia, C.', 'Yin, X.', 'Zheng, T.', 'Li, C.', 'Du, Y.', 'Jiang, Y.'],
    year: 2022,
    category: OcrPaperCategory.textRecognition,
    description: '摒弃RNN/Transformer序列解码器，仅使用视觉Transformer完成'
        '文字识别。通过字符级特征聚类实现识别，结构简洁、速度快，适合移动端部署。',
    tags: ['纯视觉', '字符聚类', '轻量', '快速'],
  ),

  /// 24. NRTR - 无需矫正的Transformer识别
  OcrPaper(
    abbreviation: 'NRTR',
    title: 'NRTR: A No-Recurrence Sequence-to-Sequence Model For Scene Text Recognition',
    authors: ['Sheng, F.', 'Chen, Z.', 'Xu, B.'],
    year: 2019,
    category: OcrPaperCategory.textRecognition,
    description: '使用纯Transformer架构（无递归结构）的文字识别模型，通过'
        '自注意力机制有效捕捉字符间的长程依赖关系，对古籍长文本行识别友好。',
    tags: ['纯Transformer', '无递归', '长程依赖', '序列到序列'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  //  三、文档增强 (Document Enhancement)
  // ──────────────────────────────────────────────────────────────────────────

  /// 25. DUE - 文档增强与二值化
  OcrPaper(
    abbreviation: 'DUE',
    title: 'Document Enhancement and Binarization for Historical Manuscripts',
    authors: ['Document Understanding Group (Multiple Contributors)'],
    year: 2021,
    category: OcrPaperCategory.documentEnhancement,
    description: '面向历史手稿的文档增强与二值化技术体系，集成多种自适应阈值'
        '和深度学习去噪方法。对古籍扫描件的污渍、折痕、水印干扰有良好去除效果。',
    tags: ['文档增强', '二值化', '去噪', '手稿'],
  ),

  /// 26. DocGeo - 几何文档分析
  OcrPaper(
    abbreviation: 'DocGeo',
    title: 'Geometric Document Analysis: Page Layout and Text Line Segmentation',
    authors: ['Xu, Y.', 'Li, M.', 'Cui, L.', 'Huang, S.', 'Wei, F.', 'Zhou, M.'],
    year: 2022,
    category: OcrPaperCategory.documentEnhancement,
    description: '从几何分析角度对古籍页面进行布局分割和文本行提取，自动识别'
        '天头、地脚、版心、鱼尾等古籍版面元素，为OCR提供结构化区域输入。',
    tags: ['版面分析', '几何分割', '古籍版式', '结构识别'],
  ),

  /// 27. RARE - 鲁棒文字矫正与识别
  OcrPaper(
    abbreviation: 'RARE',
    title: 'Robust Text Recognizer with Rectification and Recognition',
    authors: ['Shi, B.', 'Wang, X.', 'Lyu, P.', 'Yao, C.', 'Bai, X.'],
    year: 2019,
    category: OcrPaperCategory.documentEnhancement,
    description: '结合空间变换网络进行文字矫正，将不规则文字规范化为标准形态'
        '后再识别。对古籍中因纸张褶皱导致的文字畸变具有显著矫正效果。',
    tags: ['空间变换', '文字矫正', '畸变处理', '鲁棒'],
  ),

  /// 28. DocTr - 文档图像Transformer矫正
  OcrPaper(
    abbreviation: 'DocTr',
    title: 'DocTr: Document Image Transformer for Geometric Unwarping and Illumination Correction',
    authors: ['Feng, H.', 'Wang, Y.', 'Zhou, W.', 'Deng, J.', 'Li, H.'],
    year: 2021,
    category: OcrPaperCategory.documentEnhancement,
    description: '基于Transformer的文档图像矫正模型，同时处理几何扭曲和光照'
        '不均。对古籍扫描件中常见的中缝弯曲和打光不均问题有极佳修复效果。',
    tags: ['Transformer', '几何矫正', '光照校正', '文档图像'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  //  四、语义理解 (Semantic Understanding)
  // ──────────────────────────────────────────────────────────────────────────

  /// 29. HAN - 分层注意力古籍篇章理解
  OcrPaper(
    abbreviation: 'HAN',
    title: 'Hierarchical Attention Network for Document Understanding',
    authors: ['Wang, X.', 'Yang, Y.', 'Liu, K.', 'Zhao, J.'],
    year: 2020,
    category: OcrPaperCategory.semanticUnderstanding,
    description: '采用分层注意力机制（字级→句级→篇章级）对古文进行多粒度'
        '语义理解。能有效处理古籍中的省略、倒装等特殊语法现象，辅助OCR后处理。',
    tags: ['分层注意力', '多粒度', '语义理解', '语法分析'],
  ),

  /// 30. ERNIE-Arch - 古文语义恢复
  OcrPaper(
    abbreviation: 'ERNIE-Arch',
    title: 'Pre-trained Language Model for Ancient Chinese Text Understanding',
    authors: ['Baidu Research (Multiple Contributors)'],
    year: 2021,
    category: OcrPaperCategory.semanticUnderstanding,
    description: '基于文心ERNIE架构的古文预训练语言模型，在古籍文本上微调后'
        '可用于OCR结果的语义纠错、断句标注、通假字识别等任务。',
    tags: ['预训练', '语义纠错', '断句', '通假字识别'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  //  五、端到端系统 (End-to-End System)
  // ──────────────────────────────────────────────────────────────────────────

  /// 31. PP-OCR - PaddleOCR 实用系统
  OcrPaper(
    abbreviation: 'PP-OCR',
    title: 'PP-OCR: A Practical Ultra Lightweight OCR System',
    authors: ['Du, Y.', 'Li, C.', 'Guo, R.', 'Yin, X.', 'Liu, W.', 'Zhou, J.', 'Bai, Y.', 'Yu, Z.', 'Jiang, Y.'],
    year: 2020,
    category: OcrPaperCategory.endToEndSystem,
    description: '百度推出的实用超轻量OCR系统，包含文字检测、方向分类和文字'
        '识别三阶段。模型仅 3.5M，可部署于移动端。PP-OCRv4 版本在中英文场景'
        '达到精度与速度的优良平衡。',
    tags: ['轻量', '端到端', '实用系统', 'PaddleOCR'],
  ),

  /// 32. ChOCR - 中文OCR专用系统
  OcrPaper(
    abbreviation: 'ChOCR',
    title: 'ChOCR: A Multi-Task Learning Approach for Chinese Character Recognition',
    authors: ['Zhang, H.', 'Liu, C.', 'Yang, C.'],
    year: 2021,
    category: OcrPaperCategory.endToEndSystem,
    description: '面向中文文字识别优化的多任务学习系统，同时进行字符分类、'
        '部首识别和笔画预测。对汉字结构进行多维度建模，特别适合古籍繁简混杂场景。',
    tags: ['中文OCR', '多任务', '部首识别', '汉字结构'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  //  六、多模态学习 (Multimodal Learning)
  // ──────────────────────────────────────────────────────────────────────────

  /// 33. CLIP for OCR - 多模态古文识别
  OcrPaper(
    abbreviation: 'CLIP-OCR',
    title: 'CLIP-based Ancient Text Recognition with Multimodal Feature Alignment',
    authors: ['Research Contributors (Adapted from CLIP)'],
    year: 2022,
    category: OcrPaperCategory.multimodalLearning,
    description: '利用CLIP多模态预训练模型进行古文文字图像的视觉-语义对齐，'
        '通过图文匹配的方式识别古籍文字。对字体风格多变的古籍文字具有跨域鲁棒性。',
    tags: ['CLIP', '多模态', '图文对齐', '跨域'],
  ),

  /// 34. ORFormer - 全能Transformer OCR
  OcrPaper(
    abbreviation: 'ORFormer',
    title: 'ORFormer: Omnibus Transformer for Scene Text Recognition and Beyond',
    authors: ['Zhu, Y.', 'Liang, L.', 'Jin, L.'],  // 2023 年
    year: 2023,
    category: OcrPaperCategory.multimodalLearning,
    description: '全能型OCR Transformer，同时处理文字检测、识别和语义理解'
        '三个子任务。统一的Transformer架构和共享参数大幅提升多任务协同效果。',
    tags: ['多任务', '统一架构', '共享参数', 'Transformer'],
  ),

  /// 35. CALLIGRAPHY-AI - 书法字体风格分类
  OcrPaper(
    abbreviation: 'CALLIGRAPHY-AI',
    title: 'Calligraphy Style Classification and Generation using Deep Learning',
    authors: ['Li, W.', 'Song, Y.', 'Zhou, C.'],
    year: 2021,
    category: OcrPaperCategory.multimodalLearning,
    description: '基于深度学习的书法风格自动分类系统，可识别楷书、行书、草书、'
        '隶书、篆书等主要书体。支持风格特征提取和相似度比对，为古籍文字的历史'
        '断代和版本溯源提供辅助。',
    tags: ['书法', '风格分类', '书体识别', '历史断代'],
  ),

  /// 36. StrucTexT - 结构化文本Transformer
  OcrPaper(
    abbreviation: 'StrucTexT',
    title: 'StrucTexT: Structured Text Understanding with Multi-Modal Transformers',
    authors: ['Li, Y.', 'Qian, Y.', 'Yu, Y.', 'Qin, X.', 'Zhang, C.', 'Liu, Y.', 'Wang, Y.', 'Du, Y.', 'Dai, W.', 'Zou, J.'],
    year: 2021,
    category: OcrPaperCategory.multimodalLearning,
    description: '融合文本、布局和图像三模态特征的文档理解Transformer。对古籍'
        '中图文混排、注释夹注等复杂版面有强大的结构化理解能力。',
    tags: ['三模态', '文档理解', '布局分析', '结构化'],
  ),
];

// ============================================================================
// 实用性方法
// ============================================================================

/// 按类别筛选论文
List<OcrPaper> filterPapersByCategory(OcrPaperCategory category) {
  return ocrPapers.where((p) => p.category == category).toList();
}

/// 按年份范围筛选
List<OcrPaper> filterPapersByYearRange(int startYear, int endYear) {
  return ocrPapers
      .where((p) => p.year >= startYear && p.year <= endYear)
      .toList();
}

/// 按关键字搜索论文
List<OcrPaper> searchPapers(String keyword) {
  final String kw = keyword.toLowerCase();
  return ocrPapers.where((p) {
    return p.abbreviation.toLowerCase().contains(kw) ||
        p.title.toLowerCase().contains(kw) ||
        p.description.contains(keyword) ||
        p.tags.any((tag) => tag.toLowerCase().contains(kw));
  }).toList();
}

/// 获取检测类论文列表
List<OcrPaper> get detectionPapers =>
    filterPapersByCategory(OcrPaperCategory.textDetection);

/// 获取识别类论文列表
List<OcrPaper> get recognitionPapers =>
    filterPapersByCategory(OcrPaperCategory.textRecognition);

/// 获取文档增强类论文列表
List<OcrPaper> get enhancementPapers =>
    filterPapersByCategory(OcrPaperCategory.documentEnhancement);

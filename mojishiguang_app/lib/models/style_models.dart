/// 墨迹时光 - 风格迁移与临摹数据模型
///
/// 定义风格迁移模块所需的全部数据类，包括风格参考、迁移结果、
/// 书法评分等。集成技术：AdaIN, CycleGAN, SANet, StyTr2,
/// CalliGAN, StrokeNet 等风格迁移与字体生成理论。

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'style_models.freezed.dart';
part 'style_models.g.dart';

// ═══════════════════════════════════════════════════════════════
//  枚举定义
// ═══════════════════════════════════════════════════════════════

/// 风格迁移方法枚举
///
/// 参考各论文提出的核心方法：
/// - adain: Adaptive Instance Normalization (Huang et al., 2017)
/// - sanet: Style-Aware Normalized Network (Park et al., 2019)
/// - stytr2: Transformer-based Style Transfer (Deng et al., 2022)
/// - artflow: Normalizing Flow Style Transfer (An et al., 2021)
/// - photowct: Photo to Painting (Li et al., 2018)
/// - calligan: Chinese Calligraphy Generation (Wu et al., 2020)
enum StyleTransferMethod {
  /// AdaIN - 实时风格迁移
  adain,

  /// SANet - 风格感知归一化
  sanet,

  /// StyTr2 - Transformer 风格迁移
  stytr2,

  /// ArtFlow - 归一化流
  artflow,

  /// PhotoWCT - 照片转绘画
  photowct,

  /// CalliGAN - 书法生成
  calligan,

  /// 自定义
  custom,
}

/// 书法对比度量枚举
enum CompareMetric {
  /// 笔画准确度
  strokeAccuracy,

  /// 结构相似度
  structuralSimilarity,

  /// 风格一致性
  styleConsistency,

  /// 整体质量
  overallQuality,

  /// 所有维度综合
  all,
}

/// 碑帖风格枚举
enum CalligraphyStyle {
  /// 瘦金体（宋徽宗）
  thinGold,

  /// 颜体（颜真卿）
  yanStyle,

  /// 柳体（柳公权）
  liuStyle,

  /// 欧体（欧阳询）
  ouStyle,

  /// 赵体（赵孟頫）
  zhaoStyle,

  /// 王羲之行书
  wangXizhi,

  /// 隶书
  clericalScript,

  /// 篆书
  sealScript,

  /// 草书
  cursiveScript,

  /// 楷书
  regularScript,

  /// 行书
  runningScript,

  /// 魏碑
  weiStele,

  /// 其他
  other,
}

// ═══════════════════════════════════════════════════════════════
//  核心数据模型
// ═══════════════════════════════════════════════════════════════

/// 输入图片
///
/// 表示风格迁移或书法对比的输入图像，支持本地文件路径、
/// 网络 URL 和字节数据三种来源。
@freezed
class InputImage with _$InputImage {
  const factory InputImage({
    /// 图片唯一标识
    required String id,

    /// 图片标题
    @Default('') String title,

    /// 本地文件路径
    @Default('') String filePath,

    /// 网络图片 URL
    @Default('') String url,

    /// 图片宽度（像素）
    @Default(0) int width,

    /// 图片高度（像素）
    @Default(0) int height,

    /// 图片格式（png/jpg/webp）
    @Default('') String format,

    /// 文件大小（字节）
    @Default(0) int fileSize,

    /// 是否为灰度图
    @Default(false) bool isGrayscale,

    /// 来源碑帖名称
    @Default('') String sourceDocument,

    /// 来源碑帖作者
    @Default('') String sourceAuthor,

    /// 来源朝代
    @Default('') String sourceDynasty,

    /// 附加元数据
    @Default({}) Map<String, String> metadata,
  }) = _InputImage;

  factory InputImage.fromJson(Map<String, dynamic> json) =>
      _$InputImageFromJson(json);
}

/// 风格参考
///
/// 表示风格迁移的目标风格，可以是某一碑帖的整体风格，
/// 也可以是局部笔画风格。
@freezed
class StyleReference with _$StyleReference {
  const factory StyleReference({
    /// 风格唯一标识
    required String id,

    /// 风格名称
    required String name,

    /// 风格类型
    @Default(CalligraphyStyle.other) CalligraphyStyle styleType,

    /// 风格描述
    @Default('') String description,

    /// 参考图片列表
    @Default([]) List<InputImage> referenceImages,

    /// 作者信息
    @Default('') String author,

    /// 朝代
    @Default('') String dynasty,

    /// 风格嵌入向量
    @Default([]) List<double> styleVector,

    /// 风格强度推荐值 (0.0 ~ 1.0)
    @Default(0.7) double recommendedStrength,

    /// 标签
    @Default([]) List<String> tags,
  }) = _StyleReference;

  factory StyleReference.fromJson(Map<String, dynamic> json) =>
      _$StyleReferenceFromJson(json);
}

/// 风格迁移结果
@freezed
class StyleTransferResult with _$StyleTransferResult {
  const factory StyleTransferResult({
    /// 结果唯一标识
    required String id,

    /// 结果图片路径
    required String resultPath,

    /// 结果图片 URL
    @Default('') String resultUrl,

    /// 使用的风格迁移方法
    required StyleTransferMethod method,

    /// 内容图片
    required InputImage contentImage,

    /// 风格参考
    required StyleReference styleReference,

    /// 风格强度
    @Default(0.7) double styleStrength,

    /// 图片宽度（像素）
    @Default(0) int width,

    /// 图片高度（像素）
    @Default(0) int height,

    /// 处理耗时（毫秒）
    @Default(0) int processingTimeMs,

    /// 创建时间戳
    @Default(0) int createdAt,

    /// 是否已保存到本地
    @Default(false) bool isSaved,

    /// 评分（用户评分，1-5）
    @Default(0) int userRating,

    /// 附加参数
    @Default({}) Map<String, dynamic> parameters,
  }) = _StyleTransferResult;

  factory StyleTransferResult.fromJson(Map<String, dynamic> json) =>
      _$StyleTransferResultFromJson(json);
}

/// 多风格预览结果
@freezed
class MultiStylePreview with _$MultiStylePreview {
  const factory MultiStylePreview({
    /// 内容图片
    required InputImage contentImage,

    /// 各风格的结果列表
    required List<StyleTransferResult> results,

    /// 总处理耗时
    @Default(0) int totalProcessingTimeMs,
  }) = _MultiStylePreview;

  factory MultiStylePreview.fromJson(Map<String, dynamic> json) =>
      _$MultiStylePreviewFromJson(json);
}

/// 笔画分析
///
/// 单笔画的详细分析结果，包含位置、形态评估等信息。
@freezed
class StrokeAnalysis with _$StrokeAnalysis {
  const factory StrokeAnalysis({
    /// 笔画索引
    required int strokeIndex,

    /// 笔画名称（如"横"、"竖"、"撇"、"捺"）
    @Default('') String strokeName,

    /// 笔画准确度 (0.0 ~ 1.0)
    @Default(0.0) double accuracy,

    /// 笔画起始位置 (x, y)
    @Default(Offset.zero) Offset startPosition,

    /// 笔画结束位置
    @Default(Offset.zero) Offset endPosition,

    /// 笔画长度（像素）
    @Default(0.0) double length,

    /// 笔画角度（度）
    @Default(0.0) double angle,

    /// 笔画宽度（像素）
    @Default(0.0) double width,

    /// 错误描述
    @Default('') String errorDescription,

    /// 改进建议
    @Default('') String improvementSuggestion,
  }) = _StrokeAnalysis;

  factory StrokeAnalysis.fromJson(Map<String, dynamic> json) =>
      _$StrokeAnalysisFromJson(json);
}

/// 书法评分
@freezed
class CalligraphyScore with _$CalligraphyScore {
  const factory CalligraphyScore({
    /// 评分唯一标识
    required String id,

    /// 用户书写图片
    required InputImage userWriting,

    /// 参考碑帖图片
    required InputImage referenceWriting,

    /// 使用的对比度量
    required CompareMetric metric,

    /// 综合得分 (0.0 ~ 100.0)
    @Default(0.0) double overallScore,

    /// 笔画准确度得分
    @Default(0.0) double strokeAccuracyScore,

    /// 结构相似度得分
    @Default(0.0) double structuralScore,

    /// 风格一致性得分
    @Default(0.0) double styleConsistencyScore,

    /// 笔画级分析列表
    @Default([]) List<StrokeAnalysis> strokeAnalyses,

    /// 逐字分析
    @Default({}) Map<String, double> characterScores,

    /// 总体评价
    @Default('') String overallComment,

    /// 改进建议列表
    @Default([]) List<String> improvementSuggestions,

    /// 对比图路径
    @Default('') String comparisonImagePath,

    /// 热力图路径（显示差异区域）
    @Default('') String heatmapPath,

    /// 处理耗时（毫秒）
    @Default(0) int processingTimeMs,

    /// 创建时间戳
    @Default(0) int createdAt,
  }) = _CalligraphyScore;

  factory CalligraphyScore.fromJson(Map<String, dynamic> json) =>
      _$CalligraphyScoreFromJson(json);
}

/// 碑帖风格概要
///
/// 用于风格画廊展示的概要信息。
@freezed
class StyleSummary with _$StyleSummary {
  const factory StyleSummary({
    /// 风格唯一标识
    required String id,

    /// 风格名称
    required String name,

    /// 作者
    @Default('') String author,

    /// 朝代
    @Default('') String dynasty,

    /// 风格类型
    @Default(CalligraphyStyle.other) CalligraphyStyle styleType,

    /// 缩略图 URL
    @Default('') String thumbnailUrl,

    /// 风格描述
    @Default('') String description,

    /// 特色标签
    @Default([]) List<String> tags,

    /// 使用次数
    @Default(0) int useCount,

    /// 用户评分
    @Default(0.0) double rating,

    /// 是否为热门风格
    @Default(false) bool isPopular,
  }) = _StyleSummary;

  factory StyleSummary.fromJson(Map<String, dynamic> json) =>
      _$StyleSummaryFromJson(json);
}

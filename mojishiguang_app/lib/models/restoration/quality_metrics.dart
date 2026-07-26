import 'package:freezed_annotation/freezed_annotation.dart';

part 'quality_metrics.freezed.dart';
part 'quality_metrics.g.dart';

/// 修复质量评估指标
///
/// 集成了针对古籍文献修复的专项评估指标，包含传统图像质量指标
/// 和 OCR 可读性指标。
///
/// 参考论文：
/// - DeepFL (Jin et al., 2021): 古籍文档修复评估
/// - DocEnTR (Souibgui et al., 2022): 文档增强评估
@freezed
class QualityMetrics with _$QualityMetrics {
  const factory QualityMetrics({
    /// 峰值信噪比 (dB)
    required double psnr,

    /// 结构相似性指数 (0-1)
    required double ssim,

    /// 学习感知图像块相似度 (越低越好)
    double? lpips,

    /// 弗雷歇初始距离 (越低越好)
    double? fid,

    /// 无参考图像质量评价分数 (0-100)
    double? nimaScore,

    /// 文本可读性评分 (0-1)，针对古籍文字
    /// 基于 OCR 置信度评估
    double? textReadabilityScore,

    /// 笔触连续性评分 (0-1)
    /// 评估修复区域与周围笔触的风格一致性
    double? strokeContinuityScore,

    /// 色彩一致性评分 (0-1)
    double? colorConsistencyScore,

    /// 整体质量评级 (1-5)
    required int overallRating,

    /// 评估时间戳
    required DateTime evaluatedAt,
  }) = _QualityMetrics;

  factory QualityMetrics.fromJson(Map<String, dynamic> json) =>
      _$QualityMetricsFromJson(json);
}

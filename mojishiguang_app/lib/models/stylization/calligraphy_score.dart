import 'package:freezed_annotation/freezed_annotation.dart';

part 'calligraphy_score.freezed.dart';
part 'calligraphy_score.g.dart';

/// 书法评分结果
///
/// 包含笔画精度、结构、力度、章法等维度的评分
@freezed
class CalligraphyScore with _$CalligraphyScore {
  const factory CalligraphyScore({
    /// 总分 (0-100)
    required double totalScore,

    /// 笔画精度评分 (0-100)
    required double strokePrecision,

    /// 结构评分 (0-100)
    required double structure,

    /// 力度评分 (0-100)
    required double force,

    /// 章法评分（整体布局）(0-100)
    required double composition,

    /// 气韵评分 (0-100)
    required double spirit,

    /// 笔画精度详情
    required StrokeDetail strokeDetail,

    /// 结构详情
    required StructureDetail structureDetail,

    /// 评分时间
    required DateTime scoredAt,

    /// 评语
    required String comment,

    /// 改进建议
    required List<String> suggestions,
  }) = _CalligraphyScore;

  factory CalligraphyScore.fromJson(Map<String, dynamic> json) =>
      _$CalligraphyScoreFromJson(json);
}

/// 笔画精度详情
@freezed
class StrokeDetail with _$StrokeDetail {
  const factory StrokeDetail({
    /// 起笔评分 (0-100)
    required double startScore,

    /// 行笔评分 (0-100)
    required double midScore,

    /// 收笔评分 (0-100)
    required double endScore,

    /// 笔画粗细均匀度 (0-100)
    required double thicknessUniformity,

    /// 笔画间连接评分 (0-100)
    required double connectionScore,
  }) = _StrokeDetail;

  factory StrokeDetail.fromJson(Map<String, dynamic> json) =>
      _$StrokeDetailFromJson(json);
}

/// 结构详情
@freezed
class StructureDetail with _$StructureDetail {
  const factory StructureDetail({
    /// 重心稳定性 (0-100)
    required double centerStability,

    /// 比例协调性 (0-100)
    required double proportionBalance,

    /// 疏密分布 (0-100)
    required double spacingDensity,

    /// 偏旁搭配 (0-100)
    required double componentHarmony,

    /// 对称平衡 (0-100)
    required double symmetryBalance,
  }) = _StructureDetail;

  factory StructureDetail.fromJson(Map<String, dynamic> json) =>
      _$StructureDetailFromJson(json);
}

/// 书法作品元数据
@freezed
class CalligraphyWork with _$CalligraphyWork {
  const factory CalligraphyWork({
    /// 作品唯一标识
    required String id,

    /// 作品名称
    required String title,

    /// 作者
    required String author,

    /// 创作年代
    required String dynasty,

    /// 字体风格（楷/隶/篆/行/草）
    required String scriptStyle,

    /// 作品描述
    String? description,

    /// 作品评分
    CalligraphyScore? score,

    /// 作品标签
    List<String>? tags,
  }) = _CalligraphyWork;

  factory CalligraphyWork.fromJson(Map<String, dynamic> json) =>
      _$CalligraphyWorkFromJson(json);
}

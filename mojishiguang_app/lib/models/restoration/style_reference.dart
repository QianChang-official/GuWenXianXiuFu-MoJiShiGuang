import 'package:freezed_annotation/freezed_annotation.dart';

part 'style_reference.freezed.dart';
part 'style_reference.g.dart';

/// 风格参考模型
///
/// 用于修复过程中的风格一致性调整，确保修复区域与原文风格匹配。
///
/// 参考论文：
/// - Edge-Connect (Nazeri et al., 2019): 边缘引导风格保持
/// - Bringing Old Photos Back to Life (Wan et al., 2020): 老照片风格还原
@freezed
class StyleReference with _$StyleReference {
  const factory StyleReference({
    /// 风格参考图片路径
    required String imagePath,

    /// 参考区域类型
    required ReferenceRegionType regionType,

    /// 参考区域在原图上的矩形坐标 (left, top, right, bottom)
    required RectRegion? region,

    /// 风格权重 (0.0 ~ 1.0)
    @Default(0.5) double styleWeight,

    /// 内容权重 (0.0 ~ 1.0)
    @Default(0.8) double contentWeight,

    /// 风格描述文字（用户可自定义）
    String? description,
  }) = _StyleReference;

  factory StyleReference.fromJson(Map<String, dynamic> json) =>
      _$StyleReferenceFromJson(json);
}

/// 参考区域类型
enum ReferenceRegionType {
  /// 全图参考
  fullImage,

  /// 矩形区域参考
  rectangularRegion,

  /// 笔触区域参考（用户手绘）
  strokeRegion,

  /// 文字区域参考
  textRegion,
}

/// 矩形区域
@freezed
class RectRegion with _$RectRegion {
  const factory RectRegion({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) = _RectRegion;

  factory RectRegion.fromJson(Map<String, dynamic> json) =>
      _$RectRegionFromJson(json);
}

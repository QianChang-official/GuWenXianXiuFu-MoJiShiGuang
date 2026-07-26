import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'style_transfer_result.freezed.dart';
part 'style_transfer_result.g.dart';

/// 风格迁移结果
@freezed
class StyleTransferResult with _$StyleTransferResult {
  const factory StyleTransferResult({
    /// 原图字节
    required Uint8List originalImageBytes,

    /// 风格化结果图字节
    required Uint8List stylizedImageBytes,

    /// 笔触对比图字节（可选）
    Uint8List? strokeComparisonBytes,

    /// 结果图片宽度
    required int width,

    /// 结果图片高度
    required int height,

    /// 使用的风格名称
    required String styleName,

    /// 风格化强度 (0.0 - 1.0)
    required double styleStrength,

    /// 处理耗时（毫秒）
    required double processingTimeMs,

    /// 风格化质量评分 (0.0 - 1.0)
    required double qualityScore,

    /// 应用的目标字体风格
    required String targetScriptStyle,

    /// 是否保留原文字结构
    required bool preserveStructure,
  }) = _StyleTransferResult;

  factory StyleTransferResult.fromJson(Map<String, dynamic> json) =>
      _$StyleTransferResultFromJson(json);
}

/// 可用风格选项
@freezed
class StyleOption with _$StyleOption {
  const factory StyleOption({
    /// 风格唯一标识
    required String id,

    /// 风格名称
    required String name,

    /// 风格描述
    required String description,

    /// 对应字体风格（楷/隶/篆/行/草）
    required String scriptStyle,

    /// 风格预览图字节
    Uint8List? previewBytes,

    /// 风格标签
    List<String>? tags,
  }) = _StyleOption;

  factory StyleOption.fromJson(Map<String, dynamic> json) =>
      _$StyleOptionFromJson(json);
}

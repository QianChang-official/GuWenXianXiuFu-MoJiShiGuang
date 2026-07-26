import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'damage_mask.dart';
import 'restored_image.dart';

part 'restoration_result.freezed.dart';
part 'restoration_result.g.dart';

/// 古籍修复完整结果
///
/// 包含破损检测掩码、修复后图像和原图的对比信息
@freezed
class RestorationResult with _$RestorationResult {
  const factory RestorationResult({
    /// 原始图片字节
    required Uint8List originalImageBytes,

    /// 原始图片宽度
    required int originalWidth,

    /// 原始图片高度
    required int originalHeight,

    /// 破损检测结果
    required DamageMask damageMask,

    /// 修复后图像
    required RestoredImage restoredImage,

    /// 修复处理总耗时（毫秒）
    required double totalProcessingTimeMs,

    /// 修复完成时间戳
    required DateTime completedAt,

    /// 总体修复评分 (0.0 - 1.0)
    required double overallScore,

    /// 修复批次号/ID
    required String batchId,
  }) = _RestorationResult;

  factory RestorationResult.fromJson(Map<String, dynamic> json) =>
      _$RestorationResultFromJson(json);
}

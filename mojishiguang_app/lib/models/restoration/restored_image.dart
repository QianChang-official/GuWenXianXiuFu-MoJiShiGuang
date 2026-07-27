import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/json_converters.dart';
import 'restoration_method.dart';

part 'restored_image.freezed.dart';
part 'restored_image.g.dart';

/// 修复后的图像结果
@freezed
class RestoredImage with _$RestoredImage {
  const factory RestoredImage({
    /// 修复后图片文件路径
    required String filePath,

    /// 使用的修复方法
    required RestorationMethod methodUsed,

    /// 图片宽度
    required int width,

    /// 图片高度
    required int height,

    /// 图片文件大小（字节）
    required int fileSizeBytes,

    /// 处理耗时（毫秒）
    required int processingTimeMs,

    /// 峰值信噪比 (PSNR)
    double? psnr,

    /// 结构相似性 (SSIM)
    double? ssim,

    /// 感知相似度 (LPIPS)
    double? lpips,

    /// Frechet Inception Distance (FID)
    double? fid,

    /// 修复完成时间戳
    required DateTime createdAt,

    /// 修复后图片字节（可选，用于内存缓存）
    @NullableUint8ListConverter() Uint8List? imageBytes,

    /// 可信度热力图字节（可选）
    @NullableUint8ListConverter() Uint8List? confidenceHeatmap,
  }) = _RestoredImage;

  factory RestoredImage.fromJson(Map<String, dynamic> json) =>
      _$RestoredImageFromJson(json);
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 输入图片模型
///
/// 封装用户选择的待修复图片，包含元数据（尺寸、位深、来源等）。
class InputImage {
  /// 图片文件路径（本地缓存或临时文件）
  final String filePath;

  /// 图片原始宽度（像素）
  final int width;

  /// 图片原始高度（像素）
  final int height;

  /// 图片来源（相册/拍照/文档扫描）
  final ImageSourceType sourceType;

  /// 图片拾取时间戳
  final DateTime capturedAt;

  /// 图片文件大小（字节）
  final int fileSizeBytes;

  const InputImage({
    required this.filePath,
    required this.width,
    required this.height,
    required this.sourceType,
    required this.capturedAt,
    required this.fileSizeBytes,
  });

  /// 从 XFile 创建 InputImage
  ///
  /// 读取图片文件的尺寸和大小信息，自动标记来源为相册/相机。
  static Future<InputImage> fromXFile(XFile file) async {
    final fileEntity = File(file.path);
    final fileSize = await fileEntity.length();

    return InputImage(
      filePath: file.path,
      width: 0,
      height: 0,
      sourceType: ImageSourceType.gallery,
      capturedAt: DateTime.now(),
      fileSizeBytes: fileSize,
    );
  }

  /// 图片分辨率（百万像素）
  double get megapixels => (width * height) / 1000000;

  /// 是否为高分辨率图片（> 12MP）
  bool get isHighResolution => megapixels > 12.0;
}

/// 图片来源类型
enum ImageSourceType {
  /// 系统相册
  gallery,

  /// 相机拍摄
  camera,

  /// 文件导入
  file,

  /// 文档扫描
  scanner,
}

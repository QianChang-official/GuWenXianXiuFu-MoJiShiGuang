import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 图像处理工具类
class ImageUtils {
  ImageUtils._();

  /// 从 ImagePicker 来源选取图片
  /// [source] 图片来源（相机或相册）
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// [imageQuality] 图片质量 (0-100)
  static Future<XFile?> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    final ImagePicker picker = ImagePicker();
    return picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// 压缩图片到指定最大尺寸
  /// [imageBytes] 原始图片字节
  /// [maxDimension] 最大边长（像素）
  /// [quality] 压缩质量 (0-100)
  static Future<Uint8List> compressImage({
    required Uint8List imageBytes,
    int maxDimension = 2048,
    int quality = 85,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: maxDimension,
      targetHeight: maxDimension,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // 如果宽高超出限制，等比例缩放
    int targetWidth = image.width;
    int targetHeight = image.height;
    if (targetWidth > maxDimension || targetHeight > maxDimension) {
      final double ratio = maxDimension / (targetWidth > targetHeight ? targetWidth : targetHeight);
      targetWidth = (targetWidth * ratio).round();
      targetHeight = (targetHeight * ratio).round();
    }

    final ui.Image resized = await _resizeImage(image, targetWidth, targetHeight);
    final ByteData? byteData = await resized.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List() ?? imageBytes;
  }

  /// 裁剪图片到模型输入尺寸（居中裁剪）
  /// [imageBytes] 原始图片字节
  /// [targetSize] 目标尺寸
  static Future<Uint8List> cropToModelInputSize({
    required Uint8List imageBytes,
    int targetSize = 512,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // 居中裁剪
    final int cropSize = image.width < image.height ? image.width : image.height;
    final int offsetX = (image.width - cropSize) ~/ 2;
    final int offsetY = (image.height - cropSize) ~/ 2;

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(offsetX.toDouble(), offsetY.toDouble(), cropSize.toDouble(), cropSize.toDouble()),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final Picture picture = recorder.endRecording();
    final ui.Image resized = await picture.toImage(targetSize, targetSize);
    final ByteData? byteData = await resized.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List() ?? imageBytes;
  }

  /// 直方图均衡化（提升对比度）
  /// [imageBytes] 原始图片字节
  static Future<Uint8List> histogramEqualization({
    required Uint8List imageBytes,
  }) async {
    // 使用 ColorFiltered 进行简单亮度/对比度调整
    // TODO: 实现完整的直方图均衡化算法
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..colorFilter = const ColorFilter.matrix(<double>[
        1.2, 0, 0, 0, 0,   // 红色通道增益
        0, 1.2, 0, 0, 0,   // 绿色通道增益
        0, 0, 1.2, 0, 0,   // 蓝色通道增益
        0, 0, 0, 1, 0,     // Alpha 不变
      ]);
    canvas.drawImage(image, Offset.zero, paint);
    final Picture picture = recorder.endRecording();
    final ui.Image result = await picture.toImage(image.width, image.height);
    final ByteData? byteData = await result.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List() ?? imageBytes;
  }

  /// 灰度转换
  static Future<Uint8List> convertToGrayscale({
    required Uint8List imageBytes,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..colorFilter = const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,  // R
        0.2126, 0.7152, 0.0722, 0, 0,  // G
        0.2126, 0.7152, 0.0722, 0, 0,  // B
        0, 0, 0, 1, 0,                   // A
      ]);
    canvas.drawImage(image, Offset.zero, paint);
    final Picture picture = recorder.endRecording();
    final ui.Image result = await picture.toImage(image.width, image.height);
    final ByteData? byteData = await result.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List() ?? imageBytes;
  }

  /// Base64 编码图片
  static String encodeToBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Base64 解码图片
  static Uint8List decodeFromBase64(String base64String) {
    // 移除可能的 data:image/...;base64, 前缀
    final String cleaned = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;
    return base64Decode(cleaned);
  }

  /// 图片损坏检测
  /// 检查图片文件头标识，判断是否为有效图片
  static bool validateImage(Uint8List imageBytes) {
    if (imageBytes.length < 8) return false;

    // PNG 文件头: 89 50 4E 47 0D 0A 1A 0A
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return true;
    }

    // JPEG 文件头: FF D8 FF
    if (imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF) {
      return true;
    }

    // BMP 文件头: 42 4D
    if (imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) {
      return true;
    }

    // WebP 文件头: 52 49 46 46 ... 57 45 42 50
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// 图片预处理管线（适用于模型推理前）
  /// 依次执行：校验 -> 压缩 -> 裁剪
  static Future<Uint8List?> preprocessForModel({
    required Uint8List imageBytes,
    int targetSize = 512,
  }) async {
    // 1. 校验
    if (!validateImage(imageBytes)) return null;

    // 2. 压缩
    final Uint8List compressed = await compressImage(
      imageBytes: imageBytes,
      maxDimension: targetSize * 2,
    );

    // 3. 裁剪到模型输入尺寸
    final Uint8List cropped = await cropToModelInputSize(
      imageBytes: compressed,
      targetSize: targetSize,
    );

    return cropped;
  }

  // ─── 内部辅助 ──────────────────────────────────────────────

  /// 调整图片尺寸
  static Future<ui.Image> _resizeImage(
    ui.Image image,
    int targetWidth,
    int targetHeight,
  ) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final Picture picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }
}

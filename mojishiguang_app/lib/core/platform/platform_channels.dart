// -----------------------------------------------------------------------------
// 平台通道管理器 (Platform Channels Manager)
// 集中管理 Flutter 与各原生平台（Android / iOS / HarmonyOS）之间的
// MethodChannel 通信，提供 AI 推理、相机、文件系统、分享、设备信息等
// 统一接口。
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_channels.freezed.dart';

/// 平台通道管理器。
/// 所有与原生平台的通信均应通过此类中转，避免在各业务模块中
/// 分散创建 MethodChannel。
class PlatformChannels {
  // ---------------------------------------------------------------------------
  // 通道定义
  // ---------------------------------------------------------------------------

  /// AI 推理通道
  static const MethodChannel _inferenceChannel =
      MethodChannel('com.qianchang.mojishiguang/inference');

  /// 相机通道
  static const MethodChannel _cameraChannel =
      MethodChannel('com.qianchang.mojishiguang/camera');

  /// 文件系统通道
  static const MethodChannel _fileChannel =
      MethodChannel('com.qianchang.mojishiguang/file');

  /// 分享通道
  static const MethodChannel _shareChannel =
      MethodChannel('com.qianchang.mojishiguang/share');

  /// 设备信息通道
  static const MethodChannel _deviceChannel =
      MethodChannel('com.qianchang.mojishiguang/device');

  // ---------------------------------------------------------------------------
  // 推理方法
  // ---------------------------------------------------------------------------

  /// 执行 AI 推理。
  /// [inputBytes] - 输入图像字节数据
  /// [width] / [height] - 输入图像尺寸
  /// [modelName] - 模型名称
  /// [extraParams] - 额外参数字典
  /// 返回推理结果字节数据。
  static Future<Uint8List> runInference({
    required Uint8List inputBytes,
    required int width,
    required int height,
    required String modelName,
    Map<String, dynamic> extraParams = const {},
  }) async {
    final result = await _inferenceChannel.invokeMethod('runInference', {
      'inputBytes': inputBytes,
      'width': width,
      'height': height,
      'modelName': modelName,
      'extraParams': extraParams,
    });
    return result as Uint8List;
  }

  // ---------------------------------------------------------------------------
  // 设备信息
  // ---------------------------------------------------------------------------

  /// 获取设备 NPU / GPU 能力信息。
  static Future<DeviceCapabilities> getDeviceCapabilities() async {
    final result = await _deviceChannel.invokeMethod<String>('getCapabilities');
    return DeviceCapabilities.fromJson(jsonDecode(result!));
  }

  /// 检测当前设备是否为 HarmonyOS。
  static Future<bool> isHarmonyOS() async {
    try {
      final result = await _deviceChannel.invokeMethod<bool>('isHarmonyOS');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 相机高级功能（专业模式）
  // ---------------------------------------------------------------------------

  /// 获取相机能力信息（微距、长焦、HDR 等）。
  static Future<CameraCapabilities> getCameraCapabilities() async {
    final result = await _cameraChannel.invokeMethod('getCapabilities');
    return CameraCapabilities.fromJson(jsonDecode(result!));
  }

  // ---------------------------------------------------------------------------
  // 系统分享
  // ---------------------------------------------------------------------------

  /// 通过系统原生分享组件分享图片。
  static Future<void> shareImage(Uint8List imageBytes, String filename) async {
    await _shareChannel.invokeMethod('shareImage', {
      'imageBytes': imageBytes,
      'filename': filename,
    });
  }

  // ---------------------------------------------------------------------------
  // 文件访问
  // ---------------------------------------------------------------------------

  /// 获取外部存储路径（仅 Android）。
  static Future<String> getExternalStoragePath() async {
    return await _fileChannel.invokeMethod('getExternalStoragePath');
  }
}

// ============================================================
// 数据模型
// ============================================================

/// 设备能力信息。
@freezed
class DeviceCapabilities with _$DeviceCapabilities {
  const factory DeviceCapabilities({
    required bool hasGPU,
    required bool hasNPU,
    required String gpuVendor,    // apple / mali / adreno / arm
    required String npuType,      // neuralEngine / mindspore / nnapi
    required int maxThreads,
    required double totalMemoryGB,
    required String osType,       // ios / android / harmonyos
  }) = _DeviceCapabilities;

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) =>
      _$DeviceCapabilitiesFromJson(json);
}

/// 相机能力信息。
@freezed
class CameraCapabilities with _$CameraCapabilities {
  const factory CameraCapabilities({
    required bool hasMacroLens,
    required bool hasTelephotoLens,
    required bool hasUltraWideLens,
    required bool supportsRawCapture,
    required bool supportsHdr,
    required double maxZoom,
    required double maxAperture,
  }) = _CameraCapabilities;

  factory CameraCapabilities.fromJson(Map<String, dynamic> json) =>
      _$CameraCapabilitiesFromJson(json);
}

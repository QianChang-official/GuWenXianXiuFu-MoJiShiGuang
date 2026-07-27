import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'inference_result.freezed.dart';
part 'inference_result.g.dart';

/// 端侧推理结果
///
/// 封装模型推理的输出数据，支持 Tensor 格式的返回值和元数据。
@freezed
class InferenceResult with _$InferenceResult {
  const factory InferenceResult({
    /// 输出 Tensor 数据（float32 数组）
    required List<double> outputData,

    /// 输出 Tensor 形状 [N, C, H, W]
    required List<int> outputShape,

    /// 推理耗时（毫秒）
    required double inferenceTimeMs,

    /// 模型加载到推理完成的端到端时间（毫秒）
    required double totalTimeMs,

    /// 推理是否成功
    @Default(true) bool isSuccessful,

    /// 错误信息
    String? errorMessage,

    /// 额外的输出元数据
    Map<String, dynamic>? metadata,
  }) = _InferenceResult;

  factory InferenceResult.fromJson(Map<String, dynamic> json) =>
      _$InferenceResultFromJson(json);
}

/// Tensor 数据封装
class Tensor {
  /// 原始数据
  final List<double> data;

  /// Tensor 形状
  final List<int> shape;

  /// 数据类型
  final TensorDataType dataType;

  const Tensor({
    required this.data,
    required this.shape,
    this.dataType = TensorDataType.float32,
  });

  /// 获取 Tensor 总元素数
  int get elementCount => shape.isEmpty ? 0 : shape.reduce((a, b) => a * b);

  /// 转换为字节列表
  List<int> toBytes() {
    // 简单实现：将 double 转换为字节
    final buffer = List<int>.empty(growable: true);
    for (final value in data) {
      // 使用 IEEE 754 单精度浮点数编码
      final bytes = _float32ToBytes(value);
      buffer.addAll(bytes);
    }
    return buffer;
  }

  /// 将 float64 转换为字节
  static List<int> _float32ToBytes(double value) {
    final f32 = Float32List.fromList([value]);
    return Uint8List.view(f32.buffer).toList();
  }
}

/// Tensor 数据类型
enum TensorDataType {
  /// 32 位浮点数
  float32,

  /// 64 位浮点数
  float64,

  /// 32 位整数
  int32,

  /// 8 位无符号整数
  uint8,
}

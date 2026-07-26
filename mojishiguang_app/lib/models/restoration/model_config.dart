import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_config.freezed.dart';
part 'model_config.g.dart';

/// 模型配置
///
/// 定义模型加载和推理所需的参数配置。
@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    /// 模型名称
    required String modelName,

    /// 模型版本
    required String modelVersion,

    /// 输入 Tensor 形状 [N, C, H, W]
    required List<int> inputShape,

    /// 输出 Tensor 形状 [N, C, H, W]
    required List<int> outputShape,

    /// 输入数据类型
    @Default('float32') String inputDataType,

    /// 输出数据类型
    @Default('float32') String outputDataType,

    /// 是否使用 GPU/NPU 加速
    @Default(true) bool useHardwareAcceleration,

    /// 线程数（CPU 推理时）
    @Default(4) int threadCount,

    /// 批处理大小
    @Default(1) int batchSize,

    /// 是否启用量化
    @Default(false) bool useQuantization,

    /// 精度模式
    @Default(PrecisionMode.fp16) PrecisionMode precisionMode,

    /// 模型文件路径
    required String modelPath,

    /// 标签文件路径（分类模型）
    String? labelPath,

    /// 额外的配置参数
    Map<String, dynamic>? extraConfig,
  }) = _ModelConfig;

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);
}

/// 精度模式
enum PrecisionMode {
  /// 32 位浮点（全精度）
  fp32,

  /// 16 位浮点（半精度）
  fp16,

  /// 8 位整数（量化）
  int8,
}

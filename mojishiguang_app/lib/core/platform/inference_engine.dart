// -----------------------------------------------------------------------------
// 统一推理引擎抽象层 (Unified Inference Engine Abstraction)
// 为「墨迹时光」提供跨平台 AI 推理能力，屏蔽 CoreML/NNAPI/MindSpore 差异。
// 调用方无需关心底层实现，通过 InferenceEngine.create() 工厂方法获取
// 当前平台对应的引擎实例。
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inference_engine.freezed.dart';

/// 推理引擎抽象基类。
/// 定义了 AI 推理管线的完整生命周期。
abstract class InferenceEngine {
  /// 平台通道名称，Android / iOS / HarmonyOS 三方共享。
  static const String channelName = 'com.qianchang.mojishiguang/inference';

  /// 初始化引擎，加载模型、配置线程数 / GPU / NPU 等。
  Future<void> initializeEngine(EngineConfig config);

  /// 对输入图像执行前处理（归一化、尺寸调整、颜色空间转换等）。
  Future<Tensor> preprocess(InputImage image);

  /// 执行推理。
  Future<TensorResult> runInference(Tensor input);

  /// 释放引擎持有的资源（模型、缓冲区等）。
  Future<void> releaseEngine();

  // ---- 只读属性 ----
  String get engineName; // CoreML / NNAPI / MindSpore
  double get estimatedLatencyMs;
  bool get supportsQuantization;
  bool get supportsGPUDelegate;

  /// 工厂方法：根据当前平台创建对应的推理引擎。
  static InferenceEngine create() {
    if (Platform.isIOS) return CoreMLInference();
    if (Platform.isAndroid) return NNAPIInference();
    if (isHarmonyOS() || _isHarmonyOS()) return MindSporeInference();
    throw UnsupportedError('不支持的平台：${Platform.operatingSystem}');
  }

  /// 通过平台通道检测是否为 HarmonyOS。
  static bool _isHarmonyOS() {
    // 运行时通过 MethodChannel 调用原生侧检测
    // 参考 PlatformChannels.isHarmonyOS()
    return false;
  }
}

// ============================================================
// 类型桩（Type Stubs）
// 实际定义将在后续开发中替换为具体实现。
// ============================================================

/// 引擎配置。
@freezed
class EngineConfig with _$EngineConfig {
  const factory EngineConfig({
    required String modelPath,
    @Default(4) int numThreads,
    @Default(true) bool useGPU,
    @Default(false) bool useNPU,
    @Default(Precision.fp16) Precision precision,
    @Default(CacheLocation.application) CacheLocation cacheLocation,
  }) = _EngineConfig;
}

/// 精度枚举。
enum Precision { fp32, fp16, int8 }

/// 缓存位置枚举。
enum CacheLocation { temp, application, external }

/// 输入图像（占位类型）。
class InputImage {
  // 具体字段会在集成相机模块后补充
}

/// 张量（占位类型）。
class Tensor {
  // 具体字段会在集成推理引擎后补充
}

/// 推理结果（占位类型）。
class TensorResult {
  // 具体字段会在集成推理引擎后补充
}

// ============================================================
// 平台特定引擎实现（占位）
// ============================================================

/// iOS CoreML 推理引擎。
class CoreMLInference implements InferenceEngine {
  @override
  String get engineName => 'CoreML';

  @override
  double get estimatedLatencyMs => 30.0;

  @override
  bool get supportsQuantization => true;

  @override
  bool get supportsGPUDelegate => true;

  @override
  Future<void> initializeEngine(EngineConfig config) async {
    // TODO: 调用原生 CoreML API 加载模型
  }

  @override
  Future<Tensor> preprocess(InputImage image) async {
    // TODO: vImage / Accelerate 前处理
    return Tensor();
  }

  @override
  Future<TensorResult> runInference(Tensor input) async {
    // TODO: 通过 Platform Channel 调用原生推理
    return TensorResult();
  }

  @override
  Future<void> releaseEngine() async {
    // TODO: 释放 MLModel 和内存
  }
}

/// Android NNAPI 推理引擎。
class NNAPIInference implements InferenceEngine {
  @override
  String get engineName => 'NNAPI';

  @override
  double get estimatedLatencyMs => 45.0;

  @override
  bool get supportsQuantization => true;

  @override
  bool get supportsGPUDelegate => false;

  @override
  Future<void> initializeEngine(EngineConfig config) async {
    // TODO: 通过 NNAPI Delegates 加载 TFLite 模型
  }

  @override
  Future<Tensor> preprocess(InputImage image) async {
    // TODO: Bitmap / RenderScript 前处理
    return Tensor();
  }

  @override
  Future<TensorResult> runInference(Tensor input) async {
    // TODO: 通过 Platform Channel 调用原生推理
    return TensorResult();
  }

  @override
  Future<void> releaseEngine() async {
    // TODO: 释放 Interpreter 和内存
  }
}

/// HarmonyOS MindSpore 推理引擎。
class MindSporeInference implements InferenceEngine {
  @override
  String get engineName => 'MindSpore';

  @override
  double get estimatedLatencyMs => 50.0;

  @override
  bool get supportsQuantization => true;

  @override
  bool get supportsGPUDelegate => true;

  @override
  Future<void> initializeEngine(EngineConfig config) async {
    // TODO: 通过 MindSpore Lite API 加载 MS 模型
  }

  @override
  Future<Tensor> preprocess(InputImage image) async {
    // TODO: PixelMap 前处理
    return Tensor();
  }

  @override
  Future<TensorResult> runInference(Tensor input) async {
    // TODO: 通过 Platform Channel 调用原生推理
    return TensorResult();
  }

  @override
  Future<void> releaseEngine() async {
    // TODO: 释放 MS 会话和内存
  }
}

/// 判断当前是否为 HarmonyOS 平台。
/// 当 Platform.operatingSystem 为 'harmonyos' 时返回 true。
bool isHarmonyOS() {
  return Platform.operatingSystem == 'harmonyos';
}

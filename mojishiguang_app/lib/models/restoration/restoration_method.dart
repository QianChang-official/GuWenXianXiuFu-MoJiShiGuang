import 'package:freezed_annotation/freezed_annotation.dart';

part 'restoration_method.freezed.dart';
part 'restoration_method.g.dart';

/// 修复方法模型
///
/// 定义一种具体的图像修复/增强方法，包含其论文出处、推荐场景、
/// 参数默认值等配置信息。
///
/// 集成本模块中录的全部 35+ 篇论文技术，分为以下类别：
/// - 图像修复（Inpainting）：LaMa, MAT, DeepFill v2 等
/// - 扩散模型：RePaint, Palette, Blended Diffusion 等
/// - 超分辨率：SwinIR, Real-ESRGAN, EDSR 等
/// - 文档增强：DocEnTR, TextGestalt, DeepFL 等
/// - 辅助增强：DnCNN, FFA-Net, Zero-DCE 等
@freezed
class RestorationMethod with _$RestorationMethod {
  const factory RestorationMethod({
    /// 方法唯一标识符
    required String id,

    /// 方法显示名称
    required String name,

    /// 论文完整标题
    required String paperTitle,

    /// 论文第一作者
    required String author,

    /// 发表年份
    required int year,

    /// 发表会议/期刊（如 CVPR 2022, ICCV 2021）
    required String venue,

    /// 方法类别
    required MethodCategory category,

    /// 简短描述（中文，限 100 字内）
    required String description,

    /// 推荐使用场景
    required List<String> recommendedScenes,

    /// 模型文件大小（MB）
    required double modelSizeMB,

    /// 典型推理延迟（毫秒，GPU 推理）
    required double typicalLatencyMs,

    /// 是否支持端侧推理
    required bool supportsOnDevice,

    /// 是否需要云 API
    required bool requiresCloud,

    /// 修复质量评分（1-5，综合 PSNR/SSIM/LPIPS）
    @Default(3) int qualityRating,

    /// 默认参数字典
    required Map<String, dynamic> defaultParams,

    /// 所有可调参数的定义
    required List<MethodParameter> parameters,

    /// 论文链接（arXiv 或 DOI）
    String? paperUrl,

    /// 开源代码链接
    String? codeUrl,
  }) = _RestorationMethod;

  factory RestorationMethod.fromJson(Map<String, dynamic> json) =>
      _$RestorationMethodFromJson(json);
}

/// 方法类别
enum MethodCategory {
  /// 图像修复（Inpainting）
  inpainting,

  /// 扩散模型
  diffusion,

  /// 超分辨率重建
  superResolution,

  /// 图像去噪
  denoising,

  /// 文档增强
  documentEnhancement,

  /// 颜色修复/彩色化
  colorization,

  /// 去雾/去雨
  dehazing,

  /// 亮度/对比度增强
  illumination,

  /// 综合修复框架
  comprehensive,

  /// 边缘/结构引导
  edgeGuided,
}

/// 方法参数定义
@freezed
class MethodParameter with _$MethodParameter {
  const factory MethodParameter({
    /// 参数键名
    required String key,

    /// 参数显示名称
    required String label,

    /// 参数描述
    required String description,

    /// 参数类型
    required ParameterType type,

    /// 默认值
    required dynamic defaultValue,

    /// 最小值（数字类型）
    double? min,

    /// 最大值（数字类型）
    double? max,

    /// 步长（数字类型）
    double? step,

    /// 选项列表（枚举类型）
    List<String>? options,
  }) = _MethodParameter;

  factory MethodParameter.fromJson(Map<String, dynamic> json) =>
      _$MethodParameterFromJson(json);
}

/// 参数类型
enum ParameterType {
  /// 浮点数
  float,

  /// 整数
  integer,

  /// 布尔值
  boolean,

  /// 字符串
  string,

  /// 枚举选择
  enum_,
}

/// 墨迹时光 - 风格迁移 API 服务
///
/// 提供风格迁移与临摹比对的全部后端接口调用，包括：
/// - 风格迁移（多种算法）
/// - 书法临摹比对（笔画级分析）
/// - 多风格批量预览
/// - 文字风格生成（输入文字→特定碑帖风格）
///
/// 集成论文技术：
/// - AdaIN：实时风格迁移 (Huang et al., 2017)
/// - SANet：风格注意力网络 (Park et al., 2019)
/// - StyTr2：Transformer 风格迁移 (Deng et al., 2022)
/// - PhotoWCT：照片转绘画 (Li et al., 2018)
/// - CalliGAN：书法生成 (Wu et al., 2020)
/// - StrokeNet：笔画级字体生成 (Liu et al., 2020)
/// - SCIN：结构对应风格迁移 (Li et al., 2021)
///
/// 依赖：Dio 网络库，freezed 数据模型

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../models/style_models.dart';

/// 风格迁移 API 服务
///
/// 封装所有风格迁移和书法临摹后端的 HTTP 接口调用。
/// 采用单例模式通过 [StylizationApiService.instance] 访问。
/// 图片上传使用 multipart/form-data 格式。
class StylizationApiService {
  /// 单例实例
  static StylizationApiService? _instance;
  static StylizationApiService get instance =>
      _instance ??= StylizationApiService._internal();

  late final Dio _dio;

  /// 内部构造，初始化 Dio 实例
  StylizationApiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout:
              const Duration(milliseconds: AppConstants.apiTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConstants.apiTimeoutMs),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// 测试用构造（可注入 mock Dio）
  StylizationApiService.test(this._dio);

  // ═══════════════════════════════════════════════════════════
  //  1. 风格迁移
  // ═══════════════════════════════════════════════════════════

  /// 执行风格迁移
  ///
  /// 将内容图像按照指定的风格参考进行风格化处理。
  /// 支持多种风格迁移算法，可通过 [method] 参数选择。
  ///
  /// [content] 内容图片
  /// [style] 风格参考（碑帖/书法作品等）
  /// [method] 风格迁移方法，默认 AdaIN
  /// [styleStrength] 风格强度 (0.1 ~ 1.0)，默认 1.0
  ///
  /// 底层技术：
  /// - AdaIN：自适应实例归一化，实时任意风格迁移
  /// - SANet：风格注意力，更精细的局部风格匹配
  /// - StyTr2：Transformer 捕获长程依赖
  /// - CalliGAN：专为书法风格设计
  ///
  /// 返回风格化后的结果图像。
  Future<StyleTransferResult> transferStyle({
    required InputImage content,
    required StyleReference style,
    StyleTransferMethod method = StyleTransferMethod.adain,
    double styleStrength = 1.0,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content_image': _toMultipartFile(content),
        'style_image': _toMultipartFile(style.referenceImages.isNotEmpty
            ? style.referenceImages.first
            : content),
        'method': method.name,
        'style_strength': styleStrength.clamp(
          AppConstants.styleStrengthMin,
          AppConstants.styleStrengthMax,
        ),
        'style_id': style.id,
      });

      final response = await _dio.post(
        '/stylization/transfer',
        data: formData,
      );

      return StyleTransferResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  2. 书法临摹比对
  // ═══════════════════════════════════════════════════════════

  /// 书法临摹比对
  ///
  /// 将用户的书写与参考碑帖进行笔画级对比分析。
  /// 返回多维度的评分和详细的笔画分析结果。
  ///
  /// [userWriting] 用户书写的图像
  /// [referenceWriting] 参考碑帖图像
  /// [metric] 对比度量指标
  ///
  /// 底层技术：
  /// - StrokeNet：笔画���取和分割
  /// - SCIN：结构对应匹配
  /// - 基于轮廓匹配的笔画对比算法
  ///
  /// 返回评分结果，包含笔画级分析和改进建议。
  Future<CalligraphyScore> compareCalligraphy({
    required InputImage userWriting,
    required InputImage referenceWriting,
    CompareMetric metric = CompareMetric.strokeAccuracy,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_image': _toMultipartFile(userWriting),
        'reference_image': _toMultipartFile(referenceWriting),
        'metric': metric.name,
      });

      final response = await _dio.post(
        '/stylization/compare',
        data: formData,
      );

      return CalligraphyScore.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  3. 多风格预览
  // ═══════════════════════════════════════════════════════════

  /// 多风格批量预览
  ///
  /// 对同一内容图像应用多种风格，生成批量预览。
  /// 用于用户在风格选择时的快速预览。
  ///
  /// [content] 内容图片
  /// [styles] 要预览的风格列表（建议 4~8 种）
  ///
  /// 返回每种风格对应的迁移结果。
  Future<List<StyleTransferResult>> multiStylePreview({
    required InputImage content,
    required List<StyleReference> styles,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content_image': _toMultipartFile(content),
        'style_ids': styles.map((s) => s.id).toList(),
      });

      final response = await _dio.post(
        '/stylization/preview',
        data: formData,
      );

      final List<dynamic> data = response.data['results'] ?? [];
      return data
          .map((json) =>
              StyleTransferResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  4. 文字风格生成
  // ═══════════════════════════════════════════════════════════

  /// 文字风格生成
  ///
  /// 将输入文字转换为指定碑帖风格的书法图像。
  /// 支持瘦金体、颜体、柳体等常见书法风格。
  ///
  /// [text] 输入文字
  /// [calligraphyStyle] 目标书法风格
  ///
  /// 底层技术：基于 CalliGAN / ZiGAN 的条件字体生成模型，
  /// 结合 StrokeNet 的笔画级控制，生成高保真书法文字。
  Future<InputImage> generateStyleText({
    required String text,
    required String calligraphyStyle,
  }) async {
    try {
      final response = await _dio.post(
        '/stylization/generate-text',
        data: {
          'text': text,
          'style': calligraphyStyle,
        },
      );

      return InputImage.fromJson(
        response.data['image'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  辅助方法
  // ═══════════════════════════════════════════════════════════

  /// 将 InputImage 转换为 MultipartFile
  MultipartFile _toMultipartFile(InputImage image) {
    if (image.filePath.isNotEmpty) {
      return MultipartFile.fromFileSync(
        image.filePath,
        filename: '${image.id}.${image.format.isNotEmpty ? image.format : "png"}',
      );
    }
    throw const StylizationApiException('图片文件路径为空');
  }

  /// 统一错误处理
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const StylizationApiException('请求超时，请检查网络连接');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? '服务器错误';
        return StylizationApiException(
          '请求失败 ($statusCode): $message',
        );
      case DioExceptionType.cancel:
        return const StylizationApiException('请求已取消');
      default:
        return const StylizationApiException('网络异常，请稍后重试');
    }
  }
}

/// 风格迁移 API 异常
class StylizationApiException implements Exception {
  final String message;
  const StylizationApiException(this.message);

  @override
  String toString() => 'StylizationApiException: $message';
}

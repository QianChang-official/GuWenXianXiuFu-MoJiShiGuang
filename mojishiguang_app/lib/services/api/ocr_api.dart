/// 墨迹时光 - 古籍甲骨文智能识别 API 服务
///
/// ## 集成论文技术
/// - DBNet/DBNet++ (Liao et al., 2020/2022) - 可微分二值化文字检测
/// - EAST (Zhou et al., 2017) - 高效场景文字检测
/// - PSENet (Li et al., 2019) - 渐进式尺度扩展文字检测
/// - PAN (Wang et al., 2019) - 像素聚合网络文字检测
/// - CRAFT (Baek et al., 2019) - 字符级区域感知文字检测
/// - TrOCR (Li et al., 2021) - Transformer OCR
/// - ABINet (Fang et al., 2021) - 自主双向网络文字识别
/// - SRN (Yu et al., 2020) - 语义推理网络
/// - PARSeq (Bautista et al., 2022) - 排列自回归序列模型
/// - HAN (Wang et al., 2020) - 分层注意力篇章理解
///
/// 本服务封装与后端 OCR 引擎的所有 HTTP 通信，
/// 包括文字检测、识别、字典查询和语义恢复等接口。
///
/// 依赖: dio ^5.4.3+

import 'package:dio/dio.dart';
import '../../models/ocr/ocr_models.dart';

// ============================================================================
// API 路径常量
// ============================================================================

/// OCR API 端点路径
abstract class _OcrApiPaths {
  static const String detectRegions = '/api/ocr/detect';
  static const String recognizeText = '/api/ocr/recognize';
  static const String queryCandidates = '/api/ocr/candidates';
  static const String lookupDictionary = '/api/ocr/dictionary';
  static const String identifyVariation = '/api/ocr/variation';
  static const String restoreSemantics = '/api/ocr/restore';
  static const String detectCalligraphy = '/api/ocr/calligraphy';
  static const String batchRecognize = '/api/ocr/batch';
  static const String health = '/api/ocr/health';
}

// ============================================================================
// OCR API 服务类
// ============================================================================

/// 古籍 OCR API 服务
///
/// 提供文字检测、识别、字典关联、异体字识别等全套接口。
class OcrApiService {
  final Dio _dio;

  /// 创建 OCR API 服务实例
  ///
  /// [dio] - Dio HTTP 客户端实例。如果未提供，将使用默认配置。
  OcrApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.mojishiguang.cn',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  /// 获取底层 Dio 实例
  Dio get dio => _dio;

  // ==========================================================================
  //  1. 文字区域检测
  // ==========================================================================

  /// 对输入图片进行文字区域检测
  ///
  /// [imageBytes] - 图片的字节数据
  /// [detector] - 使用的检测器枚举
  /// [confidenceThreshold] - 置信度阈值（低于此值的区域将被过滤）
  ///
  /// 返回检测到的文字区域列表。
  ///
  /// 相关论文:
  /// - DBNet++ (Liao et al., 2022): 自适应尺度融合
  /// - EAST (Zhou et al., 2017): 高效端到端检测
  /// - CRAFT (Baek et al., 2019): 字符级区域感知
  Future<List<TextRegion>> detectTextRegions(
    List<int> imageBytes, {
    OcrDetector detector = OcrDetector.dbnetPlusPlus,
    double confidenceThreshold = 0.5,
  }) async {
    try {
      final FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'image.jpg'),
        'detector': detector.name,
        'confidence_threshold': confidenceThreshold,
      });

      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.detectRegions,
        data: formData,
      );

      final List<dynamic> regionsJson =
          response.data?['regions'] as List<dynamic>? ?? [];
      final List<TextRegion> regions = regionsJson
          .map((e) => TextRegion.fromJson(e as Map<String, dynamic>))
          .toList();

      return regions;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  2. 古籍 OCR 识别
  // ==========================================================================

  /// 对已检测到的文字区域进行古籍文字识别
  ///
  /// [imageBytes] - 图片的字节数据
  /// [regions] - 已检测到的文字区域列表
  /// [recognizer] - 使用的识别器枚举
  /// [enableDictionary] - 是否启用字典关联
  /// [language] - 识别语言
  ///
  /// 返回完整的 OCR 识别结果。
  ///
  /// 相关论文:
  /// - TrOCR (Li et al., 2021): Transformer OCR
  /// - ABINet (Fang et al., 2021): 自主双向网络
  /// - SRN (Yu et al., 2020): 语义推理网络
  Future<OcrResult> recognizeAncientText({
    required List<int> imageBytes,
    required List<TextRegion> regions,
    OcrRecognizer recognizer = OcrRecognizer.trocr,
    bool enableDictionary = true,
    String language = 'zh',
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'image': await _encodeImageBytes(imageBytes),
        'regions': regions.map((r) => r.toJson()).toList(),
        'recognizer': recognizer.name,
        'enable_dictionary': enableDictionary,
        'language': language,
        'is_ancient_text': true,
      };

      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.recognizeText,
        data: requestBody,
      );

      return OcrResult.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  3. 单字候选字查询
  // ==========================================================================

  /// 查询单个字符的候选识别结果
  ///
  /// [character] - 待查询的字符
  /// [context] - 上下文文本（用于语言模型辅助推断）
  /// [topK] - 返回的候选数量
  ///
  /// 返回候选字符列表，按置信度降序排列。
  ///
  /// 相关论文:
  /// - ABINet (Fang et al., 2021): 双向语言模型
  /// - PARSeq (Bautista et al., 2022): 排列自回归建模
  Future<List<CharacterCandidate>> queryCandidates({
    required String character,
    required String context,
    int topK = 5,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.queryCandidates,
        data: {
          'character': character,
          'context': context,
          'top_k': topK,
        },
      );

      final List<dynamic> candidatesJson =
          response.data?['candidates'] as List<dynamic>? ?? [];
      return candidatesJson
          .map((e) => CharacterCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  4. 字典关联查询（说文解字等）
  // ==========================================================================

  /// 查询字符在古籍字典中的释义
  ///
  /// [character] - 待查询的字符
  ///
  /// 返回字典条目，包含说文解字、康熙字典等信息。
  ///
  /// 集成资源:
  /// - 《说文解字》(许慎, 东汉)
  /// - 《康熙字典》(张玉书等, 清)
  /// - 《尔雅》
  /// - 《广韵》
  Future<DictionaryEntry> lookupDictionary(String character) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio.get(
        '${_OcrApiPaths.lookupDictionary}/$character',
      );

      return DictionaryEntry.fromJson(response.data ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return DictionaryEntry(
          character: character,
          modernMeaning: '未找到该字的字典记录',
          ancientUsages: [],
          relatedCharacters: [],
        );
      }
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  5. 异体字/避讳字识别
  // ==========================================================================

  /// 识别字符是否为异体字或避讳字
  ///
  /// [character] - 待识别的字符
  /// [era] - 所属朝代/时期（可选）
  ///
  /// 返回异体字/避讳字的详细信息。
  ///
  /// 相关论文:
  /// - HAN (Wang et al., 2020): 分层注意力篇章理解
  Future<VariationInfo> identifyVariation(
    String character, {
    String? era,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.identifyVariation,
        data: {
          'character': character,
          'era': era,
        },
      );

      return VariationInfo.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  6. 整篇古文语义恢复
  // ==========================================================================

  /// 对 OCR 识别文本进行语义恢复和分析
  ///
  /// [recognizedText] - OCR 识别出的原始文本
  /// [enablePunctuation] - 是否自动添加句读
  /// [enableTranslation] - 是否生成现代汉语翻译
  ///
  /// 返回语义恢复结果，包含断句、纠错和翻译等信息。
  ///
  /// 相关论文:
  /// - HAN (Wang et al., 2020): 分层注意力网络
  /// - ERNIE-Arch (Baidu, 2021): 古文预训练模型
  Future<SemanticRestoration> restoreSemantics(
    String recognizedText, {
    bool enablePunctuation = true,
    bool enableTranslation = true,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.restoreSemantics,
        data: {
          'text': recognizedText,
          'enable_punctuation': enablePunctuation,
          'enable_translation': enableTranslation,
          'text_type': 'ancient_chinese',
        },
      );

      return SemanticRestoration.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  7. 书法风格检测
  // ==========================================================================

  /// 检测图片中文字的书法风格
  ///
  /// [imageBytes] - 图片字节数据
  /// [region] - 文字区域（可选，不指定则检测整图）
  ///
  /// 返回书法风格分类信息。
  ///
  /// 相关论文:
  /// - CALLIGRAPHY-AI (Li et al., 2021): 书法风格分类
  Future<CalligraphyStyle> detectCalligraphy(
    List<int> imageBytes, {
    TextRegion? region,
  }) async {
    try {
      final FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'image.jpg'),
        if (region != null) 'region': region.toJson(),
      });

      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.detectCalligraphy,
        data: formData,
      );

      return CalligraphyStyle.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  8. 批量识别
  // ==========================================================================

  /// 批量识别多张图片
  ///
  /// [imageBatches] - 多张图片字节数据列表
  /// [detector] - 检测器
  /// [recognizer] - 识别器
  ///
  /// 返回多个 OCR 结果列表。
  Future<List<OcrResult>> batchRecognize({
    required List<List<int>> imageBatches,
    OcrDetector detector = OcrDetector.dbnetPlusPlus,
    OcrRecognizer recognizer = OcrRecognizer.trocr,
  }) async {
    try {
      final FormData formData = FormData.fromMap({
        'detector': detector.name,
        'recognizer': recognizer.name,
      });

      for (int i = 0; i < imageBatches.length; i++) {
        formData.files.add(MapEntry(
          'images',
          MultipartFile.fromBytes(imageBatches[i], filename: 'image_$i.jpg'),
        ));
      }

      final Response<Map<String, dynamic>> response = await _dio.post(
        _OcrApiPaths.batchRecognize,
        data: formData,
      );

      final List<dynamic> resultsJson =
          response.data?['results'] as List<dynamic>? ?? [];
      return resultsJson
          .map((e) => OcrResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==========================================================================
  //  9. 健康检查
  // ==========================================================================

  /// 检查 OCR 服务健康状态
  Future<bool> checkHealth() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get(_OcrApiPaths.health);
      return response.data?['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  // ==========================================================================
  //  内部方法
  // ==========================================================================

  /// 将图片字节编码为 Base64 字符串
  Future<String> _encodeImageBytes(List<int> bytes) async {
    // 对于小图片直接编码；大图片通过分片上传
    if (bytes.length < 10 * 1024 * 1024) {
      return _base64Encode(bytes);
    }
    throw ArgumentError('图片大小超过限制（10MB）');
  }

  /// Base64 编码（纯 Dart 实现，不依赖 dart:convert）
  String _base64Encode(List<int> bytes) {
    const String charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final int b1 = bytes[i];
      final int b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final int b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      final int triple = (b1 << 16) | (b2 << 8) | b3;
      buffer.write(charset[(triple >> 18) & 0x3F]);
      buffer.write(charset[(triple >> 12) & 0x3F]);
      buffer.write(i + 1 < bytes.length ? charset[(triple >> 6) & 0x3F] : '=');
      buffer.write(i + 2 < bytes.length ? charset[triple & 0x3F] : '=');
    }
    return buffer.toString();
  }

  /// 统一处理 Dio 异常
  OcrApiException _handleDioError(DioException e) {
    String message;
    int? statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        message = '发送数据超时';
      case DioExceptionType.receiveTimeout:
        message = '接收响应超时';
      case DioExceptionType.badResponse:
        message = _parseErrorMessage(e.response?.data) ?? '服务端错误 ($statusCode)';
      case DioExceptionType.cancel:
        message = '请求已取消';
      case DioExceptionType.connectionError:
        message = '无法连接到服务器，请检查网络';
      default:
        message = '未知网络错误: ${e.message}';
    }

    return OcrApiException(
      message: message,
      statusCode: statusCode,
      originalError: e,
    );
  }

  /// 解析服务端返回的错误信息
  String? _parseErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    if (data is String) return data;
    return null;
  }
}

// ============================================================================
// 自定义异常
// ============================================================================

/// OCR API 调用异常
class OcrApiException implements Exception {
  /// 错误信息
  final String message;

  /// HTTP 状态码
  final int? statusCode;

  /// 原始 Dio 异常
  final DioException? originalError;

  /// 默认构造函数
  const OcrApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'OcrApiException: $message (status: $statusCode)';
}

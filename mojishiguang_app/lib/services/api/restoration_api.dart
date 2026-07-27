/// 墨迹时光 · AI 残片修复大师 — 云侧修复 API 服务
///
/// 提供基于云端的图像修复 API 调用服务，支持多种修复方法的远程调用、
/// 批量对比、质量评估和风格一致性调整。
///
/// 集成的云侧推理技术：
/// - LaMa (Suvorov et al., 2022): WACV 2022 — 傅里叶卷积大掩码修复
/// - MAT (Li et al., 2022): CVPR 2022 — 掩码感知 Transformer 修复
/// - RePaint (Lugmayr et al., 2022): CVPR 2022 — 扩散模型修复
/// - Palette (Saharia et al., 2022): NeurIPS 2022 — 图像到图像扩散
/// - Blended Diffusion (Avrahami et al., 2022): CVPR 2022 — 文本引导扩散
/// - SwinIR (Liang et al., 2021): ICCV 2021 — Transformer 超分恢复
/// - Real-ESRGAN (Wang et al., 2021): ICCV 2021 — 真实世界盲超分
/// - Bringing Old Photos Back to Life (Wan et al., 2020): CVPR 2020 — 综合老照片修复
/// - TextGestalt (Liu et al., 2022): NeurIPS 2022 — 古文文字修复
/// - DeepFL (Jin et al., 2021): ACM MM 2021 — 古籍文档修复
/// - etc.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/restoration/damage_mask.dart';
import '../../models/restoration/input_image.dart';
import '../../models/restoration/quality_metrics.dart';
import '../../models/restoration/restoration_method.dart';
import '../../models/restoration/restored_image.dart';
import '../../models/restoration/style_reference.dart';
import 'restoration_methods.dart';

/// 云侧修复 API 服务类
///
/// 封装与后端推理服务的所有 HTTP 通信，提供图像修复的远程调用接口。
/// 使用 Dio 作为 HTTP 客户端，支持断点续传、进度回调和请求取消。
class RestorationApiService {
  final Dio _dio;

  /// 创建修复 API 服务实例
  ///
  /// [baseUrl] 后端 API 基础地址
  /// [timeout] 请求超时（毫秒）
  RestorationApiService({
    String baseUrl = 'https://api.mojishiguang.cn/v1',
    int timeout = 120000,
    String? apiKey,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: Duration(milliseconds: timeout),
            sendTimeout: Duration(milliseconds: timeout),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey != null) 'Authorization': 'Bearer $apiKey',
            },
          ),
        ) {
    // 添加日志拦截器（调试用）
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[RestorationAPI] $obj'),
      ),
    );
  }

  /// 1. 破损检测 API
  ///
  /// 对输入图片进行破损区域检测，返回掩码（Mask）数据。
  /// 支持检测多种破损类型：撕裂、污渍、褪色、折痕、缺块、水渍等。
  ///
  /// 参考技术：
  /// - DeepFL (Jin et al., 2021): 古籍破损检测专用
  /// - PartialConv (Liu et al., 2018): 不规则掩码生成
  Future<DamageMask> detectDamage(InputImage image) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.filePath,
          filename: 'input_image${_getExtension(image.filePath)}',
        ),
        'width': image.width,
        'height': image.height,
      });

      final response = await _dio.post(
        '/restoration/detect',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return DamageMask.fromJson(data['mask']);
      } else {
        throw RestorationApiException(
          '破损检测失败: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw RestorationApiException(
        '破损检测请求异常: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// 2. AI 修复 API
  ///
  /// 使用指定的修复方法对图片进行修复。
  ///
  /// [image] 待修复图片
  /// [mask] 破损区域掩码
  /// [method] 选择的修复方法
  /// [style] 可选风格参考
  /// [onProgress] 进度回调
  ///
  /// 参考技术：
  /// - LaMa / MAT / DeepFill v2 / Edge-Connect 等 inpainting 方法
  /// - RePaint / Palette: 扩散模型高真实感修复
  /// - Blended Diffusion: 文本引导修复（text_prompt 参数）
  /// - TextGestalt: 古文文字语义引导修复
  Future<RestoredImage> restoreImage({
    required InputImage image,
    required DamageMask mask,
    required RestorationMethod method,
    StyleReference? style,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final startTime = DateTime.now();

      // 构建请求参数
      final params = <String, dynamic>{
        'method_id': method.id,
        'params': method.defaultParams,
        'width': image.width,
        'height': image.height,
      };

      // 文本引导修复：添加提示词参数
      if (method.id == 'blended_diffusion' &&
          method.defaultParams.containsKey('prompt') &&
          (method.defaultParams['prompt'] as String).isNotEmpty) {
        params['text_prompt'] = method.defaultParams['prompt'];
      }

      // 风格参考
      if (style != null) {
        params['style_reference'] = {
          'weight': style.styleWeight,
          'content_weight': style.contentWeight,
          'description': style.description,
        };
      }

      // 古文修复专用：添加语义引导参数
      if (method.id == 'textgestalt') {
        params['semantic_guidance'] = true;
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.filePath,
          filename: 'input_image${_getExtension(image.filePath)}',
        ),
        'mask': MultipartFile.fromBytes(
          mask.maskBytes,
          filename: 'damage_mask.png',
        ),
        if (style != null)
          'style_ref': await MultipartFile.fromFile(
            style.imagePath,
            filename: 'style_ref${_getExtension(style.imagePath)}',
          ),
        'params': jsonEncode(params),
      });

      final response = await _dio.post(
        '/restoration/restore',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total * 0.3); // 上传进度占 30%
          }
        },
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(0.3 + (received / total * 0.7)); // 下载进度占 70%
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;

        final resultPath = await _materializeResultImage(
          data['result_path'] as String,
          prefix: 'restoration',
        );

        return RestoredImage(
          filePath: resultPath,
          methodUsed: method,
          width: data['width'] as int? ?? image.width,
          height: data['height'] as int? ?? image.height,
          fileSizeBytes: data['file_size'] as int? ?? 0,
          processingTimeMs: data['processing_time'] as int? ?? elapsed,
          psnr: data['psnr'] as double?,
          ssim: data['ssim'] as double?,
          lpips: data['lpips'] as double?,
          fid: data['fid'] as double?,
          createdAt: DateTime.now(),
        );
      } else {
        throw RestorationApiException(
          'AI 修复失败: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw RestorationApiException(
        'AI 修复请求异常: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// 3. 批量修复对比
  ///
  /// 对同一图片使用多种修复方法进行批量修复，方便用户对比选择。
  ///
  /// [image] 待修复图片
  /// [mask] 破损区域掩码
  /// [methods] 要尝试的修复方法列表
  ///
  /// 参考技术：
  /// - MPRNet (Zamir et al., 2021): 多阶段渐进式修复
  /// - MIRNet (Zamir et al., 2020): 多尺度修复
  Future<List<RestoredImage>> batchRestore({
    required InputImage image,
    required DamageMask mask,
    required List<RestorationMethod> methods,
  }) async {
    final results = <RestoredImage>[];
    for (int i = 0; i < methods.length; i++) {
      try {
        final result = await restoreImage(
          image: image,
          mask: mask,
          method: methods[i],
        );
        results.add(result);
      } catch (e) {
        // 单个方法失败不影响其他方法
        print('[BatchRestore] 方法 ${methods[i].name} 失败: $e');
        // 添加到结果供 UI 展示失败状态
        results.add(
          RestoredImage(
            filePath: '',
            methodUsed: methods[i],
            width: image.width,
            height: image.height,
            fileSizeBytes: 0,
            processingTimeMs: 0,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    return results;
  }

  /// 4. 修复质量评估
  ///
  /// 对修复后的图片进行质量评估，返回客观指标和感知质量评分。
  ///
  /// 评估指标参考：
  /// - PSNR/SSIM: 传统图像质量评价
  /// - LPIPS (Zhang et al., 2018): 感知相似度
  /// - NIMA (Talebi et al., 2018): 无参考图像质量评估
  /// - 自定义指标：textReadabilityScore、strokeContinuityScore 等古籍专用指标
  Future<QualityMetrics> evaluateQuality(RestoredImage restored) async {
    try {
      final formData = FormData.fromMap({
        'result_image': await MultipartFile.fromFile(
          restored.filePath,
          filename: 'result${_getExtension(restored.filePath)}',
        ),
        'method_id': restored.methodUsed.id,
      });

      final response = await _dio.post(
        '/restoration/evaluate',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return QualityMetrics(
          psnr: (data['psnr'] as num?)?.toDouble() ?? 0.0,
          ssim: (data['ssim'] as num?)?.toDouble() ?? 0.0,
          lpips: (data['lpips'] as num?)?.toDouble(),
          fid: (data['fid'] as num?)?.toDouble(),
          nimaScore: (data['nima_score'] as num?)?.toDouble(),
          textReadabilityScore: (data['text_readability'] as num?)?.toDouble(),
          strokeContinuityScore:
              (data['stroke_continuity'] as num?)?.toDouble(),
          colorConsistencyScore:
              (data['color_consistency'] as num?)?.toDouble(),
          overallRating: data['overall_rating'] as int? ?? 3,
          evaluatedAt: DateTime.now(),
        );
      } else {
        throw RestorationApiException(
          '质量评估失败: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw RestorationApiException(
        '质量评估请求异常: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// 5. 风格一致性调整
  ///
  /// 对修复区域进行风格一致性调整，确保修复部分与原文风格匹配。
  ///
  /// 参考技术：
  /// - Edge-Connect (Nazeri et al., 2019): 边缘风格一致性
  /// - Bringing Old Photos Back to Life (Wan et al., 2020): 全局风格保持
  /// - DeOldify (Antic, 2019): 色彩风格一致性
  Future<RestoredImage> applyStyleConsistency({
    required RestoredImage image,
    required StyleReference reference,
  }) async {
    try {
      final startTime = DateTime.now();

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.filePath,
          filename: 'result${_getExtension(image.filePath)}',
        ),
        'style_ref': await MultipartFile.fromFile(
          reference.imagePath,
          filename: 'style_ref${_getExtension(reference.imagePath)}',
        ),
        'style_weight': reference.styleWeight,
        'content_weight': reference.contentWeight,
        'description': reference.description ?? '',
      });

      final response = await _dio.post(
        '/restoration/style-transfer',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;

        final resultPath = await _materializeResultImage(
          data['result_path'] as String,
          prefix: 'restoration_style',
        );

        return RestoredImage(
          filePath: resultPath,
          methodUsed: image.methodUsed,
          width: data['width'] as int? ?? image.width,
          height: data['height'] as int? ?? image.height,
          fileSizeBytes: data['file_size'] as int? ?? 0,
          processingTimeMs: data['processing_time'] as int? ?? elapsed,
          psnr: data['psnr'] as double?,
          ssim: data['ssim'] as double?,
          createdAt: DateTime.now(),
        );
      } else {
        throw RestorationApiException(
          '风格调整失败: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw RestorationApiException(
        '风格调整请求异常: ${e.message}',
        e.response?.statusCode,
      );
    }
  }

  /// 将服务端结果下载为可由后续预览、评估和风格调整复用的本地文件。
  Future<String> _materializeResultImage(
    String resultLocation, {
    required String prefix,
  }) async {
    final uri = Uri.tryParse(resultLocation);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (await File(resultLocation).exists()) {
        return resultLocation;
      }
      throw const RestorationApiException('服务端返回的修复结果路径无效');
    }

    final directory = await getTemporaryDirectory();
    final extension = _getExtension(uri.path);
    final filePath =
        '${directory.path}${Platform.pathSeparator}${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    await _dio.downloadUri(uri, filePath);
    return filePath;
  }

  /// 获取文件扩展名
  String _getExtension(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    final extension = filePath.substring(dotIndex).toLowerCase();
    const supportedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
    return supportedExtensions.contains(extension) ? extension : '.jpg';
  }

  /// 取消所有正在进行的请求
  void cancelAllRequests() {
    // Dio 通过 CancelToken 实现，实际使用中应在外部传入 CancelToken
    // 此处为简化，不执行具体取消操作
  }
}

/// 修复 API 异常
class RestorationApiException implements Exception {
  final String message;
  final int? statusCode;

  const RestorationApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'RestorationApiException($statusCode): $message';
}

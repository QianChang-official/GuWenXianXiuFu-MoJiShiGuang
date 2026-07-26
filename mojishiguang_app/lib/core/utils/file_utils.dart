import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../constants/app_constants.dart';

/// 文件工具类
class FileUtils {
  FileUtils._();

  // ─── 目录管理 ──────────────────────────────────────────────

  /// 获取应用缓存根目录
  static Future<Directory> getCacheDirectory() async {
    return getTemporaryDirectory();
  }

  /// 获取应用文档目录（持久存储）
  static Future<Directory> getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  /// 获取模型缓存目录
  static Future<Directory> getModelCacheDirectory() async {
    final Directory cacheDir = await getCacheDirectory();
    final Directory modelDir = Directory('${cacheDir.path}/${AppConstants.modelCacheDir}');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// 获取临时文件目录
  static Future<Directory> getTempDirectory() async {
    final Directory cacheDir = await getCacheDirectory();
    final Directory tempDir = Directory('${cacheDir.path}/${AppConstants.tempDir}');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// 获取结果缓存目录
  static Future<Directory> getResultCacheDirectory() async {
    final Directory cacheDir = await getCacheDirectory();
    final Directory resultDir = Directory('${cacheDir.path}/${AppConstants.resultCacheDir}');
    if (!await resultDir.exists()) {
      await resultDir.create(recursive: true);
    }
    return resultDir;
  }

  /// 清空临时文件
  static Future<void> clearTempFiles() async {
    final Directory tempDir = await getTempDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }
  }

  // ─── 模型文件管理 ─────────────────────────────────────────

  /// 检查模型文件是否已缓存
  static Future<bool> isModelCached(String modelName) async {
    final Directory modelDir = await getModelCacheDirectory();
    final File modelFile = File('${modelDir.path}/$modelName');
    return modelFile.exists();
  }

  /// 获取模型文件路径
  static Future<String> getModelPath(String modelName) async {
    final Directory modelDir = await getModelCacheDirectory();
    return '${modelDir.path}/$modelName';
  }

  /// 保存模型文件到缓存
  static Future<File> saveModelFile({
    required String modelName,
    required Uint8List bytes,
  }) async {
    final Directory modelDir = await getModelCacheDirectory();
    final File modelFile = File('${modelDir.path}/$modelName');
    return modelFile.writeAsBytes(bytes);
  }

  /// 删除缓存的模型文件
  static Future<void> deleteModelFile(String modelName) async {
    final String modelPath = await getModelPath(modelName);
    final File modelFile = File(modelPath);
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
  }

  /// 获取模型文件大小
  static Future<int> getModelFileSize(String modelName) async {
    final String modelPath = await getModelPath(modelName);
    final File modelFile = File(modelPath);
    if (await modelFile.exists()) {
      return modelFile.length();
    }
    return 0;
  }

  /// 验证模型文件完整性（检查文件头和大小）
  static Future<bool> validateModelFile(String modelName) async {
    try {
      final String modelPath = await getModelPath(modelName);
      final File modelFile = File(modelPath);
      if (!await modelFile.exists()) return false;

      final int fileSize = await modelFile.length();
      if (fileSize == 0) return false;

      // TFLite 模型文件头校验: 以 0x1C 开���（FlatBuffers 标识）
      final RandomAccessFile raf = await modelFile.open(mode: FileMode.read);
      final int firstByte = await raf.readByte();
      await raf.close();
      return firstByte == 0x1C;
    } catch (e) {
      debugPrint('模型文件校验失败: $e');
      return false;
    }
  }

  // ─── 临时文件管理 ─────────────────────────────────────────

  /// 生成临时文件路径
  static Future<String> createTempFilePath({
    required String extension,
    String? prefix,
  }) async {
    final Directory tempDir = await getTempDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = '${prefix ?? 'temp'}_$timestamp.$extension';
    return '${tempDir.path}/$fileName';
  }

  /// 创建临时文件并写入数据
  static Future<File> createTempFile({
    required Uint8List bytes,
    required String extension,
    String? prefix,
  }) async {
    final String filePath = await createTempFilePath(
      extension: extension,
      prefix: prefix,
    );
    final File file = File(filePath);
    return file.writeAsBytes(bytes);
  }

  /// 清理过期临时文件（超过24小时）
  static Future<void> cleanExpiredTempFiles({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final Directory tempDir = await getTempDirectory();
    if (!await tempDir.exists()) return;

    final DateTime now = DateTime.now();
    await for (final FileSystemEntity entity in tempDir.list()) {
      if (entity is File) {
        final FileStat stat = await entity.stat();
        if (now.difference(stat.modified) > maxAge) {
          await entity.delete();
        }
      }
    }
  }

  // ─── JSON 序列化辅助 ──────────────────────────────────────

  /// 将对象保存为 JSON 文件
  static Future<File> saveJsonToFile({
    required Map<String, dynamic> json,
    required String fileName,
  }) async {
    final Directory resultDir = await getResultCacheDirectory();
    final File file = File('${resultDir.path}/$fileName.json');
    return file.writeAsString(jsonEncode(json));
  }

  /// 从 JSON 文件读取
  static Future<Map<String, dynamic>?> loadJsonFromFile({
    required String fileName,
  }) async {
    try {
      final Directory resultDir = await getResultCacheDirectory();
      final File file = File('${resultDir.path}/$fileName.json');
      if (!await file.exists()) return null;
      final String content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('读取 JSON 文件失败: $e');
      return null;
    }
  }

  /// 获取文件扩展名
  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// 检查文件类型是否支持
  static bool isSupportedImage(String path) {
    final String ext = getFileExtension(path);
    return AppConstants.supportedImageFormats.contains(ext);
  }

  /// 获取文件大小（可读格式）
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 通过 URL 缓存文件
  static Future<File?> cacheFileFromUrl(String url, String key) async {
    try {
      final FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(key);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
      final File file = await DefaultCacheManager().getSingleFile(url, key: key);
      return file;
    } catch (e) {
      debugPrint('缓存文件失败: $e');
      return null;
    }
  }
}

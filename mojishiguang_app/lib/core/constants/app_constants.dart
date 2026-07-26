/// 墨迹时光应用全局常量
class AppConstants {
  AppConstants._();

  // ─── API 配置 ──────────────────────────────────────────────

  /// API 基础地址
  static const String apiBaseUrl = 'https://api.mojishiguang.com/v1';

  /// API 请求超时时间（毫秒）
  static const int apiTimeoutMs = 30000;

  /// API 重试次数
  static const int apiRetryCount = 3;

  // ─── 缓存路径 ──────────────────────────────────────────────

  /// 模型缓存目录名
  static const String modelCacheDir = 'models';

  /// 图片缓存目录名
  static const String imageCacheDir = 'images';

  /// 结果缓存目录名
  static const String resultCacheDir = 'results';

  /// 临时文件目录名
  static const String tempDir = 'temp';

  // ─── 图片处理 ──────────────────────────────────────────────

  /// 最大图片尺寸（像素），超过此尺寸将进行压缩
  static const int maxImageDimension = 2048;

  /// 图片压缩质量 (0-100)
  static const int imageCompressQuality = 85;

  /// 模型输入标准尺寸（像素）
  static const int modelInputSize = 512;

  /// 缩略图尺寸（像素）
  static const int thumbnailSize = 200;

  /// 最大文件大小（字节），超过此大小将拒绝上传
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB

  // ─── 路由名称 ──────────────────────────────────────────────

  /// 首页
  static const String routeHome = '/';

  /// 古籍修复页
  static const String routeRestoration = '/restoration';

  /// 修复工作流页
  static const String routeRestorationWorkflow = '/restoration/workflow';

  /// OCR 文字识别页
  static const String routeOcr = '/ocr';

  /// 单字详情页
  static const String routeOcrDetail = '/ocr/detail';

  /// 知识图谱页
  static const String routeKg = '/kg';

  /// 实体详情页
  static const String routeKgEntity = '/kg/entity';

  /// 风格迁移页
  static const String routeStylization = '/stylization';

  /// 书法对比页
  static const String routeStylizationCompare = '/stylization/compare';

  // ─── 支持的文件类型 ────────────────────────────────────────

  /// 支持的图片格式
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'bmp',
    'tiff',
    'tif',
    'webp',
  ];

  /// 支持的古籍文档格式
  static const List<String> supportedDocFormats = [
    'pdf',
    'djvu',
  ];

  /// MIME 类型映射
  static const Map<String, String> mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'bmp': 'image/bmp',
    'tiff': 'image/tiff',
    'tif': 'image/tiff',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
  };

  // ─── 模型配置 ──────────────────────────────────────────────

  /// 破损检测模型文件名
  static const String damageDetectModel = 'damage_detect.tflite';

  /// 修复模型文件名（LaMa）
  static const String restorationModelLama = 'lama_restoration.tflite';

  /// 修复模型文件名（MAT）
  static const String restorationModelMat = 'mat_restoration.tflite';

  /// OCR 模型文件名
  static const String ocrModel = 'ocr_model.tflite';

  /// 风格迁移模型文件名
  static const String styleTransferModel = 'style_transfer.tflite';

  // ─── OCR 配置 ──────────────────────────────────────────────

  /// OCR 识别置信度阈值
  static const double ocrConfidenceThreshold = 0.6;

  /// 候选字最大数量
  static const int maxCharacterCandidates = 5;

  // ─── 知识图谱配置 ──────────────────────────────────────────

  /// 知识图谱最大显示深度
  static const int kgMaxDepth = 6;

  /// 知识图谱默认展开层级
  static const int kgDefaultExpandLevel = 2;

  // ─── 风格迁移配置 ──────────────────────────────────────────

  /// 风格化强度范围
  static const double styleStrengthMin = 0.1;
  static const double styleStrengthMax = 1.0;
  static const double styleStrengthDefault = 0.7;

  // ─── 分页配置 ──────────────────────────────────────────────

  /// 默认每页数量
  static const int defaultPageSize = 20;

  /// 默认起始页码
  static const int defaultPageIndex = 1;

  // ─── 动画配置 ──────────────────────────────────────────────

  /// 默认动画时长（毫秒）
  static const int defaultAnimationDurationMs = 300;

  /// 页面切换动画时长（毫秒）
  static const int pageTransitionDurationMs = 350;
}

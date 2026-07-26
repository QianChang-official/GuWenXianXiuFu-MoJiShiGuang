/// 墨迹时光 - 古籍甲骨文智能识别
///
/// ## 集成论文技术
/// - DBNet / DBNet++ (Liao et al., 2020/2022) - 可微分二值化文字检测
/// - EAST (Zhou et al., 2017) - 高效场景文字检测
/// - CRAFT (Baek et al., 2019) - 字符级区域感知文字检测
/// - PSENet (Li et al., 2019) - 渐进式尺度扩展
/// - TrOCR (Li et al., 2021) - Transformer OCR
/// - ABINet (Fang et al., 2021) - 自主双向网络
///
/// 本文件定义 OCR 模块的核心数据模型，包括：
/// - 文字检测区域、OCR 结果、候选字、字典条目等
/// - 检测器和识别器的枚举
///
// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ocr_models.g.dart';

// ============================================================================
// 枚举定义
// ============================================================================

/// OCR 处理步骤枚举
enum OcrStep {
  /// 等待输入图片
  input,

  /// 文字区域检测中
  detection,

  /// 文字识别中
  recognition,

  /// 字典关联查询中
  dictionary,

  /// 识别完成
  complete,

  /// 出错状态
  error,
}

/// 文字检测器选择枚举
///
/// 对应集成论文中的检测算法：
/// - `dbnetPlusPlus`: DBNet++ 自适应尺度融合（推荐，默认）
/// - `east`: EAST 快速检测
/// - `craft`: CRAFT 字符级检测
/// - `pan`: PAN 像素聚合检测
/// - `psenet`: PSENet 渐进式扩展
/// - `fcenet`: FCENet 傅里叶轮廓
enum OcrDetector {
  /// DBNet++ 自适应尺度融合（默认推荐）
  dbnetPlusPlus,

  /// DBNet 可微分二值化
  dbnet,

  /// EAST 高效检测
  east,

  /// CRAFT 字符级区域感知
  craft,

  /// PAN 像素聚合
  pan,

  /// PSENet 渐进式扩展
  psenet,

  /// SAST 单次任意形状检测
  sast,

  /// FCENet 傅里叶轮廓嵌入
  fcenet,
}

/// 文字识别器选择枚举
///
/// 对应集成论文中的识别算法：
/// - `trocr`: TrOCR Transformer OCR（推荐，默认）
/// - `abinet`: ABINet 自主双向网络
/// - `parseq`: PARSeq 排列自回归模型
/// - `svtr`: SVTR 纯视觉模型
enum OcrRecognizer {
  /// TrOCR Transformer OCR（默认推荐）
  trocr,

  /// ABINet 自主双向网络
  abinet,

  /// SRN 语义推理网络
  srn,

  /// VisionLAN 视觉语言注意力
  visionlan,

  /// PARSeq 排列自回归模型
  parseq,

  /// MASTER 多头注意力
  master,

  /// SVTR 纯视觉模型（轻量）
  svtr,

  /// CRNN 经典基线
  crnn,
}

/// 识别模式
enum OcrMode {
  /// 快速识别 - 使用轻量模型，适合预览
  quick,

  /// 深度分析 - 使用高精度模型，带字典和语义分析
  deepAnalysis,
}

// ============================================================================
// 数据模型
// ============================================================================

/// 文字检测区域 - 图片中检测到的单个文字区域
///
/// 包含边界框坐标、置信度分数和识别文字等信息。
@immutable
@JsonSerializable()
class TextRegion extends Equatable {
  /// 区域唯一标识
  final String id;

  /// 边界框左上角 x 坐标（归一化 0~1）
  final double x;

  /// 边界框左上角 y 坐标（归一化 0~1）
  final double y;

  /// 边界框宽度（归一化 0~1）
  final double width;

  /// 边界框高度（归一化 0~1）
  final double height;

  /// 旋转角度（弧度，用于旋转矩形框）
  final double rotation;

  /// 检测置信度（0~1）
  final double confidence;

  /// 识别出的文字（识别阶段后填充）
  final String? text;

  /// 该区域的识别置信度（识别阶段后填充）
  final double? textConfidence;

  /// 是否为竖排文字
  final bool isVertical;

  /// 排序序号（从上到下、从右到左的阅读顺序）
  final int sortOrder;

  /// 默认构造函数
  const TextRegion({
    this.id = '',
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.confidence = 0.0,
    this.text,
    this.textConfidence,
    this.isVertical = false,
    this.sortOrder = 0,
  });

  /// 从 JSON 创建
  factory TextRegion.fromJson(Map<String, dynamic> json) =>
      _$TextRegionFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$TextRegionToJson(this);

  /// 获取边界框中心 x
  double get centerX => x + width / 2;

  /// 获取边界框中心 y
  double get centerY => y + height / 2;

  /// 获取面积
  double get area => width * height;

  @override
  List<Object?> get props => [
        id,
        x,
        y,
        width,
        height,
        rotation,
        confidence,
        text,
        textConfidence,
        isVertical,
        sortOrder,
      ];
}

/// OCR 识别结果 - 整张图片的完整识别输出
@immutable
@JsonSerializable()
class OcrResult extends Equatable {
  /// 识别出的全部文本字符串
  final String fullText;

  /// 各文字区域的详细结果
  final List<TextRegion> regions;

  /// 检测到的文字总行数
  final int lineCount;

  /// 检测到的总字符数
  final int characterCount;

  /// 整体置信度（0~1）
  final double overallConfidence;

  /// 不确定的字符列表（置信度低于阈值）
  final List<UncertainCharacter> uncertainCharacters;

  /// 识别的文本语言
  final String language;

  /// 默认构造函数
  const OcrResult({
    this.fullText = '',
    this.regions = const [],
    this.lineCount = 0,
    this.characterCount = 0,
    this.overallConfidence = 0.0,
    this.uncertainCharacters = const [],
    this.language = 'zh',
  });

  /// 从 JSON 创建
  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$OcrResultToJson(this);

  @override
  List<Object?> get props => [
        fullText,
        regions,
        lineCount,
        characterCount,
        overallConfidence,
        uncertainCharacters,
        language,
      ];
}

/// 不确定字符 - 置信度较低、需要人工确认的字符
@immutable
@JsonSerializable()
class UncertainCharacter extends Equatable {
  /// 该字符在全文中的索引位置
  final int index;

  /// 原始识别字符
  final String character;

  /// 识别置信度（0~1）
  final double confidence;

  /// 候选字符列表
  final List<CharacterCandidate> candidates;

  /// 该字符所在的文字区域 ID
  final String? regionId;

  /// 默认构造函数
  const UncertainCharacter({
    required this.index,
    required this.character,
    required this.confidence,
    this.candidates = const [],
    this.regionId,
  });

  /// 从 JSON 创建
  factory UncertainCharacter.fromJson(Map<String, dynamic> json) =>
      _$UncertainCharacterFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$UncertainCharacterToJson(this);

  @override
  List<Object?> get props => [
        index,
        character,
        confidence,
        candidates,
        regionId,
      ];
}

/// 候选字符 - 单个字符的候选识别结果
@immutable
@JsonSerializable()
class CharacterCandidate extends Equatable {
  /// 候选字符
  final String character;

  /// 置信度分数（0~1）
  final double confidence;

  /// 是否是默认选择
  final bool isDefault;

  /// 来源（如：视觉识别/语言模型/字典匹配）
  final String source;

  /// 默认构造函数
  const CharacterCandidate({
    required this.character,
    required this.confidence,
    this.isDefault = false,
    this.source = 'visual',
  });

  /// 从 JSON 创建
  factory CharacterCandidate.fromJson(Map<String, dynamic> json) =>
      _$CharacterCandidateFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$CharacterCandidateToJson(this);

  @override
  List<Object?> get props => [character, confidence, isDefault, source];
}

/// 字典条目 - 说文解字/康熙字典等古籍字典查询结果
@immutable
@JsonSerializable()
class DictionaryEntry extends Equatable {
  /// 查询的字符
  final String character;

  /// 拼音注音
  final String? pinyin;

  /// 说文解字的释义
  final String? shuowenMeaning;

  /// 康熙字典引文
  final String? kangxiQuotation;

  /// 本义解释
  final String? originalMeaning;

  /// 现代汉语释义
  final String? modernMeaning;

  /// 古籍中常用含义列表
  final List<String> ancientUsages;

  /// 相关字/通假字
  final List<String> relatedCharacters;

  /// 引用来源
  final String? source;

  /// 默认构造函数
  const DictionaryEntry({
    required this.character,
    this.pinyin,
    this.shuowenMeaning,
    this.kangxiQuotation,
    this.originalMeaning,
    this.modernMeaning,
    this.ancientUsages = const [],
    this.relatedCharacters = const [],
    this.source,
  });

  /// 从 JSON 创建
  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DictionaryEntryFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$DictionaryEntryToJson(this);

  @override
  List<Object?> get props => [
        character,
        pinyin,
        shuowenMeaning,
        kangxiQuotation,
        originalMeaning,
        modernMeaning,
        ancientUsages,
        relatedCharacters,
        source,
      ];
}

/// 异体字/避讳字信息
@immutable
@JsonSerializable()
class VariationInfo extends Equatable {
  /// 当前字符
  final String character;

  /// 标准正字
  final String? standardForm;

  /// 异体字类型（异体字/避讳字/俗字/通假字）
  final String variationType;

  /// 使用的朝代/时期
  final String? era;

  /// 说明
  final String? description;

  /// 是否为本朝避讳字
  final bool isTaboo;

  /// 避讳的帝王名讳
  final String? tabooEmperor;

  /// 相关异体形式
  final List<String> variantForms;

  /// 默认构造函数
  const VariationInfo({
    required this.character,
    this.standardForm,
    this.variationType = '异体字',
    this.era,
    this.description,
    this.isTaboo = false,
    this.tabooEmperor,
    this.variantForms = const [],
  });

  /// 从 JSON 创建
  factory VariationInfo.fromJson(Map<String, dynamic> json) =>
      _$VariationInfoFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$VariationInfoToJson(this);

  @override
  List<Object?> get props => [
        character,
        standardForm,
        variationType,
        era,
        description,
        isTaboo,
        tabooEmperor,
        variantForms,
      ];
}

/// 语义恢复结果 - 对OCR识别文本进行古文语义分析和恢复
@immutable
@JsonSerializable()
class SemanticRestoration extends Equatable {
  /// 原始识别文本
  final String originalText;

  /// 语义恢复后的文本
  final String restoredText;

  /// 断句结果（句读标注）
  final String punctuatedText;

  /// 逐句分析
  final List<SentenceAnalysis> sentenceAnalyses;

  /// 更正记录
  final List<CorrectionRecord> corrections;

  /// 通假字识别结果
  final List<VariationInfo> loanCharacters;

  /// 整体语义置信度
  final double confidence;

  /// 默认构造函数
  const SemanticRestoration({
    required this.originalText,
    this.restoredText = '',
    this.punctuatedText = '',
    this.sentenceAnalyses = const [],
    this.corrections = const [],
    this.loanCharacters = const [],
    this.confidence = 0.0,
  });

  /// 从 JSON 创建
  factory SemanticRestoration.fromJson(Map<String, dynamic> json) =>
      _$SemanticRestorationFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$SemanticRestorationToJson(this);

  @override
  List<Object?> get props => [
        originalText,
        restoredText,
        punctuatedText,
        sentenceAnalyses,
        corrections,
        loanCharacters,
        confidence,
      ];
}

/// 句子分析 - 单句的语义分析结果
@immutable
@JsonSerializable()
class SentenceAnalysis extends Equatable {
  /// 句子原文
  final String text;

  /// 断句后的形式
  final String punctuated;

  /// 现代汉语翻译
  final String? translation;

  /// 句子类型（陈述/疑问/感叹等）
  final String? sentenceType;

  /// 关键词语注释
  final List<String> annotations;

  /// 默认构造函数
  const SentenceAnalysis({
    required this.text,
    this.punctuated = '',
    this.translation,
    this.sentenceType,
    this.annotations = const [],
  });

  /// 从 JSON 创建
  factory SentenceAnalysis.fromJson(Map<String, dynamic> json) =>
      _$SentenceAnalysisFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$SentenceAnalysisToJson(this);

  @override
  List<Object?> get props => [
        text,
        punctuated,
        translation,
        sentenceType,
        annotations,
      ];
}

/// 更正记录 - 语义纠错中的单条更正
@immutable
@JsonSerializable()
class CorrectionRecord extends Equatable {
  /// 原有字符
  final String original;

  /// 更正后字符
  final String corrected;

  /// 索引位置
  final int index;

  /// 更正原因（通假/形似/音近/残损等）
  final String reason;

  /// 置信度
  final double confidence;

  /// 默认构造函数
  const CorrectionRecord({
    required this.original,
    required this.corrected,
    required this.index,
    required this.reason,
    this.confidence = 0.0,
  });

  /// 从 JSON 创建
  factory CorrectionRecord.fromJson(Map<String, dynamic> json) =>
      _$CorrectionRecordFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$CorrectionRecordToJson(this);

  @override
  List<Object?> get props => [
        original,
        corrected,
        index,
        reason,
        confidence,
      ];
}

/// OCR 历史记录
@immutable
@JsonSerializable()
class OcrHistoryRecord extends Equatable {
  /// 记录 ID
  final String id;

  /// 创建时间戳
  final DateTime createdAt;

  /// 识别结果摘要（前 50 字）
  final String summary;

  /// 检测器类型
  final OcrDetector detector;

  /// 识别器类型
  final OcrRecognizer recognizer;

  /// 识别模式
  final OcrMode mode;

  /// 识别文本行数
  final int lineCount;

  /// 整体置信度
  final double confidence;

  /// 缩略图路径（本地缓存）
  final String? thumbnailPath;

  /// 默认构造函数
  const OcrHistoryRecord({
    required this.id,
    required this.createdAt,
    this.summary = '',
    this.detector = OcrDetector.dbnetPlusPlus,
    this.recognizer = OcrRecognizer.trocr,
    this.mode = OcrMode.quick,
    this.lineCount = 0,
    this.confidence = 0.0,
    this.thumbnailPath,
  });

  /// 从 JSON 创建
  factory OcrHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$OcrHistoryRecordFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$OcrHistoryRecordToJson(this);

  @override
  List<Object?> get props => [
        id,
        createdAt,
        summary,
        detector,
        recognizer,
        mode,
        lineCount,
        confidence,
        thumbnailPath,
      ];
}

/// 书法风格分类信息
@immutable
@JsonSerializable()
class CalligraphyStyle extends Equatable {
  /// 书体名称（楷书/行书/草书/隶书/篆书）
  final String styleName;

  /// 风格置信度
  final double confidence;

  /// 所属朝代
  final String? dynasty;

  /// 风格特征描述
  final String? description;

  /// 代表书法家
  final String? representativeCalligrapher;

  /// 默认构造函数
  const CalligraphyStyle({
    required this.styleName,
    required this.confidence,
    this.dynasty,
    this.description,
    this.representativeCalligrapher,
  });

  /// 从 JSON 创建
  factory CalligraphyStyle.fromJson(Map<String, dynamic> json) =>
      _$CalligraphyStyleFromJson(json);

  /// 转换为 JSON
  Map<String, dynamic> toJson() => _$CalligraphyStyleToJson(this);

  @override
  List<Object?> get props => [
        styleName,
        confidence,
        dynasty,
        description,
        representativeCalligrapher,
      ];
}

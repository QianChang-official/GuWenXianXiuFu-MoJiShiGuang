import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'character_candidate.dart';

part 'ocr_result.freezed.dart';
part 'ocr_result.g.dart';

/// OCR 识别结果
@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({
    /// 识别出的文本内容
    required String recognizedText,

    /// 每个文字的候选字列表
    required List<CharacterCandidate> candidates,

    /// 整体识别置信度 (0.0 - 1.0)
    required double confidence,

    /// 文字区域列表
    required List<TextRegion> textRegions,

    /// 字体风格（楷/隶/篆/行/草等）
    required String scriptStyle,

    /// 总字数
    required int totalCharacters,

    /// 不确定字数（置信度低于阈值）
    required int uncertainCharacters,

    /// 识别耗时（毫秒）
    required double processingTimeMs,
  }) = _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);
}

/// OCR 文字区域
@freezed
class TextRegion with _$TextRegion {
  const factory TextRegion({
    /// 区域边界框
    required Rect boundingBox,

    /// 该区域识别文本
    required String text,

    /// 区域置信度
    required double confidence,

    /// 如果该区域包含古籍文字，记录对应的原文
    String? originalText,
  }) = _TextRegion;

  factory TextRegion.fromJson(Map<String, dynamic> json) =>
      _$TextRegionFromJson(json);
}

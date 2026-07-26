import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_candidate.freezed.dart';
part 'character_candidate.g.dart';

/// 单字的候选项列表
@freezed
class CharacterCandidate with _$CharacterCandidate {
  const factory CharacterCandidate({
    /// 原始/目标文字
    required String character,

    /// 该字在原文中的位置（像素坐标字符串或索引）
    required String position,

    /// 候选字列表（按置信度排序）
    required List<CandidateChar> alternatives,

    /// 最佳候选置信度
    required double confidence,

    /// 是否不确定（需要人工确认）
    required bool isUncertain,

    /// 对应的字典关联信息
    DictionaryEntry? dictionaryEntry,
  }) = _CharacterCandidate;

  factory CharacterCandidate.fromJson(Map<String, dynamic> json) =>
      _$CharacterCandidateFromJson(json);
}

/// 单个候选字
@freezed
class CandidateChar with _$CandidateChar {
  const factory CandidateChar({
    /// 候选文字
    required String char,

    /// 置信度 (0.0 - 1.0)
    required double confidence,

    /// Unicode 编码
    required int unicode,

    /// 简繁体标记（简体/繁体/异体）
    String? variant,
  }) = _CandidateChar;

  factory CandidateChar.fromJson(Map<String, dynamic> json) =>
      _$CandidateCharFromJson(json);
}

/// 字典条目信息
@freezed
class DictionaryEntry with _$DictionaryEntry {
  const factory DictionaryEntry({
    /// 文字
    required String character,

    /// 拼音
    String? pinyin,

    /// 释义
    String? definition,

    /// 在古籍中出现的例句
    String? example,

    /// 部首
    String? radical,

    /// 笔画数
    int? strokeCount,

    /// 异体字列表
    List<String>? variantCharacters,
  }) = _DictionaryEntry;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DictionaryEntryFromJson(json);
}

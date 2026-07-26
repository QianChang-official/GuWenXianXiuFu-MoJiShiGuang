import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'damage_mask.freezed.dart';
part 'damage_mask.g.dart';

/// 破损类型枚举
enum DamageType {
  /// 虫蛀
  wormEaten,
  /// 水渍
  waterStain,
  /// 缺角
  missingCorner,
  /// 折裂
  foldCrack,
  /// 模糊
  fuzzy,
}

/// 破损区域
@freezed
class DamageRegion with _$DamageRegion {
  const factory DamageRegion({
    /// 破损区域边界框
    required Rect boundingBox,

    /// 破损区域面积（像素数）
    required double area,

    /// 破损严重程度 (0.0 - 1.0)
    required double severity,
  }) = _DamageRegion;

  factory DamageRegion.fromJson(Map<String, dynamic> json) =>
      _$DamageRegionFromJson(json);
}

/// 破损掩码
@freezed
class DamageMask with _$DamageMask {
  const factory DamageMask({
    /// 掩码图片字节
    required Uint8List maskBytes,

    /// 掩码宽度
    required int width,

    /// 掩码高度
    required int height,

    /// 检测置信度 (0.0 - 1.0)
    required double confidence,

    /// 破损区域列表
    required List<DamageRegion> regions,

    /// 破损类型
    required DamageType damageType,
  }) = _DamageMask;

  factory DamageMask.fromJson(Map<String, dynamic> json) =>
      _$DamageMaskFromJson(json);
}

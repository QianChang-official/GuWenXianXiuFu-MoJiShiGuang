import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation.freezed.dart';
part 'relation.g.dart';

/// 关系类型枚举
enum RelationType {
  /// 父子关系
  parentChild,
  /// 师徒关系
  mentorStudent,
  /// 同门关系
  classmate,
  /// 引用/参考
  reference,
  /// 继承
  inheritance,
  /// 影响
  influence,
  /// 创作
  authorship,
  /// 收藏
  collection,
  /// 注释/批注
  annotation,
  /// 相关
  related,
  /// 其他
  other,
}

/// 知识图谱关系
@freezed
class Relation with _$Relation {
  const factory Relation({
    /// 关系唯一标识
    required String id,

    /// 源实体 ID
    required String sourceId,

    /// 目标实体 ID
    required String targetId,

    /// 关系类型
    required RelationType type,

    /// 关系描述
    required String description,

    /// 关系强度 (0.0 - 1.0)
    required double strength,

    /// 关系来源/证据
    required String source,

    /// 是否已验证
    required bool verified,

    /// 创建时间
    required DateTime createdAt,

    /// 额外属性
    Map<String, dynamic>? properties,
  }) = _Relation;

  factory Relation.fromJson(Map<String, dynamic> json) =>
      _$RelationFromJson(json);
}

/// 关系边（用于图结构展示）
@freezed
class GraphEdge with _$GraphEdge {
  const factory GraphEdge({
    /// 边 ID
    required String id,

    /// 源节点 ID
    required String sourceId,

    /// 目标节点 ID
    required String targetId,

    /// 关系标签
    required String label,

    /// 关系类型
    required RelationType type,

    /// 边粗细（根据关系强度）
    required double thickness,

    /// 边的颜色
    required String color,
  }) = _GraphEdge;

  factory GraphEdge.fromJson(Map<String, dynamic> json) =>
      _$GraphEdgeFromJson(json);
}

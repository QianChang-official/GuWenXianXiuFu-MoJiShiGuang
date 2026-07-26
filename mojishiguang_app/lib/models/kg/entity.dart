import 'package:freezed_annotation/freezed_annotation.dart';
import 'relation.dart';

part 'entity.freezed.dart';
part 'entity.g.dart';

/// 实体类型枚举
enum EntityType {
  /// 人物
  person,
  /// 书名/文献
  book,
  /// 朝代
  dynasty,
  /// 地名
  location,
  /// 官职
  official,
  /// 事件
  event,
  /// 术语
  term,
  /// 机构
  institution,
  /// 其他
  other,
}

/// 知识图谱实体
@freezed
class Entity with _$Entity {
  const factory Entity({
    /// 实体唯一标识
    required String id,

    /// 实体名称
    required String name,

    /// 实体类型
    required EntityType type,

    /// 实体描述
    required String description,

    /// 相关实体 ID 列表
    required List<String> relatedEntityIds,

    /// 关联关系列表
    required List<Relation> relations,

    /// 子实体列表（树形结构）
    List<Entity>? children,

    /// 实体重要度 (0.0 - 1.0)
    required double importance,

    /// 创建时间
    required DateTime createdAt,

    /// 更新时间
    required DateTime updatedAt,

    /// 额外属性
    Map<String, dynamic>? properties,
  }) = _Entity;

  factory Entity.fromJson(Map<String, dynamic> json) =>
      _$EntityFromJson(json);
}

/// 知识图谱节点（用于图结构展示）
@freezed
class GraphNode with _$GraphNode {
  const factory GraphNode({
    /// 节点 ID（对应实体 ID）
    required String id,

    /// 节点标签（实体名称）
    required String label,

    /// 节点类型
    required EntityType type,

    /// 节点大小（根据重要度计算）
    required double size,

    /// 节点颜色
    required String color,

    /// X 坐标（布局计算）
    double? x,

    /// Y 坐标（布局计算）
    double? y,

    /// 层级深度
    required int depth,
  }) = _GraphNode;

  factory GraphNode.fromJson(Map<String, dynamic> json) =>
      _$GraphNodeFromJson(json);
}

/// 知识图谱树节点（用于树形结构展示）
@freezed
class TreeNode with _$TreeNode {
  const factory TreeNode({
    /// 节点 ID
    required String id,

    /// 节点名称
    required String name,

    /// 节点类型
    required EntityType type,

    /// 子节点列表
    required List<TreeNode> children,

    /// 是否展开
    required bool isExpanded,

    /// 层级深度
    required int depth,
  }) = _TreeNode;

  factory TreeNode.fromJson(Map<String, dynamic> json) =>
      _$TreeNodeFromJson(json);
}

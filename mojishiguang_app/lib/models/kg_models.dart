/// 墨迹时光 - 知识图谱数据模型
///
/// 定义知识图谱模块所需的全部数据类，包括实体、关系、图谱、时间线等。
/// 集成技术：TransE, TransR, RotatE, R-GCN, GAT 等知识图谱嵌入与图神经网络理论。

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'kg_models.freezed.dart';
part 'kg_models.g.dart';

// ═══════════════════════════════════════════════════════════════
//  枚举定义
// ═══════════════════════════════════════════════════════════════

/// 实体类型枚举
///
/// 基于知识图谱实体识别（NER）任务中的常见分类体系，
/// 结合古籍文献特有的实体类型进行扩展。
enum EntityType {
  /// 人物
  person,

  /// 地名
  location,

  /// 官职/爵位
  official,

  /// 朝代/年号
  dynasty,

  /// 书名/碑帖名
  document,

  /// 事件
  event,

  /// 机构
  organization,

  /// 器物
  artifact,

  /// 其他
  other,
}

/// 关系类型枚举
enum RelationType {
  /// 师从/学于
  taughtBy,

  /// 友人
  friendOf,

  /// 父子/亲属
  parentOf,

  /// 任职/担任
  servedAs,

  /// 生于/卒于
  bornIn,

  /// 创作/书写
  created,

  /// 收藏于
  collectedIn,

  /// 提及/引用
  referenced,

  /// 位于
  locatedIn,

  /// 参与
  participatedIn,

  /// 其他
  other,
}

/// 外部知识库枚举
enum ExternalKb {
  /// Wikidata - 通用知识库
  wikidata,

  /// 中国哲学书电子化计划
  ctext,

  /// 中国历代人物传记资料库
  cbdb,

  /// 维基百科
  wikipedia,

  /// 百度百科
  baiduBaike,
}

/// 知识图谱视图模式
enum KgViewMode {
  /// 力导向图可视化
  graph,

  /// 时间线视图
  timeline,

  /// 列表视图
  list,
}

// ═══════════════════════════════════════════════════════════════
//  核心数据模型
// ═══════════════════════════════════════════════════════════════

/// 实体节点
///
/// 表示知识图谱中的一个独立实体，可以是人物、地名、官职等。
/// 每个实体有唯一 ID、名称、类型、描述及关联的元数据。
@freezed
class Entity with _$Entity {
  const factory Entity({
    /// 实体唯一标识符
    required String id,

    /// 实体名称
    required String name,

    /// 实体类型
    required EntityType type,

    /// 实体简介描述
    @Default('') String description,

    /// 别名列表（字号、别称等）
    @Default([]) List<String> aliases,

    /// 置信度得分 (0.0 ~ 1.0)
    @Default(1.0) double confidence,

    /// 关联的碑帖/古籍列表
    @Default([]) List<String> relatedDocuments,

    /// 外部知识库引用列表
    @Default([]) List<ExternalReference> externalRefs,

    /// 时间信息（生卒年、时期等）
    @Default('') String timeInfo,

    /// 嵌入向量（用于相似度计算）
    @Default([]) List<double> embedding,

    /// 附加元数据
    @Default({}) Map<String, String> metadata,
  }) = _Entity;

  factory Entity.fromJson(Map<String, dynamic> json) =>
      _$EntityFromJson(json);
}

/// 关系边
///
/// 连接两个实体的关系，包含关系类型、置信度和时间属性。
/// 支持带时间约束的时序关系（如 TGN、RE-NET 中的时间感知边）。
@freezed
class Relation with _$Relation {
  const factory Relation({
    /// 关系唯一标识符
    required String id,

    /// 头实体 ID
    required String headId,

    /// 尾实体 ID
    required String tailId,

    /// 关系类型
    required RelationType type,

    /// 关系名称（中文描述）
    required String name,

    /// 关系描述
    @Default('') String description,

    /// 置信度得分 (0.0 ~ 1.0)
    @Default(1.0) double confidence,

    /// 时间标注（如"公元105年"）
    @Default('') String timeLabel,

    /// 来源文献
    @Default('') String source,

    /// 关系权重（用于力导向布局）
    @Default(1.0) double weight,
  }) = _Relation;

  factory Relation.fromJson(Map<String, dynamic> json) =>
      _$RelationFromJson(json);
}

/// 知识图谱
///
/// 包含所有实体节点和关系边的完整图谱数据结构。
/// 支持子图裁剪、统计信息和元数据。
@freezed
class KnowledgeGraph with _$KnowledgeGraph {
  const factory KnowledgeGraph({
    /// 图谱唯一标识
    required String id,

    /// 图谱名称
    required String name,

    /// 实体列表
    required List<Entity> entities,

    /// 关系列表
    required List<Relation> relations,

    /// 中心实体 ID（当前聚焦点）
    @Default('') String centerEntityId,

    /// 当前展开深度
    @Default(0) int currentDepth,

    /// 最大深度
    @Default(6) int maxDepth,

    /// 统计信息
    @Default(KgStats()) KgStats stats,

    /// 是否还有更多节点可展开
    @Default(false) bool hasMore,
  }) = _KnowledgeGraph;

  factory KnowledgeGraph.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeGraphFromJson(json);
}

/// 图谱统计信息
@freezed
class KgStats with _$KgStats {
  const factory KgStats({
    /// 实体总数
    @Default(0) int entityCount,

    /// 关系总数
    @Default(0) int relationCount,

    /// 各类型实体统计
    @Default({}) Map<EntityType, int> entityTypeDistribution,

    /// 各类型关系统计
    @Default({}) Map<RelationType, int> relationTypeDistribution,

    /// 最大深度
    @Default(0) int maxDepth,

    /// 连通分量数
    @Default(0) int componentCount,
  }) = _KgStats;

  factory KgStats.fromJson(Map<String, dynamic> json) =>
      _$KgStatsFromJson(json);
}

/// 外部知识库引用
@freezed
class ExternalReference with _$ExternalReference {
  const factory ExternalReference({
    /// 来源知识库
    required ExternalKb source,

    /// 外部实体 ID
    required String externalId,

    /// 外部实体名称
    @Default('') String name,

    /// 外部链接 URL
    @Default('') String url,

    /// 简要描述
    @Default('') String description,
  }) = _ExternalReference;

  factory ExternalReference.fromJson(Map<String, dynamic> json) =>
      _$ExternalReferenceFromJson(json);
}

/// 时间线事件
///
/// 表示时间线上的一个时间点事件，关联实体和关系。
@freezed
class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    /// 事件唯一标识
    required String id,

    /// 事件标题
    required String title,

    /// 事件描述
    @Default('') String description,

    /// 时间标签
    required String timeLabel,

    /// 公元年份（用于排序）
    required int year,

    /// 关联的实体 ID 列表
    @Default([]) List<String> entityIds,

    /// 事件类型
    @Default('') String eventType,

    /// 重要性 (0.0 ~ 1.0)
    @Default(0.5) double importance,

    /// 来源碑帖/文献
    @Default('') String source,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
}

/// 时间线
@freezed
class Timeline with _$Timeline {
  const factory Timeline({
    /// 时间线唯一标识
    required String id,

    /// 时间线标题
    @Default('') String title,

    /// 事件列表（按时间排序）
    required List<TimelineEvent> events,

    /// 起始年份
    required int startYear,

    /// 结束年份
    required int endYear,

    /// 关联的实体 ID 列表
    @Default([]) List<String> entityIds,

    /// 时间跨度（年代段）
    @Default('') String period,
  }) = _Timeline;

  factory Timeline.fromJson(Map<String, dynamic> json) =>
      _$TimelineFromJson(json);
}

/// 实体详情（聚合信息）
@freezed
class EntityDetail with _$EntityDetail {
  const factory EntityDetail({
    /// 实体基础信息
    required Entity entity,

    /// 直接关联的实体
    @Default([]) List<Entity> relatedEntities,

    /// 直接关联的关系
    @Default([]) List<Relation> relations,

    /// 时间线位置
    @Default([]) List<TimelineEvent> timelineEvents,

    /// 相关碑帖列表
    @Default([]) List<String> relatedDocuments,

    /// 外部知识库引用
    @Default([]) List<ExternalReference> externalRefs,

    /// 关联深度（从中心节点出发的层数）
    @Default(0) int depth,

    /// 度（连接的边数）
    @Default(0) int degree,

    /// 是否有更多关联可加载
    @Default(false) bool hasMore,
  }) = _EntityDetail;

  factory EntityDetail.fromJson(Map<String, dynamic> json) =>
      _$EntityDetailFromJson(json);
}

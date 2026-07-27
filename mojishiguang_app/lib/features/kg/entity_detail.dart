/// 墨迹时光 - 实体详情面板
///
/// 知���图谱实体详情侧边面板，展示实体的完整信息。
/// 包含��实体名称+类型标签、关联实体列表、时间线位置、
/// 相关碑帖列表、外部知识库链接等。
///
/// 集成技术：TransE, TransR, R-GCN, ERNIE, KG-BERT
/// 信息聚合参考：Wikidata 实体页面、中国哲学书电子化计划

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/kg_models.dart';

/// 实体详情面板
///
/// 展示单个实体的聚合信息，支持关联实体点击跳转。
/// 面板宽度建议 320px，支持响应式收起/展开。
class EntityDetailPanel extends StatelessWidget {
  /// 实体详细信息
  final EntityDetail detail;

  /// 关联实体点击回调
  final Function(String entityId)? onEntityTap;

  /// 关闭面板回调
  final VoidCallback? onClose;

  const EntityDetailPanel({
    super.key,
    required this.detail,
    this.onEntityTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final entity = detail.entity;

    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      child: Container(
        width: 320,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 面板头部 ──
            _buildHeader(context, entity),

            // ── 基本信息 ──
            _buildBasicInfo(entity),

            // ── 滚动内容区 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 关联实体
                    if (detail.relatedEntities.isNotEmpty) ...[
                      _buildSectionTitle(
                        '关联实体 (${detail.relatedEntities.length})',
                      ),
                      ...detail.relatedEntities.take(10).map(
                            (e) => _RelatedEntityTile(
                              entity: e,
                              onTap: () => onEntityTap?.call(e.id),
                            ),
                          ),
                      if (detail.relatedEntities.length > 10)
                        _buildLoadMoreButton(),
                      const SizedBox(height: 16),
                    ],

                    // 时间线事件
                    if (detail.timelineEvents.isNotEmpty) ...[
                      _buildSectionTitle(
                        '时间线事件 (${detail.timelineEvents.length})',
                      ),
                      ...detail.timelineEvents
                          .take(5)
                          .map((e) => _TimelineTile(event: e)),
                      if (detail.timelineEvents.length > 5)
                        _buildMoreButton('查看全部时间线事件'),
                      const SizedBox(height: 16),
                    ],

                    // 相关碑帖
                    if (detail.relatedDocuments.isNotEmpty) ...[
                      _buildSectionTitle(
                        '相关碑帖 (${detail.relatedDocuments.length})',
                      ),
                      ...detail.relatedDocuments
                          .take(5)
                          .map((doc) => _DocumentTile(document: doc)),
                      if (detail.relatedDocuments.length > 5)
                        _buildMoreButton('查看全部碑帖'),
                      const SizedBox(height: 16),
                    ],

                    // 外部知识库链接
                    if (detail.externalRefs.isNotEmpty) ...[
                      _buildSectionTitle('外部链接'),
                      ...detail.externalRefs.map(
                        (ref) => _ExternalRefTile(reference: ref),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 图谱统计信息
                    _buildSectionTitle('图谱信息'),
                    _buildInfoRow('连接度数', '${detail.degree}'),
                    _buildInfoRow('关联深度', '${detail.depth}'),
                    _buildInfoRow(
                      '置信度',
                      '${(entity.confidence * 100).toStringAsFixed(1)}%',
                    ),

                    // 当前接口暂不支持分页加载，明确禁用入口，避免误导用户。
                    if (detail.hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.expand_more),
                            label: const Text('加载更多关联（暂未开放）'),
                            onPressed: null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 面板头部 ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Entity entity) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 实体名称
                Text(
                  entity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SourceHanSerifSC',
                  ),
                ),
                const SizedBox(height: 4),
                // 类型标签
                Row(
                  children: [
                    _buildTypeTag(entity.type),
                    const SizedBox(width: 8),
                    if (entity.aliases.isNotEmpty)
                      Expanded(
                        child: Text(
                          '别名: ${entity.aliases.join("、")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 关闭按钮
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeTag(EntityType type) {
    final label = _typeLabel(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _typeColor(type).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: _typeColor(type),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── 基本信息 ─────────────────────────────────────────────

  Widget _buildBasicInfo(Entity entity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entity.description.isNotEmpty)
            Text(
              entity.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          if (entity.timeInfo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  entity.timeInfo,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 区块标题 ─────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.inkBlack,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Tooltip(
        message: '加载更多功能暂未开放',
        child: TextButton(
          onPressed: null,
          child: const Text(
            '加载更多关联实体（暂未开放）',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Tooltip(
        message: '$text功能暂未开放',
        child: TextButton(
          onPressed: null,
          child: Text('$text（暂未开放）', style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  // ── 工具方法 ────────────────────────────────────────────

  String _typeLabel(EntityType type) {
    switch (type) {
      case EntityType.person:
        return '人物';
      case EntityType.location:
        return '地名';
      case EntityType.official:
        return '官职';
      case EntityType.dynasty:
        return '朝代';
      case EntityType.document:
        return '文献';
      case EntityType.event:
        return '事件';
      case EntityType.organization:
        return '机构';
      case EntityType.artifact:
        return '器物';
      case EntityType.other:
        return '其他';
    }
  }

  Color _typeColor(EntityType type) {
    switch (type) {
      case EntityType.person:
        return const Color(0xFFE74C3C);
      case EntityType.location:
        return const Color(0xFF2ECC71);
      case EntityType.official:
        return const Color(0xFFF39C12);
      case EntityType.dynasty:
        return const Color(0xFF9B59B6);
      case EntityType.document:
        return const Color(0xFF3498DB);
      case EntityType.event:
        return const Color(0xFF1ABC9C);
      case EntityType.organization:
        return const Color(0xFFE67E22);
      case EntityType.artifact:
        return const Color(0xFFE91E63);
      case EntityType.other:
        return const Color(0xFF95A5A6);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  子组件
// ═══════════════════════════════════════════════════════════════

/// 关联实体磁贴
class _RelatedEntityTile extends StatelessWidget {
  final Entity entity;
  final VoidCallback? onTap;

  const _RelatedEntityTile({required this.entity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _entityColor(entity.type),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entity.description.isNotEmpty)
                    Text(
                      entity.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _entityColor(EntityType type) {
    switch (type) {
      case EntityType.person:
        return const Color(0xFFE74C3C);
      case EntityType.location:
        return const Color(0xFF2ECC71);
      case EntityType.official:
        return const Color(0xFFF39C12);
      case EntityType.dynasty:
        return const Color(0xFF9B59B6);
      case EntityType.document:
        return const Color(0xFF3498DB);
      case EntityType.event:
        return const Color(0xFF1ABC9C);
      case EntityType.organization:
        return const Color(0xFFE67E22);
      case EntityType.artifact:
        return const Color(0xFFE91E63);
      case EntityType.other:
        return const Color(0xFF95A5A6);
    }
  }
}

/// 时间线事件磁贴
class _TimelineTile extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.vermilion.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.timeLabel,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.vermilion,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 13)),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 相关碑帖磁贴
class _DocumentTile extends StatelessWidget {
  final String document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: '碑帖详情暂未开放',
        child: Row(
          children: [
            const Icon(Icons.auto_stories, size: 16, color: Color(0xFF3498DB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(document, style: const TextStyle(fontSize: 13)),
            ),
            const Text(
              '暂未开放',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 外部知识库引用磁贴
class _ExternalRefTile extends StatelessWidget {
  final ExternalReference reference;

  const _ExternalRefTile({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.link_off, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference.name.isNotEmpty
                      ? reference.name
                      : reference.externalId,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Text(
                  '${_kbLabel(reference.source)} · 外部跳转暂未开放',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _kbLabel(ExternalKb kb) {
    switch (kb) {
      case ExternalKb.wikidata:
        return 'Wikidata';
      case ExternalKb.ctext:
        return '中国哲学书电子化计划';
      case ExternalKb.cbdb:
        return '中国历代人物传记资料库';
      case ExternalKb.wikipedia:
        return '维基百科';
      case ExternalKb.baiduBaike:
        return '百度百科';
    }
  }
}

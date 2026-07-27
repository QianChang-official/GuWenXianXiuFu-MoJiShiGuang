/// 墨迹时光 - 实体详情页
///
/// 展示知识图谱中单个实体的详细信息，包括基本信息、关联实体、
/// 时间线事件、外部知识库链接等。
///
/// 集成技术：TransE, TransR, R-GCN 知识图谱嵌入理论

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/kg_models.dart';
import '../../../providers/kg_provider.dart';

/// 实体详情页
///
/// 展示实体名称、类型、描述、关联实体列表、时间线事件、外部链接。
class EntityDetailScreen extends ConsumerWidget {
  const EntityDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(kgProvider);

    // 从 provider 中获取实体详情
    final detail = state.entityDetail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('实体详情')),
        body: const Center(child: Text('未选择实体')),
      );
    }

    final entity = detail.entity;

    return Scaffold(
      appBar: AppBar(
        title: Text(entity.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: '展开关联',
            onPressed: () {
              ref.read(kgProvider.notifier).expandEntity(entity);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 基本信息 ─────────────────────────────────────
            _buildBasicInfo(theme, entity),

            const SizedBox(height: 16),

            // ─── 关联实体列表 ────────────────────────────────
            if (detail.relatedEntities.isNotEmpty) ...[
              _buildSectionTitle(
                theme,
                '关联实体 (${detail.relatedEntities.length})',
              ),
              const SizedBox(height: 8),
              ...detail.relatedEntities.take(10).map(
                    (relatedEntity) => _RelatedEntityTile(
                      entity: relatedEntity,
                      onTap: () {
                        ref
                            .read(kgProvider.notifier)
                            .expandEntity(relatedEntity);
                      },
                    ),
                  ),
              if (detail.relatedEntities.length > 10)
                Center(
                  child: const TextButton(
                    onPressed: null,
                    child: Text('更多关联实体暂未开放'),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // ─── 时间线事件 ──────────────────────────────────
            if (detail.timelineEvents.isNotEmpty) ...[
              _buildSectionTitle(
                theme,
                '时间线事件 (${detail.timelineEvents.length})',
              ),
              const SizedBox(height: 8),
              ...detail.timelineEvents
                  .take(5)
                  .map((event) => _TimelineEventTile(event: event)),
              if (detail.timelineEvents.length > 5)
                Center(
                  child: const TextButton(
                    onPressed: null,
                    child: Text('完整时间线暂未开放'),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // ─── 相关碑帖 ────────────────────────────────────
            if (detail.relatedDocuments.isNotEmpty) ...[
              _buildSectionTitle(
                theme,
                '相关碑帖 (${detail.relatedDocuments.length})',
              ),
              const SizedBox(height: 8),
              ...detail.relatedDocuments
                  .take(5)
                  .map((doc) => _RelatedDocumentTile(document: doc)),
              const SizedBox(height: 16),
            ],

            // ─── 外部知识库链接 ──────────────────────────────
            if (detail.externalRefs.isNotEmpty) ...[
              _buildSectionTitle(theme, '外部链接'),
              const SizedBox(height: 8),
              ...detail.externalRefs.map(
                (ref) => _ExternalRefTile(reference: ref),
              ),
              const SizedBox(height: 16),
            ],

            // ─── 图谱信息 ────────────────────────────────────
            _buildSectionTitle(theme, '图谱信息'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('连接度数', '${detail.degree}'),
                    const Divider(height: 16),
                    _infoRow('关联深度', '${detail.depth}'),
                    const Divider(height: 16),
                    _infoRow(
                      '置信度',
                      '${(entity.confidence * 100).toStringAsFixed(1)}%',
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

  /// 基本信息区域
  Widget _buildBasicInfo(ThemeData theme, Entity entity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 实体名称
            Text(
              entity.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'SourceHanSerifSC',
              ),
            ),
            const SizedBox(height: 8),
            // 类型标签
            Row(
              children: [
                _buildTypeTag(theme, entity.type),
                const SizedBox(width: 8),
                if (entity.aliases.isNotEmpty)
                  Expanded(
                    child: Text(
                      '别名: ${entity.aliases.join("、")}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            // 描述
            if (entity.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entity.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
            // 时间信息
            if (entity.timeInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entity.timeInfo,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 类型标签
  Widget _buildTypeTag(ThemeData theme, EntityType type) {
    final color = _entityTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _entityTypeLabel(type),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.inkBlack,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _entityTypeLabel(EntityType type) {
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

  Color _entityTypeColor(EntityType type) {
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

/// 关联实体磁贴
class _RelatedEntityTile extends StatelessWidget {
  final Entity entity;
  final VoidCallback? onTap;

  const _RelatedEntityTile({required this.entity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _entityTypeColor(entity.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(
          entity.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: entity.description.isNotEmpty
            ? Text(
                entity.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _entityTypeColor(EntityType type) {
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
class _TimelineEventTile extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  style: const TextStyle(
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
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 相关碑帖磁贴
class _RelatedDocumentTile extends StatelessWidget {
  final String document;

  const _RelatedDocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.auto_stories,
          size: 18,
          color: Color(0xFF3498DB),
        ),
        title: Text(document, style: const TextStyle(fontSize: 13)),
        trailing: const Tooltip(
          message: '碑帖详情暂未开放',
          child: Icon(Icons.lock_outline, size: 16),
        ),
        onTap: null,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.open_in_new,
          size: 18,
          color: AppTheme.vermilion.withOpacity(0.7),
        ),
        title: Text(
          reference.name.isNotEmpty ? reference.name : reference.externalId,
          style: const TextStyle(fontSize: 13, color: AppTheme.vermilion),
        ),
        subtitle: Text(
          '${_kbLabel(reference.source)} · 外部链接打开暂未开放',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.lock_outline, size: 16),
        onTap: null,
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

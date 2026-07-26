/// 墨迹时光 - 知识图谱首页
///
/// 提供古籍知识图谱的搜索、可视化浏览与分析功能。
/// 支持图谱/时间线/列表三种视图模式，实体类型过滤，深度展开与统计展示。
///
/// 集成论文技术：
/// - 力导向布局 (Fruchterman-Reingold 算法)
/// - TransE/RotatE (知识图谱嵌入)
/// - GAT/GATv2 (图注意力机制)
/// - R-GCN (关系图卷积网络)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/kg_models.dart';
import '../../../providers/kg_provider.dart';
import '../../kg/entity_detail.dart';
import '../../kg/graph_canvas.dart';

/// 知识图谱首页
///
/// 包含：搜索栏（带历史）、视图模式切换（图谱/时间线/列表）、
/// 实体类型过滤芯片、统计信息条、三种视图内容、错误/空/加载态。
class KgScreen extends ConsumerStatefulWidget {
  const KgScreen({super.key});

  @override
  ConsumerState<KgScreen> createState() => _KgScreenState();
}

class _KgScreenState extends ConsumerState<KgScreen> {
  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  /// 是否显示搜索历史下拉
  bool _showHistory = false;

  /// 节点位置映射（实体 ID → 画布坐标）
  final Map<String, Offset> _nodePositions = {};

  /// 视图模式固定宽度
  static const double _detailPanelWidth = 320;

  @override
  void initState() {
    super.initState();
    // 初始化节点位置
    _initNodePositions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 初始化节点位置（随机分布）
  void _initNodePositions() {
    final state = ref.read(kgProvider);
    if (state.graph != null) {
      for (final entity in state.graph!.entities) {
        _nodePositions[entity.id] = Offset(
          (entity.id.hashCode % 400 - 200).toDouble(),
          (entity.id.hashCode % 300 - 150).toDouble(),
        );
      }
    }
  }

  /// 执行搜索
  void _doSearch(String query) {
    if (query.trim().isEmpty) return;
    ref.read(kgProvider.notifier).searchGraph(query);
    setState(() => _showHistory = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(kgProvider);
    final notifier = ref.read(kgProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识图谱'),
        actions: [
          // 统计信息按钮
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '图谱统计',
            onPressed: () => _showStatsDialog(context, state),
          ),
          // 展开深度按钮
          if (state.graph != null)
            IconButton(
              icon: const Icon(Icons.open_in_full),
              tooltip: '展开深度 (当前: ${state.currentDepth})',
              onPressed: () => notifier.expandDepth(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── 搜索栏（带历史） ───────────────────────────────
          _buildSearchBar(theme, state, notifier),

          // ─── 视图模式和过滤工具栏 ──────────────────────────
          _buildToolbar(theme, state, notifier),

          // ─── 统计信息条 ────────────────────────────────────
          if (state.graph != null)
            _buildStatsBar(theme, state),

          // ─── 主内容区 ──────────────────────────────────────
          Expanded(
            child: _buildContent(theme, state, notifier),
          ),
        ],
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar(
      ThemeData theme, KgState state, KgNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索人物、地名、官职、朝代...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && state.searchHistory.isNotEmpty) {
                setState(() => _showHistory = true);
              } else {
                setState(() => _showHistory = false);
              }
            },
            onSubmitted: (value) => _doSearch(value),
          ),
          // 搜索历史下拉
          if (_showHistory && state.searchHistory.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      '搜索历史',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...state.searchHistory.take(5).map((query) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(query, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        _searchController.text = query;
                        _doSearch(query);
                      },
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 工具栏：视图模式切换 + 实体类型过滤
  Widget _buildToolbar(ThemeData theme, KgState state, KgNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视图模式切换
          Row(
            children: [
              ToggleButtons(
                isSelected: [
                  state.viewMode == KgViewMode.graph,
                  state.viewMode == KgViewMode.timeline,
                  state.viewMode == KgViewMode.list,
                ],
                borderRadius: BorderRadius.circular(8),
                constraints:
                    const BoxConstraints(minWidth: 64, minHeight: 32),
                onPressed: (index) {
                  notifier.setViewMode(KgViewMode.values[index]);
                },
                children: const [
                  Tooltip(message: '图谱视图', child: Icon(Icons.hub, size: 18)),
                  Tooltip(
                      message: '时间线视图',
                      child: Icon(Icons.timeline, size: 18)),
                  Tooltip(
                      message: '列表视图', child: Icon(Icons.list, size: 18)),
                ],
              ),
              const Spacer(),
              // 清除筛选
              if (state.activeFilters.isNotEmpty)
                TextButton(
                  onPressed: () => notifier.clearFilters(),
                  child:
                      const Text('清除筛选', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 实体类型过滤芯片
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EntityType.values.map((type) {
                final isActive = state.activeFilters.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_entityTypeLabel(type),
                        style: const TextStyle(fontSize: 11)),
                    selected: isActive,
                    selectedColor:
                        _entityTypeColor(type).withValues(alpha: 0.2),
                    checkmarkColor: _entityTypeColor(type),
                    onSelected: (_) => notifier.toggleFilter(type),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 统计信息条
  Widget _buildStatsBar(ThemeData theme, KgState state) {
    final graph = state.graph;
    if (graph == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _statItem(theme, Icons.circle, '${graph.entities.length}', '实体'),
          const SizedBox(width: 16),
          _statItem(
              theme, Icons.arrow_right_alt, '${graph.relations.length}', '关系'),
          const SizedBox(width: 16),
          _statItem(theme, Icons.hierarchy, '深度 ${state.currentDepth}',
              '当前深度'),
          const Spacer(),
          // 加载/错误状态
          if (state.isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _statItem(
      ThemeData theme, IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.vermilion),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 主内容区 — 根据视图模式切换
  Widget _buildContent(
      ThemeData theme, KgState state, KgNotifier notifier) {
    // 空状态
    if (state.graph == null && !state.isProcessing && state.errorMessage == null) {
      return _buildEmptyState(theme);
    }

    // 加载中
    if (state.isProcessing && state.graph == null) {
      return _buildLoadingState(theme);
    }

    // 错误状态
    if (state.errorMessage != null && state.graph == null) {
      return _buildErrorState(theme, state, notifier);
    }

    // 根据视图模式切换
    switch (state.viewMode) {
      case KgViewMode.graph:
        return _buildGraphView(theme, state, notifier);
      case KgViewMode.timeline:
        return _buildTimelineView(theme, state);
      case KgViewMode.list:
        return _buildListView(theme, state, notifier);
    }
  }

  /// 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('搜索古籍人物、地名、官职...',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('输入关键词探索知识图谱',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  /// 加载中
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: 16),
          const Text('正在构建知识图谱...'),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(
      ThemeData theme, KgState state, KgNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? '图谱构建失败',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            onPressed: () {
              if (state.searchQuery.isNotEmpty) {
                notifier.searchGraph(state.searchQuery);
              }
            },
          ),
        ],
      ),
    );
  }

  /// 图谱画布模式
  Widget _buildGraphView(
      ThemeData theme, KgState state, KgNotifier notifier) {
    final graph = state.graph;
    if (graph == null) return const SizedBox.shrink();

    // 应用筛选
    final filteredEntities = state.activeFilters.isNotEmpty
        ? graph.entities
            .where((e) => state.activeFilters.contains(e.type))
            .toList()
        : graph.entities;

    // 筛选后的关系
    final filteredEntityIds = filteredEntities.map((e) => e.id).toSet();
    final filteredRelations = graph.relations
        .where((r) =>
            filteredEntityIds.contains(r.headId) &&
            filteredEntityIds.contains(r.tailId))
        .toList();

    final filteredGraph = KnowledgeGraph(
      id: graph.id,
      name: graph.name,
      entities: filteredEntities,
      relations: filteredRelations,
    );

    return Row(
      children: [
        // 图谱画布
        Expanded(
          child: GraphCanvas(
            graph: filteredGraph,
            nodePositions: _nodePositions,
            selectedEntityId: state.selectedEntity?.id,
            onNodeTap: (entityId) {
              final entity = graph.entities.firstWhere(
                (e) => e.id == entityId,
                orElse: () => graph.entities.first,
              );
              notifier.expandEntity(entity);
            },
            onNodeDoubleTap: (entityId) {
              context.push('/kg/entity');
            },
            onNodeDrag: (entityId, position) {
              setState(() {
                _nodePositions[entityId] = position;
              });
            },
          ),
        ),
        // 右侧实体详情面板
        if (state.entityDetail != null)
          SizedBox(
            width: _detailPanelWidth,
            child: EntityDetailPanel(
              detail: state.entityDetail!,
              onEntityTap: (entityId) {
                final entity = graph.entities.firstWhere(
                  (e) => e.id == entityId,
                  orElse: () => graph.entities.first,
                );
                notifier.expandEntity(entity);
              },
              onClose: () => notifier.clearSelection(),
            ),
          ),
      ],
    );
  }

  /// 时间线视图
  Widget _buildTimelineView(ThemeData theme, KgState state) {
    final timeline = state.timeline;
    if (timeline == null || timeline.events.isEmpty) {
      return const Center(child: Text('暂无时间线数据'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeline.events.length,
      itemBuilder: (context, index) {
        final event = timeline.events[index];
        return _TimelineEventCard(event: event, isLast: index == timeline.events.length - 1);
      },
    );
  }

  /// 列表视图
  Widget _buildListView(
      ThemeData theme, KgState state, KgNotifier notifier) {
    final graph = state.graph;
    if (graph == null) return const SizedBox.shrink();

    // 应用筛选
    final entities = state.activeFilters.isNotEmpty
        ? graph.entities
            .where((e) => state.activeFilters.contains(e.type))
            .toList()
        : graph.entities;

    final entityIds = entities.map((e) => e.id).toSet();
    final relations = graph.relations
        .where((r) =>
            entityIds.contains(r.headId) && entityIds.contains(r.tailId))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 实体列表
        Text(
          '实体 (${entities.length})',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...entities.map((entity) => ListTile(
              dense: true,
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _entityTypeColor(entity.type),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(entity.name,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                _entityTypeLabel(entity.type),
                style: TextStyle(
                    fontSize: 12,
                    color: _entityTypeColor(entity.type)),
              ),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => notifier.expandEntity(entity),
            )),
        const Divider(),
        const SizedBox(height: 8),
        // 关系列表
        Text(
          '关系 (${relations.length})',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...relations.map((relation) {
          final head = graph.entities.firstWhere(
            (e) => e.id == relation.headId,
            orElse: () => graph.entities.first,
          );
          final tail = graph.entities.firstWhere(
            (e) => e.id == relation.tailId,
            orElse: () => graph.entities.first,
          );
          return ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_right_alt, size: 18),
            title: Text(
              '${head.name} → ${tail.name}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(relation.name,
                style: const TextStyle(fontSize: 12)),
          );
        }),
      ],
    );
  }

  /// 弹窗展示图谱统计
  void _showStatsDialog(BuildContext context, KgState state) {
    final graph = state.graph;
    if (graph == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图谱统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('实体总数', '${graph.entities.length}'),
            _statRow('关系总数', '${graph.relations.length}'),
            _statRow('当前深度', '${state.currentDepth}'),
            const SizedBox(height: 12),
            const Text('实体类型分布',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            ...EntityType.values.map((type) {
              final count =
                  graph.entities.where((e) => e.type == type).length;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _entityTypeColor(type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_entityTypeLabel(type),
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 实体类型 → 中文名
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

  /// 实体类型 → 颜色
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

/// 时间线事件卡片
class _TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineEventCard({
    required this.event,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间轴
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.vermilion.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.timeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.vermilion,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 竖线
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.vermilion,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 6, color: Colors.white),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.vermilion.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 事件内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (event.source.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '来源: ${event.source}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
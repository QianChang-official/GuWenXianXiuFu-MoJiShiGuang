import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/kg_models.dart';
import '../services/api/kg_api.dart';

part 'kg_provider.freezed.dart';

/// 知识图谱完整状态
@freezed
class KgState with _$KgState {
  const factory KgState({
    required String searchQuery,
    required KnowledgeGraph? graph,
    required Entity? selectedEntity,
    required EntityDetail? entityDetail,
    required Timeline? timeline,
    required KgViewMode viewMode,
    required bool isProcessing,
    required double progress,
    required String? errorMessage,
    required int currentDepth,
    required Set<EntityType> activeFilters,
    required List<String> searchHistory,
  }) = _KgState;

  factory KgState.initial() => const KgState(
        searchQuery: '',
        graph: null,
        selectedEntity: null,
        entityDetail: null,
        timeline: null,
        viewMode: KgViewMode.graph,
        isProcessing: false,
        progress: 0.0,
        errorMessage: null,
        currentDepth: 2,
        activeFilters: <EntityType>{},
        searchHistory: [],
      );
}

class KgNotifier extends Notifier<KgState> {
  final KgApiService _apiService = KgApiService.instance;

  @override
  KgState build() => KgState.initial();

  /// 搜索并构建知识图谱
  Future<void> searchGraph(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      searchQuery: query,
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
    );

    try {
      // 1. 实体抽取
      final entities = await _apiService.extractEntities(query);
      state = state.copyWith(progress: 0.3);

      // 2. 关系抽取
      final relations = await _apiService.extractRelations(query, entities);
      state = state.copyWith(progress: 0.6);

      // 3. 构建知识图谱
      final graph = KnowledgeGraph(
        id: 'kg_${DateTime.now().millisecondsSinceEpoch}',
        name: query,
        entities: entities,
        relations: relations,
      );
      state = state.copyWith(graph: graph, progress: 0.8);

      // 4. 构建时间线
      final timeline = await _apiService.generateTimeline(entities);
      state = state.copyWith(
        timeline: timeline,
        progress: 1.0,
        isProcessing: false,
        searchHistory: [query, ...state.searchHistory].take(20).toList(),
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: '图谱构建失败: $e');
    }
  }

  /// 展开实体详情
  Future<void> expandEntity(Entity entity) async {
    state = state.copyWith(
      selectedEntity: entity,
      entityDetail: null,
      isProcessing: true,
      errorMessage: null,
    );
    try {
      final detail = await _apiService.getEntityDetail(entity.id);
      if (state.selectedEntity?.id != entity.id) return;
      state = state.copyWith(entityDetail: detail, isProcessing: false);
    } catch (e) {
      if (state.selectedEntity?.id != entity.id) return;
      state = state.copyWith(isProcessing: false, errorMessage: '实体详情获取失败: $e');
    }
  }

  /// 展开下一层关联实体
  Future<void> expandDepth() async {
    if (state.graph == null) return;
    final nextDepth = state.currentDepth + 1;
    state = state.copyWith(isProcessing: true, progress: 0.0);

    try {
      final expandedGraph = await _apiService.queryKnowledgeGraph(
        query: state.searchQuery,
        depth: nextDepth,
        entityFilter: state.activeFilters.isEmpty ? null : state.activeFilters,
      );
      state = state.copyWith(
        graph: expandedGraph,
        currentDepth: nextDepth,
        isProcessing: false,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: '展开失败: $e');
    }
  }

  void setViewMode(KgViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void toggleFilter(EntityType type) {
    final updated = Set<EntityType>.from(state.activeFilters);
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    state = state.copyWith(activeFilters: updated);
  }

  void clearFilters() {
    state = state.copyWith(activeFilters: <EntityType>{});
  }

  void selectEntity(Entity? entity) {
    state = state.copyWith(selectedEntity: entity);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedEntity: null,
      entityDetail: null,
      isProcessing: false,
    );
  }

  void reset() => state = KgState.initial();

  void clearError() => state = state.copyWith(errorMessage: null);
}

final kgProvider = NotifierProvider<KgNotifier, KgState>(KgNotifier.new);

/// 墨迹时光 - 知识图谱 API 服务
///
/// 提供知识图谱相关的全部后端接口调用，包括：
/// - 实体抽取（基于碑帖文字的人物/地名/官职识别）
/// - 关系抽取（实体间的语义关系）
/// - 知识图谱查询（按深度展开、类型过滤）
/// - 外部知识库关联（Wikidata / 中国哲学书等）
/// - 时间线生成
/// - 实体详情聚合
///
/// 集成论文技术：TransE, TransR, R-GCN, ERNIE, KG-BERT, RE-NET, TGN
///
/// 数据流向：
/// 碑帖文字 → OCR识别 → 实体/关系抽取 → 知识图谱构建 → 前端可视化
///
/// 依赖：Dio 网络库，freezed 数据模型

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../models/kg_models.dart';

/// 知识图谱 API 服务
///
/// 封装所有知识图谱后端的 HTTP 接口调用。
/// 采用单例模式通过 [KgApiService.instance] 访问。
/// 所有方法均为异步，返回结果已解析为强类型数据模型。
class KgApiService {
  /// 单例实例
  static KgApiService? _instance;
  static KgApiService get instance => _instance ??= KgApiService._internal();

  late final Dio _dio;

  /// 内部构造，初始化 Dio 实例
  KgApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// 测试用构造（可注入 mock Dio）
  KgApiService.test(this._dio);

  // ═══════════════════════════════════════════════════════════
  //  1. 实体抽取
  // ═══════════════════════════════════════════════════════════

  /// 从输入文本中抽取命名实体
  ///
  /// 利用 NER 模型从碑帖文字、古籍段落中识别人物、地名、官职、朝代等实体。
  /// [text] 是待识别的文本内容。
  /// [filter] 可选，指定只返回特定类型的实体。
  ///
  /// 底层技术：基于 ERNIE / KG-BERT 的序列标注模型，
  /// 结合古籍特有词典（如古代官职名、年号列表）提高召回率。
  ///
  /// 返回示例：
  /// ```dart
  /// [
  ///   Entity(id: 'e1', name: '王羲之', type: EntityType.person, ...),
  ///   Entity(id: 'e2', name: '会稽', type: EntityType.location, ...),
  /// ]
  /// ```
  Future<List<Entity>> extractEntities(
    String text, {
    EntityType? filter,
  }) async {
    try {
      final response = await _dio.post(
        '/kg/entities/extract',
        data: {
          'text': text,
          if (filter != null) 'filter': filter.name,
        },
      );
      final List<dynamic> data = response.data['entities'] ?? [];
      List<Entity> entities = data
          .map((json) => Entity.fromJson(json as Map<String, dynamic>))
          .toList();
      if (filter != null) {
        entities = entities.where((e) => e.type == filter).toList();
      }
      return entities;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  2. 关系抽取
  // ═══════════════════════════════════════════════════════════

  /// 从文本中抽取实体间的关系
  ///
  /// 基于已识别的实体列表，分析文本中实体间的语义关系。
  /// 支持的关系类型包括：师从、友人、父子、任职、创作、收藏等。
  ///
  /// 底层技术：基于 R-GCN / CompGCN 的联合抽取模型，
  /// 支持重叠关系和多实体关系的同时抽取。
  ///
  /// [text] 源文本
  /// [entities] 已识别的实体列表
  Future<List<Relation>> extractRelations(
    String text,
    List<Entity> entities,
  ) async {
    try {
      final response = await _dio.post(
        '/kg/relations/extract',
        data: {
          'text': text,
          'entities': entities.map((e) => e.toJson()).toList(),
        },
      );
      final List<dynamic> data = response.data['relations'] ?? [];
      return data
          .map((json) => Relation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  3. 知识图谱查询
  // ═══════════════════════════════════════════════════════════

  /// 查询知识图谱
  ///
  /// 以搜索词为中心展开知识图谱。支持：
  /// - [depth] 展开深度控制
  /// - [entityFilter] 实体类型过滤
  /// - [relationFilter] 关系类型过滤
  ///
  /// 底层技术：基于 TransE / RotatE 嵌入的语义搜索 +
  /// GAT/GATv2 邻居聚合的多跳展开策略。
  ///
  /// 返回包含实体节点和关系边的完整图谱结构。
  Future<KnowledgeGraph> queryKnowledgeGraph({
    required String query,
    int depth = 2,
    Set<EntityType>? entityFilter,
    Set<RelationType>? relationFilter,
  }) async {
    try {
      final response = await _dio.post(
        '/kg/query',
        data: {
          'query': query,
          'depth': depth.clamp(1, AppConstants.kgMaxDepth),
          if (entityFilter != null)
            'entity_filter': entityFilter.map((e) => e.name).toList(),
          if (relationFilter != null)
            'relation_filter': relationFilter.map((r) => r.name).toList(),
        },
      );
      return KnowledgeGraph.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  4. 外部知识库关联
  // ═══════════════════════════════════════════════════════════

  /// 查询外部知识库
  ///
  /// 将本地知识图谱的实体与外部知识库进行链接（Entity Linking）。
  /// 支持 Wikidata、中国哲学书电子化计划（ctext）、CBDB 等。
  ///
  /// [entityName] 实体名称
  /// [kb] 目标外部知识库
  ///
  /// 返回外部实体的引用信息，包括 ID、名称、URL 等。
  Future<List<ExternalReference>> queryExternalKb({
    required String entityName,
    ExternalKb kb = ExternalKb.wikidata,
  }) async {
    try {
      final response = await _dio.get(
        '/kg/external',
        queryParameters: {
          'entity': entityName,
          'kb': kb.name,
        },
      );
      final List<dynamic> data = response.data['references'] ?? [];
      return data
          .map((json) =>
              ExternalReference.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  5. 时间线生成
  // ═══════════════════════════════════════════════════════════

  /// 生成时间线
  ///
  /// 根据实体列表构建按时间排列的事件序列。
  /// 利用实体的时间属性（生卒年、在位时间等）和关系中的时间标注，
  /// 自动构建时间线。
  ///
  /// 底层技术：基于 RE-NET / TGN 的时间感知图模型，
  /// 支持事件排序、时间间隔计算和时间线分段。
  ///
  /// [entities] 待构建时间线的实体列表
  Future<Timeline> generateTimeline(List<Entity> entities) async {
    try {
      final response = await _dio.post(
        '/kg/timeline',
        data: {
          'entity_ids': entities.map((e) => e.id).toList(),
        },
      );
      return Timeline.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  6. 实体详情聚合
  // ═══════════════════════════════════════════════════════════

  /// 获取实体详情
  ///
  /// 聚合指定实体的全面信息，包括：
  /// - 基础属性（名称、类型、描述）
  /// - 关联实体（直接连接的邻居节点）
  /// - 关联关系（与其他实体的边）
  /// - 时间线位置（相关事件）
  /// - 相关碑帖列表
  /// - 外部知识库引用
  ///
  /// [entityId] 实体唯一标识符
  Future<EntityDetail> getEntityDetail(String entityId) async {
    try {
      final response = await _dio.get(
        '/kg/entity/$entityId',
      );
      return EntityDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  辅助方法
  // ═══════════════════════════════════════════════════════════

  /// 统一错误处理，将 DioException 转换为可读异常
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const KgApiException('请求超时，请检查网络连接');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? '服务器错误';
        return KgApiException(
          '请求失败 ($statusCode): $message',
        );
      case DioExceptionType.cancel:
        return const KgApiException('请求已取消');
      default:
        return const KgApiException('网络异常，请稍后重试');
    }
  }
}

/// 知识图谱 API 异常
///
/// 封装知识图谱接口调用中的错误信息。
class KgApiException implements Exception {
  final String message;
  const KgApiException(this.message);

  @override
  String toString() => 'KgApiException: $message';
}

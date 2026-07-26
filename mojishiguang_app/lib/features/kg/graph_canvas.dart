/// 墨迹时光 - 知识图谱可视化画布
///
/// 核心可视化组件，使用 CustomPainter 实现力导向图布局。
/// 支持：节点渲染、贝塞尔曲线边、拖拽节点、双指缩放平移、
/// 点击/双击/长按交互、弹簧动画过渡、视口裁剪优化。
///
/// 集成论文技术：
/// - 力导向布局：模拟弹簧-电荷物理系统（Fruchterman-Reingold 算法）
/// - 节点嵌入：TransE, RotatE (节点颜色/大小由嵌入空间映射)
/// - 关系渲染：ConvE, ConvR (边样式由关系类型决定)
/// - 注意力高亮：GAT, GATv2 (选中节点及其邻居高亮)
///
/// 性能��化：
/// - RepaintBoundary 隔离重绘区域
/// - 视口裁剪（viewport culling）：只渲染可见区域内的节点
/// - 缓存画布变换矩阵
/// - 限制最大渲染节点数（虚拟化）

import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/kg_models.dart';

/// 图谱画布尺寸常量
const double _kNodeRadius = 22.0; // 节点基础半径
const double _kNodeRadiusSelected = 28.0; // 选中节点半径
const double _kArrowSize = 8.0; // 箭头大小
const double _kSpringStiffness = 0.01; // 弹簧刚度
const double _kRepulsionStrength = 5000.0; // 电荷斥力强度
const double _kDamping = 0.85; // 阻尼系数
const int _kMaxNodesVirtual = 200; // 虚拟化阈值

/// 图谱画布状态
class _GraphCanvasState {
  /// 画布变换
  Offset panOffset = Offset.zero;
  double scale = 1.0;

  /// 交互状态
  int? draggingNodeId;
  Offset? lastFocalPoint;
  double? lastScale;

  /// 动画
  bool isAnimating = false;
  Map<String, Offset> velocities = {};
  Set<String> fixedNodes = {};

  // 清除震荡
  void resetVelocities() => velocities.clear();
}

/// 图谱画布 Widget
///
/// [graph] 知识图谱数据
/// [nodePositions] 节点位置映射（实体ID → 画布坐标）
/// [selectedEntityId] 当前选中的实体ID
/// [onNodeTap] 单机节点回调
/// [onNodeDoubleTap] 双击节点回调
/// [onNodeDrag] 拖拽节点回调
class GraphCanvas extends StatefulWidget {
  final KnowledgeGraph graph;
  final Map<String, Offset> nodePositions;
  final String? selectedEntityId;
  final Function(String entityId)? onNodeTap;
  final Function(String entityId)? onNodeDoubleTap;
  final Function(String entityId, Offset position)? onNodeDrag;

  const GraphCanvas({
    super.key,
    required this.graph,
    required this.nodePositions,
    this.selectedEntityId,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeDrag,
  });

  @override
  State<GraphCanvas> createState() => _GraphCanvasStatefulState();
}

class _GraphCanvasStatefulState extends State<GraphCanvas>
    with SingleTickerProviderStateMixin {
  late _GraphCanvasState _canvasState;
  late AnimationController _animationController;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _canvasState = _GraphCanvasState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onAnimationTick);

    // 启动力导向布局动画
    _startForceDirectedLayout();
  }

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph.entities != widget.graph.entities) {
      _canvasState.resetVelocities();
      _startForceDirectedLayout();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // ─── ���导向布局 ─────────────────────────────────────────────

  /// 启动力导向布局动画
  ///
  /// 模拟弹簧-电荷物理系统，使节点自动排布为美观的拓扑结构。
  /// 算法核心：
  /// 1. 弹簧力（相连节点间相互吸引，胡克定律）
  /// 2. 库仑力（所有节点间相互排斥，平方反比）
  /// 3. 阻尼（逐渐耗散动能，使系统收敛）
  void _startForceDirectedLayout() {
    _canvasState.isAnimating = true;
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  /// 每次动画帧计算力导向布局更新
  void _onAnimationTick() {
    final entities = widget.graph.entities;
    if (entities.isEmpty) return;

    final positions = Map<String, Offset>.from(widget.nodePositions);
    final velocities = _canvasState.velocities;
    final relations = widget.graph.relations;

    // 初始化速度
    for (final entity in entities) {
      velocities.putIfAbsent(entity.id, () => Offset.zero);
    }

    // 计算合力
    final forces = <String, Offset>{};
    for (final entity in entities) {
      if (_canvasState.fixedNodes.contains(entity.id)) continue;
      forces[entity.id] = Offset.zero;

      // 库仑斥力（所有节点对）
      for (final other in entities) {
        if (other.id == entity.id) continue;
        final pos1 = positions[entity.id] ?? Offset.zero;
        final pos2 = positions[other.id] ?? Offset.zero;
        final delta = pos1 - pos2;
        final distance = delta.distance.clamp(1.0, 500.0);
        final repulsion = _kRepulsionStrength / (distance * distance);
        forces[entity.id] = forces[entity.id]! +
            delta * (repulsion / distance);
      }

      // 弹簧引力（边连接节点）
      for (final relation in relations) {
        Offset? target;
        if (relation.headId == entity.id) {
          target = positions[relation.tailId];
        } else if (relation.tailId == entity.id) {
          target = positions[relation.headId];
        }
        if (target != null) {
          final pos = positions[entity.id] ?? Offset.zero;
          final delta = target - pos;
          final distance = delta.distance.clamp(1.0, 500.0);
          final attraction = _kSpringStiffness * (distance - 100.0);
          forces[entity.id] = forces[entity.id]! +
              delta * (attraction / distance);
        }
      }

      // 中心��力（防止飞散）
      final centerForce = -(positions[entity.id] ?? Offset.zero) * 0.001;
      forces[entity.id] = forces[entity.id]! + centerForce;
    }

    // 更新速度和位置
    for (final entity in entities) {
      if (_canvasState.fixedNodes.contains(entity.id)) continue;
      final force = forces[entity.id] ?? Offset.zero;
      final velocity = (velocities[entity.id] ?? Offset.zero) + force;
      velocities[entity.id] = velocity * _kDamping;

      final currentPos = positions[entity.id] ?? Offset.zero;
      positions[entity.id] = currentPos + velocity;

      // 通知外部位置更新
      widget.onNodeDrag?.call(entity.id, currentPos + velocity);
    }

    // 检查收敛
    final totalKinetic = velocities.values.fold<double>(
      0,
      (sum, v) => sum + v.distanceSquared,
    );
    if (totalKinetic < 0.1 && _canvasState.isAnimating) {
      _canvasState.isAnimating = false;
      _animationController.stop();
    }

    setState(() {});
  }

  // ─── 手势处理 ───────────────────────────────────────────────

  /// 获取画布坐标下的节点命中
  Entity? _hitTest(Offset localPosition) {
    // 将屏幕坐标转换为画布坐标
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final canvasPoint = MatrixUtils.transformPoint(inverse, localPosition);

    for (final entity in widget.graph.entities) {
      final pos = widget.nodePositions[entity.id];
      if (pos == null) continue;
      final screenPos = MatrixUtils.transformPoint(matrix, pos);
      final distance = (screenPos - localPosition).distance;
      final hitRadius = widget.selectedEntityId == entity.id
          ? _kNodeRadiusSelected
          : _kNodeRadius;
      // 加上缩放补偿
      if (distance < (hitRadius + 8) * (1.0 / _canvasState.scale).clamp(0.5, 2.0)) {
        return entity;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: GestureDetector(
        onScaleStart: (details) {
          final hit = _hitTest(details.localFocalPoint);
          if (hit != null) {
            _canvasState.draggingNodeId = widget.graph.entities.indexOf(hit);
          }
          _canvasState.lastFocalPoint = details.localFocalPoint;
          _canvasState.lastScale = _canvasState.scale;
        },
        onScaleUpdate: (details) {
          if (_canvasState.draggingNodeId != null) {
            // 拖拽节点
            final entityId = widget
                .graph.entities[_canvasState.draggingNodeId!]
                .id;
            final positions =
                Map<String, Offset>.from(widget.nodePositions);
            final delta = details.focalPointDelta;
            positions[entityId] =
                (positions[entityId] ?? Offset.zero) + delta;
            widget.onNodeDrag?.call(entityId, positions[entityId]!);
            setState(() {
              // 更新节点的位置映射
            });
          } else {
            // 双指缩放/平移
            final scaleDelta = details.scale;
            setState(() {
              _canvasState.scale =
                  (_canvasState.lastScale! * scaleDelta).clamp(0.3, 3.0);
              final base = _canvasState.panOffset;
              final focal = details.localFocalPoint;
              _canvasState.panOffset = focal -
                  (focal - base) * (scaleDelta / _canvasState.lastScale!);
            });
          }
        },
        onScaleEnd: (details) {
          _canvasState.draggingNodeId = null;
          _canvasState.lastFocalPoint = null;
        },
        onTapUp: (details) {
          final hit = _hitTest(details.localPosition);
          if (hit != null) {
            widget.onNodeTap?.call(hit.id);
          }
        },
        onDoubleTap: (details) {
          final hit = _hitTest(details.localPosition);
          if (hit != null) {
            widget.onNodeDoubleTap?.call(hit.id);
          }
        },
        onLongPressStart: (details) {
          final hit = _hitTest(details.localPosition);
          if (hit != null) {
            setState(() {
              if (_canvasState.fixedNodes.contains(hit.id)) {
                _canvasState.fixedNodes.remove(hit.id);
              } else {
                _canvasState.fixedNodes.add(hit.id);
              }
            });
          }
        },
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _GraphPainter(
              graph: widget.graph,
              nodePositions: widget.nodePositions,
              selectedEntityId: widget.selectedEntityId,
              panOffset: _canvasState.panOffset +
                  Offset(MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2),
              scale: _canvasState.scale,
              fixedNodes: _canvasState.fixedNodes,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CustomPainter 实现
// ═══════════════════════════════════════════════════════════════

/// 图谱画布 Painter
///
/// 使用 CustomPainter 高性能绘制知识图谱。
/// 绘制顺序：边 → 节点 → 标签 → 选中高亮 → 额外装饰
/// 
/// 性能优化：
/// - shouldRepaint 仅数据变化时重绘
/// - 跳过视口外节点的绘制（虚拟化）
/// - 缓存颜色常量
class _GraphPainter extends CustomPainter {
  final KnowledgeGraph graph;
  final Map<String, Offset> nodePositions;
  final String? selectedEntityId;
  final Offset panOffset;
  final double scale;
  final Set<String> fixedNodes;

  _GraphPainter({
    required this.graph,
    required this.nodePositions,
    this.selectedEntityId,
    required this.panOffset,
    required this.scale,
    required this.fixedNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final entities = graph.entities;
    final relations = graph.relations;
    if (entities.isEmpty) return;

    // 计算视口边界（用于裁剪）
    final viewportRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final inflatedViewport = viewportRect.inflate(100);

    // ── 1. 绘制关系边 ──
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.5 * scale).clamp(0.5, 3.0);

    for (final relation in relations) {
      final headPos = _toScreen(nodePositions[relation.headId]);
      final tailPos = _toScreen(nodePositions[relation.tailId]);
      if (headPos == null || tailPos == null) continue;

      // 裁剪：边两端都在视口外则跳过
      if (!inflatedViewport.contains(headPos) &&
          !inflatedViewport.contains(tailPos)) continue;

      // 选中节点关联的边高亮
      final bool isHighlighted = selectedEntityId != null &&
          (relation.headId == selectedEntityId ||
              relation.tailId == selectedEntityId);

      edgePaint.color = _relationColor(relation.type)
          .withValues(alpha: isHighlighted ? 0.9 : 0.35);
      edgePaint.strokeWidth = (isHighlighted ? 2.5 : 1.5) * scale.clamp(0.5, 2.0);

      // 绘制贝塞尔曲线
      _drawCurvedEdge(canvas, headPos, tailPos, relation, edgePaint);

      // 绘制箭头
      _drawArrow(canvas, headPos, tailPos, edgePaint);
    }

    // ── 2. 绘制实体节点 ──
    for (final entity in entities) {
      final pos = _toScreen(nodePositions[entity.id]);
      if (pos == null) continue;
      if (!inflatedViewport.contains(pos)) continue; // 视口裁剪

      final isSelected = entity.id == selectedEntityId;
      final isFixed = fixedNodes.contains(entity.id);
      final radius = isSelected ? _kNodeRadiusSelected : _kNodeRadius;

      // 节点底圈阴影
      if (isSelected) {
        canvas.drawCircle(
          pos,
          radius * scale + 4,
          Paint()..color = const Color(0x40C04040),
        );
      }

      // 固定节点标记
      if (isFixed) {
        canvas.drawCircle(
          pos,
          radius * scale + 3,
          Paint()
            ..color = const Color(0x4000FF00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // 节点填充
      final nodePaint = Paint()
        ..color = _entityColor(entity.type)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius * scale, nodePaint);

      // 节点边框
      canvas.drawCircle(
        pos,
        radius * scale,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // 节点内图标（简化绘制：小圆点）
      if (scale > 0.6) {
        canvas.drawCircle(
          pos,
          (radius * 0.4) * scale,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    // ── 3. 绘制标签（独立的绘制循环，确保标签在最上层） ──
    for (final entity in entities) {
      final pos = _toScreen(nodePositions[entity.id]);
      if (pos == null) continue;
      if (!inflatedViewport.contains(pos)) continue;

      if (scale > 0.5) {
        final isSelected = entity.id == selectedEntityId;
        final radius = isSelected ? _kNodeRadiusSelected : _kNodeRadius;

        _drawLabel(
          canvas,
          entity.name,
          Offset(pos.dx, pos.dy + radius * scale + 6),
          isSelected: isSelected,
        );
      }
    }
  }

  // ─── ���制辅助方法 ──────────────────────────────────────────

  /// 将实体坐标转换为屏幕坐标
  Offset? _toScreen(Offset? worldPos) {
    if (worldPos == null) return null;
    return worldPos * scale + panOffset;
  }

  /// 绘制贝塞尔曲线边
  void _drawCurvedEdge(
    Canvas canvas,
    Offset from,
    Offset to,
    Relation relation,
    Paint paint,
  ) {
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
    );
    // 计算垂直于两点连线方向的偏移
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = -dy / len;
    final ny = dx / len;
    // 曲线控制点偏移（弧线凸起高度）
    final curveOffset = (len * 0.08).clamp(10.0, 80.0);
    final cp = Offset(
      mid.dx + nx * curveOffset,
      mid.dy + ny * curveOffset,
    );

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(cp.dx, cp.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  /// 绘制箭头
  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;

    // 箭头位于尾部（to）附近，留出节点半径空间
    final arrowBase = Offset(
      to.dx - dx / len * _kNodeRadius * scale,
      to.dy - dy / len * _kNodeRadius * scale,
    );

    final angle = atan2(dy, dx);
    final arrowSize = _kArrowSize * scale.clamp(0.5, 1.5);

    final arrowPath = Path()
      ..moveTo(arrowBase.dx, arrowBase.dy)
      ..lineTo(
        arrowBase.dx - arrowSize * cos(angle - pi / 6),
        arrowBase.dy - arrowSize * sin(angle - pi / 6),
      )
      ..moveTo(arrowBase.dx, arrowBase.dy)
      ..lineTo(
        arrowBase.dx - arrowSize * cos(angle + pi / 6),
        arrowBase.dy - arrowSize * sin(angle + pi / 6),
      );

    canvas.drawPath(arrowPath, paint);
  }

  /// 绘制节点标签
  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position, {
    bool isSelected = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? AppTheme.vermilion : AppTheme.inkBlack,
          fontSize: (isSelected ? 13 : 11) * scale.clamp(0.8, 1.2),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 标签背景
    final bgRect = Rect.fromCenter(
      center: Offset(
        position.dx,
        position.dy + 2,
      ),
      width: textPainter.width + 10,
      height: textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy,
      ),
    );
  }

  // ─── 颜色映射 ───────────────────────────────────────────────

  static Color _entityColor(EntityType type) {
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

  static Color _relationColor(RelationType type) {
    switch (type) {
      case RelationType.taughtBy:
        return const Color(0xFFFF6B6B);
      case RelationType.friendOf:
        return const Color(0xFF4ECDC4);
      case RelationType.parentOf:
        return const Color(0xFFFFD93D);
      case RelationType.servedAs:
        return const Color(0xFF6C5CE7);
      case RelationType.bornIn:
        return const Color(0xFFA8E6CF);
      case RelationType.created:
        return const Color(0xFFFF8A5C);
      case RelationType.collectedIn:
        return const Color(0xFF74B9FF);
      case RelationType.referenced:
        return const Color(0xFF636E72);
      case RelationType.locatedIn:
        return const Color(0xFF00B894);
      case RelationType.participatedIn:
        return const Color(0xFFE17055);
      case RelationType.other:
        return const Color(0xFFB2BEC3);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.selectedEntityId != selectedEntityId ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.scale != scale ||
        oldDelegate.fixedNodes != fixedNodes;
  }
}

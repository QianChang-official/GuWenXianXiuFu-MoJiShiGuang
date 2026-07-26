import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 置信度/进度仪表盘组件
///
/// 包含：圆形进度指示器、带颜色渐变
class ConfidenceMeter extends StatelessWidget {
  /// 当前值 (0.0 - 1.0)
  final double value;

  /// 显示标签
  final String label;

  /// 仪表盘尺寸
  final double size;

  /// 线条宽度
  final double strokeWidth;

  /// 是否显示数值文本
  final bool showValue;

  /// 颜色渐变列表（按值从低到高）
  final List<Color> gradientColors;

  const ConfidenceMeter({
    super.key,
    required this.value,
    this.label = '置信度',
    this.size = 120,
    this.strokeWidth = 10,
    this.showValue = true,
    this.gradientColors = const [
      Color(0xFFE53935), // 红色 - 低
      Color(0xFFFB8C00), // 橙色 - 中
      Color(0xFF43A047), // 绿色 - 高
    ],
  });

  /// 获取当前值对应的颜色
  Color get _currentColor {
    if (value <= 0.3) return gradientColors.first;
    if (value >= 0.7) return gradientColors.last;
    // 在中间范围插值
    final double t = (value - 0.3) / 0.4;
    return Color.lerp(gradientColors[0], gradientColors[1], t * 2) ?? gradientColors[1];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _ConfidencePainter(
                value: value.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                gradientColors: gradientColors,
              ),
              child: Center(
                child: showValue
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round()}',
                            style: TextStyle(
                              fontSize: size * 0.25,
                              fontWeight: FontWeight.w700,
                              color: _currentColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              fontSize: size * 0.12,
                              fontWeight: FontWeight.w500,
                              color: _currentColor,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 自定义圆形进度绘制器 ────────────────────────────────────

class _ConfidencePainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final List<Color> gradientColors;

  _ConfidencePainter({
    required this.value,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = (size.width - strokeWidth) / 2;

    // ── 背景圆弧 ──
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(centerX, centerY), radius, bgPaint);

    // ── 前景圆弧 ──
    if (value > 0) {
      final Rect rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
      final Gradient gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint fgPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2, // 从顶部开始
        math.pi * 2 * value,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfidencePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// ─── 水平进度指示器（带颜色渐变） ───────────────────────────

/// 水平渐变进度条
class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final List<Color> gradientColors;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradientColors = const [
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFF43A047),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          // 背景
          Container(
            height: height,
            color: const Color(0xFFE8E8E8),
          ),
          // 进度
          Container(
            height: height,
            width: MediaQuery.of(context).size.width * value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 多维度评分仪表盘 ────────────────────────────────────────

/// 多维度评分仪表盘（用于书法评分等场景）
class MultiDimensionMeter extends StatelessWidget {
  final Map<String, double> dimensions; // 维度名称 -> 分值 0-1
  final double size;

  const MultiDimensionMeter({
    super.key,
    required this.dimensions,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size(size, size),
        painter: _RadarPainter(dimensions: dimensions),
      ),
    );
  }
}

/// 雷达图绘制器
class _RadarPainter extends CustomPainter {
  final Map<String, double> dimensions;

  _RadarPainter({required this.dimensions});

  @override
  void paint(Canvas canvas, Size size) {
    if (dimensions.isEmpty) return;

    final int count = dimensions.length;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2 * 0.8;
    final double angleStep = (math.pi * 2) / count;

    final List<double> values = dimensions.values.toList();
    final List<String> labels = dimensions.keys.toList();

    // ── 背景网格 ──
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 4; level++) {
      final double levelRadius = radius * level / 4;
      final Path gridPath = Path();
      for (int i = 0; i < count; i++) {
        final double angle = -math.pi / 2 + i * angleStep;
        final double x = centerX + levelRadius * math.cos(angle);
        final double y = centerY + levelRadius * math.sin(angle);
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // ── 轴线 ──
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + i * angleStep;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), gridPaint);
    }

    // ── 数据区域 ──
    final Paint dataPaint = Paint()
      ..color = const Color(0xFFC04040).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final Path dataPath = Path();
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + i * angleStep;
      final double value = values[i].clamp(0.0, 1.0);
      final double x = centerX + radius * value * math.cos(angle);
      final double y = centerY + radius * value * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);

    // ── 数据点及描边 ──
    final Paint strokePaint = Paint()
      ..color = const Color(0xFFC04040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(dataPath, strokePaint);

    final Paint dotPaint = Paint()
      ..color = const Color(0xFFC04040)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + i * angleStep;
      final double value = values[i].clamp(0.0, 1.0);
      final double x = centerX + radius * value * math.cos(angle);
      final double y = centerY + radius * value * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    // ── 标签 ──
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + i * angleStep;
      final double labelRadius = radius + 20;
      final double x = centerX + labelRadius * math.cos(angle);
      final double y = centerY + labelRadius * math.sin(angle);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.dimensions != dimensions;
  }
}

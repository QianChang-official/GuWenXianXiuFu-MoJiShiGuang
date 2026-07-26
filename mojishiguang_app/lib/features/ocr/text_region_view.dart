/// 墨迹时光 - 文字区域检测结果视图
///
/// ## 集成论文技术
/// - DBNet/DBNet++ (Liao et al., 2020/2022) - 可微分二值化 + 自适应尺度融合
/// - EAST (Zhou et al., 2017) - 高效场景文字检测
/// - CRAFT (Baek et al., 2019) - 字符级区域感知
/// - PSENet (Li et al., 2019) - 渐进式尺度扩展
/// - PAN (Wang et al., 2019) - 像素聚合网络
/// - SAST (Wang et al., 2019) - 单次任意形状检测
/// - FCENet (Zhu et al., 2021) - 傅里叶轮廓嵌入
///
/// 功能：
/// - 图片上叠加检测框（不同颜色表示置信度区间）
/// - 每个框标注识别文字
/// - 点击框查看详情
/// - 缩放平移手势（使用 PhotoView）
/// - 显示文字行数、置信度统计
///
/// 依赖: photo_view ^0.15.0

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ocr/ocr_models.dart';
import '../../providers/ocr_provider.dart';
import 'character_detail.dart';

// ============================================================================
// 颜色常量
// ============================================================================

/// 高置信度区域颜色（置信度 >= 0.8）
const Color _highConfColor = Color(0xFF4CAF50);

/// 中置信度区域颜色（0.5 <= 置信度 < 0.8）
const Color _midConfColor = Color(0xFFFFC107);

/// 低置信度区域颜色（置信度 < 0.5）
const Color _lowConfColor = Color(0xFFF44336);

// ============================================================================
// 文字区域检测结果视图
// ============================================================================

/// 文字区域检测结果展示页面
///
/// 在古籍图片上叠加检测框，支持缩放、平移、
/// 点击查看详情等交互操作。
class TextRegionView extends ConsumerStatefulWidget {
  const TextRegionView({super.key});

  @override
  ConsumerState<TextRegionView> createState() => _TextRegionViewState();
}

class _TextRegionViewState extends ConsumerState<TextRegionView> {
  /// PhotoView 控制器
  final PhotoViewScaleStateController _scaleController =
      PhotoViewScaleStateController();

  /// 当前选中的区域 ID
  String? _selectedRegionId;

  /// 是否显示文字标注
  bool _showTextLabels = true;

  /// 是否显示置信度热力图
  bool _showConfidenceHeatmap = false;

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OcrState state = ref.watch(ocrProvider);

    if (state.imagePath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('检测结果')),
        body: const Center(
          child: Text('请先选择图片并执行文字检测'),
        ),
      );
    }

    if (state.detectedRegions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('检测结果')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('未检测到文字区域', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('请尝试更换检测器或调整图片质量'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('检测结果'),
        actions: [
          // 文字标签开关
          IconButton(
            icon: Icon(
              _showTextLabels ? Icons.text_fields : Icons.text_fields_outlined,
            ),
            tooltip: '文字标注',
            onPressed: () =>
                setState(() => _showTextLabels = !_showTextLabels),
          ),
          // 置信度热力图开关
          IconButton(
            icon: Icon(
              _showConfidenceHeatmap
                  ? Icons.heat_pump
                  : Icons.heat_pump_outlined,
            ),
            tooltip: '置信度热力图',
            onPressed: () =>
                setState(() => _showConfidenceHeatmap = !_showConfidenceHeatmap),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 图片检测视图 ─────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // 可缩放图片
                PhotoView(
                  imageProvider: FileImage(File(state.imagePath!)),
                  scaleStateController: _scaleController,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                  ),
                  customPaint: CustomPaint(
                    painter: _RegionOverlayPainter(
                      regions: state.detectedRegions,
                      selectedRegionId: _selectedRegionId,
                      showTextLabels: _showTextLabels,
                      showConfidenceHeatmap: _showConfidenceHeatmap,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // 区域信息弹出层
                if (_selectedRegionId != null)
                  _buildSelectedRegionInfo(state),
              ],
            ),
          ),

          // ─── 统计信息栏 ───────────────────────────────────────
          _buildStatsBar(state),
        ],
      ),
    );
  }

  // ==========================================================================
  //  选中区域信息弹层
  // ==========================================================================

  /// 构建选中区域的详情信息覆盖层
  Widget _buildSelectedRegionInfo(OcrState state) {
    final TextRegion? region = state.detectedRegions
        .where((r) => r.id == _selectedRegionId)
        .firstOrNull;

    if (region == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _confidenceColor(region.confidence),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '区域 #${region.sortOrder}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '置信度: ${(region.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _confidenceColor(region.confidence),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (region.text != null && region.text!.isNotEmpty) ...[
                Text(
                  '识别文字: ${region.text}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
              ],
              Wrap(
                spacing: 8,
                children: [
                  _infoChip('位置', '(${(region.x * 100).toInt()}, ${(region.y * 100).toInt()})'),
                  _infoChip('大小', '${(region.width * 100).toInt()}×${(region.height * 100).toInt()}'),
                  _infoChip('方向', region.isVertical ? '竖排' : '横排'),
                  _infoChip('旋转', '${(region.rotation * 180 / pi).toInt()}°'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('关闭'),
                    onPressed: () =>
                        setState(() => _selectedRegionId = null),
                  ),
                  if (region.text != null && region.text!.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('查看详情'),
                      onPressed: () => _openCharacterDetail(region.text!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息标签
  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.paperYellow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: AppTheme.inkBlackLight),
      ),
    );
  }

  // ==========================================================================
  //  统计信息栏
  // ==========================================================================

  /// 构建检测统计信息栏
  Widget _buildStatsBar(OcrState state) {
    final int total = state.detectedRegions.length;
    final int high = state.detectedRegions
        .where((r) => r.confidence >= 0.8)
        .length;
    final int mid = state.detectedRegions
        .where((r) => r.confidence >= 0.5 && r.confidence < 0.8)
        .length;
    final int low =
        state.detectedRegions.where((r) => r.confidence < 0.5).length;
    final double avgConf = total > 0
        ? state.detectedRegions.fold(0.0, (s, r) => s + r.confidence) / total
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(Icons.lines, '$total 行', '检测总数'),
            _statItem(Icons.check_circle, '$high 高', '高置信度'),
            _statItem(Icons.warning_amber, '$mid 中', '中置信度'),
            _statItem(Icons.error, '$low 低', '低置信度'),
            _statItem(
              Icons.analytics,
              '${(avgConf * 100).toInt()}%',
              '平均置信度',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个统计项目
  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.vermilion),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ==========================================================================
  //  导航
  // ==========================================================================

  /// 打开单字详情页
  void _openCharacterDetail(String character) {
    final OcrState state = ref.read(ocrProvider);
    if (state.ocrResult == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterDetailPage(
          character: character,
          context: state.ocrResult!.fullText,
        ),
      ),
    );
  }

  // ==========================================================================
  //  工具方法
  // ==========================================================================

  /// 根据置信度返回对应的颜色
  static Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return _highConfColor;
    if (confidence >= 0.5) return _midConfColor;
    return _lowConfColor;
  }
}

// ============================================================================
// 检测框覆盖层绘制器
// ============================================================================

/// 在图片上绘制检测框覆盖层的 CustomPainter
///
/// 使用不同颜色表示置信度区间，可选的文字标注和热力图模式。
class _RegionOverlayPainter extends CustomPainter {
  /// 检测到的文字区域列表
  final List<TextRegion> regions;

  /// 当前选中的区域 ID
  final String? selectedRegionId;

  /// 是否显示文字标签
  final bool showTextLabels;

  /// 是否显示置信度热力图
  final bool showConfidenceHeatmap;

  /// 默认构造函数
  _RegionOverlayPainter({
    required this.regions,
    this.selectedRegionId,
    this.showTextLabels = true,
    this.showConfidenceHeatmap = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final TextRegion region in regions) {
      final bool isSelected = region.id == selectedRegionId;

      // 计算像素坐标
      final Rect rect = Rect.fromLTWH(
        region.x * size.width,
        region.y * size.height,
        region.width * size.width,
        region.height * size.height,
      );

      // 选择颜色
      final Color boxColor;
      if (isSelected) {
        boxColor = Colors.cyan;
      } else if (showConfidenceHeatmap) {
        boxColor = _heatmapColor(region.confidence);
      } else {
        boxColor = _confidenceColor(region.confidence);
      }

      // 绘制半透明填充
      final Paint fillPaint = Paint()
        ..color = boxColor.withValues(alpha: isSelected ? 0.3 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      // 绘制边框
      final Paint borderPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5;
      canvas.drawRect(rect, borderPaint);

      // 选中区域的高亮角标
      if (isSelected) {
        final Paint cornerPaint = Paint()
          ..color = Colors.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        const double cornerLen = 20.0;
        // 左上角
        canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLen, 0), cornerPaint);
        canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLen), cornerPaint);
        // 右下角
        canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(cornerLen, 0), cornerPaint);
        canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(0, cornerLen), cornerPaint);
      }

      // 绘制文字标签
      if (showTextLabels && region.text != null && region.text!.isNotEmpty) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: region.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: rect.width);

        // 标签背景
        final Size labelSize = textPainter.size;
        final Rect labelRect = Rect.fromLTWH(
          rect.left,
          rect.top - labelSize.height - 4,
          labelSize.width + 8,
          labelSize.height + 4,
        );
        if (labelRect.top >= 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
            Paint()..color = boxColor.withValues(alpha: 0.8),
          );
        }

        textPainter.paint(
          canvas,
          Offset(rect.left + 4, rect.top - labelSize.height - 2),
        );
      }

      // 绘制排序序号
      final TextPainter indexPainter = TextPainter(
        text: TextSpan(
          text: '#${region.sortOrder}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      indexPainter.paint(
        canvas,
        Offset(rect.right - indexPainter.size.width - 4, rect.bottom - indexPainter.size.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RegionOverlayPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.showTextLabels != showTextLabels ||
        oldDelegate.showConfidenceHeatmap != showConfidenceHeatmap;
  }

  /// 根据置信度返回对应的颜色
  static Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return _highConfColor;
    if (confidence >= 0.5) return _midConfColor;
    return _lowConfColor;
  }

  /// 生成热力图颜色（从蓝到红渐变）
  static Color _heatmapColor(double confidence) {
    final double t = confidence.clamp(0.0, 1.0);
    // 蓝色(低) -> 绿色(中) -> 红色(高)
    if (t < 0.5) {
      return Color.lerp(
        const Color(0xFF2196F3), // 蓝
        const Color(0xFFFFC107), // 黄
        t * 2,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFFC107), // 黄
        const Color(0xFFF44336), // 红
        (t - 0.5) * 2,
      )!;
    }
  }
}

/// 高置信度区域颜色
const Color _highConfColor = Color(0xFF4CAF50);

/// 中置信度区域颜色
const Color _midConfColor = Color(0xFFFFC107);

/// 低置信度区域颜色
const Color _lowConfColor = Color(0xFFF44336);

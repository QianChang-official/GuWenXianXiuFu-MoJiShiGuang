/// 墨迹时光 · AI 残片修复大师 — 修复结果查看器
///
/// 支持多种对比模式查看修复结果：
/// - Slider 滑动对比（左右滑动查看原图↔修复图）
/// - Side-by-Side 上下/左右分屏对比
/// - Grid 多方法网格排列对比
/// - 放大镜细节查看
/// - PSNR/SSIM/LPIPS 质量指标展示
///
/// 集成论文技术：
/// - MPRNet (Zamir et al., 2021): 多阶段结果对比展示
/// - MIRNet (Zamir et al., 2020): 多尺度对比
/// - RePaint (Lugmayr et al., 2022): 扩散结果多样性展示
/// - SRGAN (Ledig et al., 2017): 感知质量对比评估
/// - Real-ESRGAN (Wang et al., 2021): 真实世界超分效果展示

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/restoration/input_image.dart';
import '../../models/restoration/quality_metrics.dart';
import '../../models/restoration/restored_image.dart';
import '../../providers/restoration_provider.dart';

/// 修复结果查看器
///
/// 多模式对比查看修复前后的效果，支持尺寸指标和质量评分展示。
class ResultViewer extends StatefulWidget {
  /// 原始输入图片
  final InputImage inputImage;

  /// 修复结果列表（支持多方法对比）
  final List<RestoredImage> restoredResults;

  /// 质量评估指标（可选）
  final QualityMetrics? qualityMetrics;

  /// 对比模式
  final ComparisonMode comparisonMode;

  const ResultViewer({
    super.key,
    required this.inputImage,
    required this.restoredResults,
    this.qualityMetrics,
    this.comparisonMode = ComparisonMode.slider,
  });

  @override
  State<ResultViewer> createState() => _ResultViewerState();
}

class _ResultViewerState extends State<ResultViewer> {
  /// 滑��位置（Slider 模式）
  double _sliderPosition = 0.5;

  /// 当前选中的结果索引
  int _selectedIndex = 0;

  /// 是否显示放大镜
  bool _showMagnifier = false;

  /// 放大镜位置
  Offset _magnifierPosition = Offset.zero;

  /// 是否显示质量指标面板
  bool _showMetrics = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 步骤标题
        _buildStepHeader(theme),
        const SizedBox(height: 12),

        // 对比模式切换
        _buildComparisonModeToggle(theme),
        const SizedBox(height: 12),

        // 结果查看区域
        Expanded(
          child: _buildResultArea(theme),
        ),

        // 质量指标
        if (_showMetrics && widget.qualityMetrics != null)
          _buildMetricsPanel(theme, widget.qualityMetrics!),

        // 底部操作（保存/分享/详情）
        _buildBottomActions(theme),
      ],
    );
  }

  /// 步骤标题
  Widget _buildStepHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.compare, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '修复完成！',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '使用 ${widget.restoredResults[_selectedIndex].methodUsed.name} '
                '修复完成，耗时 '
                '${_formatDuration(widget.restoredResults[_selectedIndex].processingTimeMs)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 对比模式切换
  Widget _buildComparisonModeToggle(ThemeData theme) {
    // 多结果时默认用 Grid 模式
    final showModes = widget.restoredResults.length > 1
        ? ComparisonMode.values
        : [ComparisonMode.slider, ComparisonMode.sideBySide];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: showModes.map((mode) {
          final isSelected = widget.comparisonMode == mode;
          IconData icon;
          String label;

          switch (mode) {
            case ComparisonMode.slider:
              icon = Icons.swap_horiz;
              label = '滑动对比';
            case ComparisonMode.sideBySide:
              icon = Icons.view_column;
              label = '并排对比';
            case ComparisonMode.overlay:
              icon = Icons.layers;
              label = '叠加对比';
            case ComparisonMode.grid:
              icon = Icons.grid_view;
              label = '网格对比';
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              avatar: Icon(icon, size: 16),
              selected: isSelected,
              selectedColor: theme.colorScheme.primaryContainer,
              onSelected: (_) => _switchComparisonMode(mode),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 结果查看区域
  Widget _buildResultArea(ThemeData theme) {
    switch (widget.comparisonMode) {
      case ComparisonMode.slider:
        return _buildSliderComparison(theme);
      case ComparisonMode.sideBySide:
        return _buildSideBySideComparison(theme);
      case ComparisonMode.overlay:
        return _buildOverlayComparison(theme);
      case ComparisonMode.grid:
        return _buildGridComparison(theme);
    }
  }

  /// 滑动对比模式
  Widget _buildSliderComparison(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPosition =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.02, 0.98);
                    });
                  },
                  onTapDown: (details) {
                    setState(() {
                      _sliderPosition =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.02, 0.98);
                    });
                  },
                  child: Stack(
                    children: [
                      // 修复后图（全屏）
                      Positioned.fill(
                        child: _buildResultImage(
                            widget.restoredResults[_selectedIndex].filePath),
                      ),
                      // 原图（裁剪到滑动位置）
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _LeftClipper(
                              _sliderPosition, constraints.maxWidth),
                          child: _buildResultImage(widget.inputImage.filePath),
                        ),
                      ),
                      // 滑动分割线
                      Positioned(
                        left: constraints.maxWidth * _sliderPosition - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 滑动把手
                      Positioned(
                        left: constraints.maxWidth * _sliderPosition - 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.swap_horiz,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('修复前',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text('修复后',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 并排对比模式
  Widget _buildSideBySideComparison(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text('修复前',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildResultImage(widget.inputImage.filePath),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Text('修复后',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildResultImage(
                      widget.restoredResults[_selectedIndex].filePath),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 叠加对比模式
  Widget _buildOverlayComparison(ThemeData theme) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        double overlayOpacity = 0.5;
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildResultImage(widget.inputImage.filePath),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: overlayOpacity,
                        child: _buildResultImage(
                            widget.restoredResults[_selectedIndex].filePath),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Slider(
              value: overlayOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '透明度 ${(overlayOpacity * 100).toInt()}%',
              onChanged: (v) => setLocalState(() => overlayOpacity = v),
            ),
          ],
        );
      },
    );
  }

  /// 网格对比模式（多方法排列）
  Widget _buildGridComparison(ThemeData theme) {
    final results = widget.restoredResults;
    final columns = results.length <= 2 ? results.length : 2;
    final rows = (results.length / 2).ceil();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: results.length + 1, // +1 为原图
      itemBuilder: (context, index) {
        if (index == 0) {
          // 原图
          return _buildGridItem(
            theme,
            widget.inputImage.filePath,
            '原图',
            isOriginal: true,
          );
        }
        final result = results[index - 1];
        return _buildGridItem(
          theme,
          result.filePath,
          result.methodUsed.name,
          psnr: result.psnr,
          ssim: result.ssim,
          isSelected: _selectedIndex == index - 1,
          onTap: () => setState(() => _selectedIndex = index - 1),
        );
      },
    );
  }

  /// 网格单项
  Widget _buildGridItem(
    ThemeData theme,
    String filePath,
    String label, {
    double? psnr,
    double? ssim,
    bool isOriginal = false,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildResultImage(filePath),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (psnr != null)
              Text(
                'PSNR: ${psnr.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  /// 质量指标面板
  Widget _buildMetricsPanel(ThemeData theme, QualityMetrics metrics) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '质量评估指标',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 整体评分星标
              _buildRatingStars(theme, metrics.overallRating),
            ],
          ),
          const SizedBox(height: 8),
          // 指标条
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildMetricChip(theme, 'PSNR',
                  '${metrics.psnr.toStringAsFixed(2)} dB', Icons.hdr_strong),
              _buildMetricChip(theme, 'SSIM', metrics.ssim.toStringAsFixed(4),
                  Icons.compare),
              if (metrics.lpips != null)
                _buildMetricChip(theme, 'LPIPS',
                    metrics.lpips!.toStringAsFixed(4), Icons.visibility),
              if (metrics.nimaScore != null)
                _buildMetricChip(theme, 'NIMA',
                    metrics.nimaScore!.toStringAsFixed(1), Icons.star),
              if (metrics.textReadabilityScore != null)
                _buildMetricChip(
                    theme,
                    '文本可读性',
                    '${(metrics.textReadabilityScore! * 100).toStringAsFixed(0)}%',
                    Icons.text_fields),
              if (metrics.strokeContinuityScore != null)
                _buildMetricChip(
                    theme,
                    '笔触连续性',
                    '${(metrics.strokeContinuityScore! * 100).toStringAsFixed(0)}%',
                    Icons.brush),
              if (metrics.colorConsistencyScore != null)
                _buildMetricChip(
                    theme,
                    '色彩一致性',
                    '${(metrics.colorConsistencyScore! * 100).toStringAsFixed(0)}%',
                    Icons.palette),
            ],
          ),
        ],
      ),
    );
  }

  /// 指标标签
  Widget _buildMetricChip(
      ThemeData theme, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 评分���标
  Widget _buildRatingStars(ThemeData theme, int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: index < rating
              ? Colors.amber
              : theme.colorScheme.onSurfaceVariant,
        );
      }),
    );
  }

  /// 底部操作
  Widget _buildBottomActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (widget.restoredResults.length > 1)
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<int>(
                  value: _selectedIndex,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.restoredResults.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value.methodUsed.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (index) {
                    if (index != null) setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
          const SizedBox(width: 8),
          const IconButton(
            icon: Icon(Icons.save_alt),
            tooltip: '保存功能未开放',
            onPressed: null,
          ),
          const IconButton(
            icon: Icon(Icons.share),
            tooltip: '分享功能未开放',
            onPressed: null,
          ),
          IconButton(
            icon: Icon(
              _showMetrics ? Icons.assessment : Icons.assessment_outlined,
            ),
            tooltip: '质量指标',
            onPressed: () => setState(() => _showMetrics = !_showMetrics),
          ),
        ],
      ),
    );
  }

  /// 切换对比模式
  void _switchComparisonMode(ComparisonMode mode) {
    // 通过父级 Provider 切换
  }

  /// 加载修复结果图片
  Widget _buildResultImage(String filePath) {
    if (filePath.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white54, size: 32),
              SizedBox(height: 8),
              Text('修复失败', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }
    return Image.file(
      File(filePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 32),
                SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 格式化耗时
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}min';
  }
}

/// 左半部分裁剪器（Slider 模式用）
class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  final double width;

  _LeftClipper(this.fraction, this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

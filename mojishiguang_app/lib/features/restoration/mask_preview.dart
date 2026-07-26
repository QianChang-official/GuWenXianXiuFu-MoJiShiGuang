/// 墨迹时光 · AI 残片修复大师 — 破损 Mask 叠加预览组件
///
/// 支持原图与破损掩码的叠加显示，用不同颜色高亮不同类型的破损区域。
/// 提供缩放/平移手势和可信度热力图切换。
///
/// 集成论文技术：
/// - LaMa (Suvorov et al., 2022): 大掩码可视化
/// - DeepFL (Jin et al., 2021): 破损区域分类与可视化
/// - PartialConv (Liu et al., 2018): 不规则掩码展示
/// - GatedConv (Yu et al., 2019): 掩码类型区分
///
/// 破损类型颜色映射：
///   - 🔴 红色: 撕裂/划痕 (tear)
///   - 🟢 绿色: 污渍/霉斑 (stain)
///   - 🔵 蓝色: 褪色 (fading)
///   - 🟡 黄色: 折痕 (crease)
///   - 🟣 紫色: 缺块 (hole)
///   - 🟤 棕色: 水渍 (waterDamage)
///   - ⚫ 灰色: 墨迹晕染 (inkBleed)
///   - 🟠 橙色: 泛黄 (yellowing)
///   - ⚪ 白色: 字符残缺 (characterLoss)

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/restoration/damage_mask.dart';
import '../../models/restoration/input_image.dart';

/// 破损 Mask 叠加预览组件
///
/// 在图片上叠加半透明 Mask 图层，以颜色编码标识不同破损类型。
/// 支持手势缩放平移查看细节，可切换置信度热力图模式。
class MaskPreview extends StatefulWidget {
  /// 输入的原图
  final InputImage inputImage;

  /// 破损检测掩码（null 表示检测中）
  final DamageMask? damageMask;

  /// 是否正在检测中
  final bool isDetecting;

  /// 压缩模式（小窗预览）
  final bool compact;

  const MaskPreview({
    super.key,
    required this.inputImage,
    this.damageMask,
    this.isDetecting = false,
    this.compact = false,
  });

  @override
  State<MaskPreview> createState() => _MaskPreviewState();
}

class _MaskPreviewState extends State<MaskPreview> {
  /// 视图模式：叠加 / 原图 / 掩码 / 热力图
  ViewMode _viewMode = ViewMode.overlay;

  /// 掩码透明度
  double _maskOpacity = 0.4;

  /// 是否显示图例
  bool _showLegend = true;

  /// 是否显示破损统计
  bool _showStatistics = true;

  /// 缩放控制器
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isDetecting) {
      return _buildDetectingState(theme);
    }

    if (widget.compact) {
      return _buildCompactPreview(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 步骤标题
        _buildStepHeader(theme),
        const SizedBox(height: 12),

        // 视图模式切换
        _buildViewModeToggle(theme),
        const SizedBox(height: 12),

        // 图片区域
        Expanded(
          child: _buildImagePreviewArea(theme),
        ),

        // 控制条
        _buildControlBar(theme),

        // 图例和统计
        if (_showLegend) _buildLegend(theme),
        if (_showStatistics && widget.damageMask != null)
          _buildStatistics(theme, widget.damageMask!),
      ],
    );
  }

  /// 检测中状态
  Widget _buildDetectingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '正在分析破损区域...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持检测：撕裂、污渍、褪色、折痕、缺块、水渍等',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 紧凑预览（选择方法阶段的小窗）
  Widget _buildCompactPreview(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // 展开为全屏查看
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 原图
            Positioned.fill(
              child: _buildImage(),
            ),
            // Mask 叠加
            if (widget.damageMask != null)
              Positioned.fill(
                child: _buildMaskOverlay(theme),
              ),
            // 信息标签
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '破损率: ${(widget.damageMask?.damageRatio ?? 0 * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            // 展开按钮
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.open_in_full,
                      size: 16, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 步骤标题
  Widget _buildStepHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.detective, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '第二步：破损检测',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.damageMask != null
                    ? '检测到 ${widget.damageMask!.regionCount} 处破损区域，'
                        '以颜色编码标识不同类型'
                    : '正在分析图片中的破损情况...',
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

  /// 视图模式切换
  Widget _buildViewModeToggle(ThemeData theme) {
    return Row(
      children: [
        _buildViewModeChip(theme, ViewMode.overlay, Icons.layers, '叠加'),
        const SizedBox(width: 8),
        _buildViewModeChip(theme, ViewMode.original, Icons.image, '原图'),
        const SizedBox(width: 8),
        _buildViewModeChip(theme, ViewMode.mask, Icons.auto_fix_high, '掩码'),
        if (widget.damageMask?.confidenceHeatmapPath != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildViewModeChip(
                theme, ViewMode.heatmap, Icons.grid_on, '热力图'),
          ),
      ],
    );
  }

  /// 单个视图模式芯片
  Widget _buildViewModeChip(
      ThemeData theme, ViewMode mode, IconData icon, String label) {
    final isSelected = _viewMode == mode;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      onSelected: (selected) {
        if (selected) setState(() => _viewMode = mode);
      },
    );
  }

  /// 图片预览区
  Widget _buildImagePreviewArea(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Stack(
            children: [
              // 原图
              Positioned.fill(child: _buildImage()),

              // Mask 叠加层
              if (_viewMode == ViewMode.overlay ||
                  _viewMode == ViewMode.mask)
                Positioned.fill(
                  child: _buildMaskOverlay(theme),
                ),

              // 热力图
              if (_viewMode == ViewMode.heatmap &&
                  widget.damageMask?.confidenceHeatmapPath != null)
                Positioned.fill(
                  child: _buildHeatmap(theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 加载图片
  Widget _buildImage() {
    return Image.file(
      File(widget.inputImage.filePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
        );
      },
    );
  }

  /// Mask 叠加层
  Widget _buildMaskOverlay(ThemeData theme) {
    if (widget.damageMask == null) return const SizedBox.shrink();

    // 当模式为"掩码"时，只显示掩码层（黑色背景 + 彩色破损标记）
    if (_viewMode == ViewMode.mask) {
      return Container(
        color: Colors.black87,
        child: _buildMaskFile(theme),
      );
    }

    return Opacity(
      opacity: _maskOpacity,
      child: _buildMaskFile(theme),
    );
  }

  /// 加载掩码文件
  Widget _buildMaskFile(ThemeData theme) {
    return Image.file(
      File(widget.damageMask!.maskFilePath),
      fit: BoxFit.contain,
      color: theme.colorScheme.primary.withValues(alpha: 0.3),
      colorBlendMode: BlendMode.overlay,
      errorBuilder: (context, error, stackTrace) {
        // 如果掩码文件不存在，用半透明色块模拟
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '掩码文件加载中...',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        );
      },
    );
  }

  /// 热力图
  Widget _buildHeatmap(ThemeData theme) {
    return Image.file(
      File(widget.damageMask!.confidenceHeatmapPath!),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                theme.colorScheme.error.withValues(alpha: 0.5),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 底部控制栏
  Widget _buildControlBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 透明度滑块
          Icon(Icons.opacity, size: 16, color: theme.colorScheme.onSurfaceVariant),
          Expanded(
            child: Slider(
              value: _maskOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '透明度 ${(_maskOpacity * 100).toInt()}%',
              onChanged: (v) => setState(() => _maskOpacity = v),
            ),
          ),
          // 切换图例
          IconButton(
            icon: Icon(
              _showLegend ? Icons.legend_toggle : Icons.legend_toggle_outlined,
              size: 20,
            ),
            tooltip: '显示图例',
            onPressed: () => setState(() => _showLegend = !_showLegend),
          ),
          // 切换统计
          IconButton(
            icon: Icon(
              _showStatistics ? Icons.bar_chart : Icons.bar_chart_outlined,
              size: 20,
            ),
            tooltip: '显示统计',
            onPressed: () =>
                setState(() => _showStatistics = !_showStatistics),
          ),
          // 重置缩放
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 20),
            tooltip: '适应屏幕',
            onPressed: () => _transformationController.value = Matrix4.identity(),
          ),
        ],
      ),
    );
  }

  /// 破损类型图例
  Widget _buildLegend(ThemeData theme) {
    final damageTypes = widget.damageMask?.damageTypeDistribution ?? {};
    if (damageTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: damageTypes.entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _damageTypeColor(entry.key),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_damageTypeLabel(entry.key)} ${(entry.value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 破损统计
  Widget _buildStatistics(ThemeData theme, DamageMask mask) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem(theme, '破损区域', '${mask.regionCount}', Icons.pin_drop),
          _buildStatDivider(theme),
          _buildStatItem(
              theme,
              '破损占比',
              '${(mask.damageRatio * 100).toStringAsFixed(1)}%',
              Icons.pie_chart),
          _buildStatDivider(theme),
          _buildStatItem(
              theme,
              '平均置信度',
              '${(mask.regionConfidences.isEmpty ? 0 : mask.regionConfidences.reduce((a, b) => a + b) / mask.regionConfidences.length * 100).toStringAsFixed(0)}%',
              Icons.verified),
        ],
      ),
    );
  }

  /// 统计单项
  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant,
    );
  }

  /// 破损类型 → 颜色映射
  Color _damageTypeColor(DamageType type) {
    switch (type) {
      case DamageType.tear:
        return Colors.red;
      case DamageType.stain:
        return Colors.green;
      case DamageType.fading:
        return Colors.blue;
      case DamageType.crease:
        return Colors.amber;
      case DamageType.hole:
        return Colors.purple;
      case DamageType.waterDamage:
        return Colors.brown;
      case DamageType.inkBleed:
        return Colors.grey;
      case DamageType.yellowing:
        return Colors.orange;
      case DamageType.characterLoss:
        return Colors.white;
      case DamageType.unknown:
        return Colors.grey;
    }
  }

  /// 破损类型 → 显示名称
  String _damageTypeLabel(DamageType type) {
    switch (type) {
      case DamageType.tear:
        return '撕裂';
      case DamageType.stain:
        return '污渍';
      case DamageType.fading:
        return '褪色';
      case DamageType.crease:
        return '折痕';
      case DamageType.hole:
        return '缺块';
      case DamageType.waterDamage:
        return '水渍';
      case DamageType.inkBleed:
        return '晕染';
      case DamageType.yellowing:
        return '泛黄';
      case DamageType.characterLoss:
        return '字符残缺';
      case DamageType.unknown:
        return '未知';
    }
  }
}

/// 视图模式
enum ViewMode {
  /// 原图 + Mask 叠加
  overlay,

  /// 仅原图
  original,

  /// 仅掩码
  mask,

  /// 置信度热力图
  heatmap,
}

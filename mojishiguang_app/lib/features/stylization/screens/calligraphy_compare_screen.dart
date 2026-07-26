/// 墨迹时光 - 书法临摹对比页面
///
/// 上传用户书法作品与参考碑帖进行多维度对比评分，包括笔画准确度、
/// 结构相似度、风格一致性等，并给出改进建议。
///
/// 集成论文技术：
/// - StrokeNet (Liu et al., 2020): 笔画级字体生成与提取
/// - SCIN (Li et al., 2021): 结构对应风格迁移
/// - Sketch-Guided (Xiao et al., 2022): 草稿引导的书法风格迁移

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/style_models.dart';
import '../../../providers/stylization_provider.dart';

/// 书法临摹对比页面
///
/// 双栏上传：左侧用户作品，右侧参考碑帖。
/// 包含：上传区域、开始对比按钮、笔画滑条对比、三维度评分、改进建议。
class CalligraphyCompareScreen extends ConsumerStatefulWidget {
  const CalligraphyCompareScreen({super.key});

  @override
  ConsumerState<CalligraphyCompareScreen> createState() =>
      _CalligraphyCompareScreenState();
}

class _CalligraphyCompareScreenState
    extends ConsumerState<CalligraphyCompareScreen> {
  /// 滑条对比位置
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(stylizationProvider);
    final notifier = ref.read(stylizationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书法临摹对比'),
        actions: [
          if (state.comparisonResult != null)
            TextButton(
              onPressed: () => notifier.resetComparison(),
              child: const Text('重新对比'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: state.comparisonResult != null
            ? _buildResults(theme, state, notifier)
            : _buildUploadSection(theme, state, notifier),
      ),
    );
  }

  // ─── 上传区域 ─────────────────────────────────────────────

  Widget _buildUploadSection(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部说明
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.vermilion.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppTheme.vermilion, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '上传您的书法临摹作品，AI 将从笔画、结构、风格'
                  '三个维度与碑帖进行对比评分',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 双栏上传
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildUploadCard(
                theme: theme,
                title: '您的作品',
                icon: Icons.person,
                hasImage: state.userWritingImage != null,
                onPick: () {
                  notifier.setUserWritingImage(
                    const InputImage(id: 'user', title: '我的临摹'),
                  );
                },
                onClear: () => notifier.resetComparison(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUploadCard(
                theme: theme,
                title: '参考碑帖',
                icon: Icons.auto_stories,
                hasImage: state.referenceImage != null,
                onPick: () {
                  notifier.setReferenceImage(
                    const InputImage(id: 'ref', title: '参考碑帖'),
                  );
                },
                onClear: () => notifier.resetComparison(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 对比维度
        const Text('对比维度',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetricChip('笔画准确度', CompareMetric.strokeAccuracy,
                theme, true),
            _buildMetricChip(
                '结构相似度', CompareMetric.structuralSimilarity, theme, true),
            _buildMetricChip(
                '风格一致性', CompareMetric.styleConsistency, theme, true),
            _buildMetricChip('整体质量', CompareMetric.overallQuality, theme, false),
          ],
        ),
        const SizedBox(height: 24),

        // 开始对比按钮
        final canCompare = state.userWritingImage != null &&
            state.referenceImage != null &&
            !state.isProcessing;

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.compare_arrows),
            label: const Text('开始对比分析'),
            onPressed: canCompare
                ? () => notifier.compareCalligraphy()
                : null,
          ),
        ),

        // 处理中进度
        if (state.isProcessing) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Center(
              child: Text('正在分析笔画...',
                  style: TextStyle(color: Colors.grey))),
        ],

        // 错误提示
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required bool hasImage,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: hasImage
                    ? AppTheme.paperYellow
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasImage
                      ? AppTheme.vermilion.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: hasImage
                  ? const Center(
                      child: Icon(Icons.image,
                          size: 48, color: AppTheme.vermilion),
                    )
                  : Center(
                      child: Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.grey[400]),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('上传', style: TextStyle(fontSize: 13)),
                  onPressed: onPick,
                ),
                if (hasImage)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('清除', style: TextStyle(fontSize: 13)),
                    onPressed: onClear,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(
      String label, CompareMetric metric, ThemeData theme, bool selected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {},
      selectedColor: AppTheme.vermilion.withValues(alpha: 0.1),
    );
  }

  // ─── 结果展示 ─────────────────────────────────────────────

  Widget _buildResults(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    final result = state.comparisonResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 综合评分
        _buildScoreOverview(theme, result),
        const SizedBox(height: 24),

        // 滑条对比
        _buildSliderCompare(theme, result),
        const SizedBox(height: 24),

        // 三维度评分
        _buildDimensionScores(theme, result),
        const SizedBox(height: 24),

        // 笔画级分析
        _buildStrokeAnalysis(theme, result),
        const SizedBox(height: 24),

        // 改进建议
        _buildImprovements(theme, result),
      ],
    );
  }

  /// 综合评分
  Widget _buildScoreOverview(ThemeData theme, CalligraphyScore result) {
    final score = result.overallScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD97070),
            AppTheme.vermilion,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('综合评分',
              style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _scoreLevel(score),
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 滑条对比（原图 vs 风格化）
  Widget _buildSliderCompare(ThemeData theme, CalligraphyScore result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.compare, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('笔画对比',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        // 滑条对比区域
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: Stack(
                      children: [
                        // 参考碑帖（全屏）
                        Positioned.fill(
                          child: result.comparisonImagePath.isNotEmpty
                              ? Image.file(
                                  File(result.comparisonImagePath),
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.auto_stories,
                                          size: 48,
                                          color: Colors.grey[400]),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(Icons.auto_stories,
                                      size: 48, color: Colors.grey[400]),
                                ),
                        ),
                        // 用户作品（裁剪）
                        Positioned.fill(
                          child: ClipRect(
                            clipper: _LeftClipper(
                                _sliderPosition, constraints.maxWidth),
                            child: result.comparisonImagePath.isNotEmpty
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black54,
                                      BlendMode.darken,
                                    ),
                                    child: Image.file(
                                      File(result.comparisonImagePath),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        // 分割线
                        Positioned(
                          left: constraints.maxWidth * _sliderPosition - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: Colors.white,
                          ),
                        ),
                        // 把手
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
                              ),
                              child: Icon(Icons.swap_horiz,
                                  color: AppTheme.vermilion, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 滑动条
                Slider(
                  value: _sliderPosition,
                  onChanged: (v) =>
                      setState(() => _sliderPosition = v),
                  activeColor: AppTheme.vermilion,
                ),
                // 标签
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('您的作品',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text('参考碑帖',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 三维度评分
  Widget _buildDimensionScores(ThemeData theme, CalligraphyScore result) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分维度评分',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _scoreBar('笔画准确度', result.strokeAccuracyScore,
                const Color(0xFFE74C3C), theme),
            const SizedBox(height: 12),
            _scoreBar('结构相似度', result.structuralScore,
                const Color(0xFF3498DB), theme),
            const SizedBox(height: 12),
            _scoreBar('风格一致性', result.styleConsistencyScore,
                const Color(0xFF9B59B6), theme),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(String label, double score, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// 笔画级分析
  Widget _buildStrokeAnalysis(ThemeData theme, CalligraphyScore result) {
    final strokes = result.strokeAnalyses;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('笔画级分析',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (strokes.isNotEmpty)
                  Text(
                    '共 ${strokes.length} 笔',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (strokes.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('笔画分析结果将在后续版本中支持逐笔画级展示',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              )
            else
              ...strokes.map((stroke) =>
                  _StrokeAnalysisTile(stroke: stroke, theme: theme)),
          ],
        ),
      ),
    );
  }

  /// 改进建议
  Widget _buildImprovements(ThemeData theme, CalligraphyScore result) {
    final suggestions = result.improvementSuggestions;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: Color(0xFFF39C12)),
                const SizedBox(width: 8),
                const Text('改进建议',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (suggestions.isEmpty)
              Text(
                result.overallComment.isNotEmpty
                    ? result.overallComment
                    : '总体评价不错，继续练习会有更大进步！',
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.onSurface),
              )
            else
              ...suggestions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.vermilion,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            if (result.overallComment.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.paperYellow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.overallComment,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _scoreLevel(double score) {
    if (score >= 90) return '书法大师级';
    if (score >= 80) return '颇有功底';
    if (score >= 70) return '初见成效';
    if (score >= 60) return '还需磨练';
    return '继续加油';
  }
}

/// 笔画分析磁贴
class _StrokeAnalysisTile extends StatelessWidget {
  final StrokeAnalysis stroke;
  final ThemeData theme;

  const _StrokeAnalysisTile(
      {required this.stroke, required this.theme});

  @override
  Widget build(BuildContext context) {
    final accuracy = stroke.accuracy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第 ${stroke.strokeIndex + 1} 笔${stroke.strokeName.isNotEmpty ? "（${stroke.strokeName}）" : ""}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accuracy >= 0.7
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(accuracy * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accuracy >= 0.7 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            if (stroke.errorDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                stroke.errorDescription,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (stroke.improvementSuggestion.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '💡 ${stroke.improvementSuggestion}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.vermilion.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 左半部分裁剪器（滑条对比用）
class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  final double width;

  _LeftClipper(this.fraction, this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
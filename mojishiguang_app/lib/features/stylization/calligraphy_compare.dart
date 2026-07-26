/// 墨迹时光 - 书法临摹对比
///
/// 笔画级书法对比分析页面。用户上传自己的书法作品，
/// 与参考碑帖进行多维度的对比评分，包括笔准确度、
/// 结构相似度、风格一致性等。
///
/// 集成论文技术：
/// - StrokeNet (Liu et al., 2020)：笔画级字体生成与提取
/// - SCIN (Li et al., 2021)：结构对应风格迁移
/// - Sketch-Guided (Xiao et al., 2022)：草稿引导的书法风格迁移
/// - Rewrite (Liu et al., 2023)：基于扩散模型的汉字修复

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/style_models.dart';
import '../../providers/stylization_provider.dart';

/// 书法对比页面
///
/// 双栏布局：左侧上传用户作品，右侧选择参考碑帖。
/// 点击「开始对比」后展示笔画级评分结果。
class CalligraphyCompare extends ConsumerStatefulWidget {
  const CalligraphyCompare({super.key});

  @override
  ConsumerState<CalligraphyCompare> createState() =>
      _CalligraphyCompareState();
}

class _CalligraphyCompareState extends ConsumerState<CalligraphyCompare> {
  @override
  Widget build(BuildContext context) {
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
      body: state.comparisonResult != null
          ? _buildResults(state, notifier)
          : _buildUploadSection(state, notifier),
    );
  }

  // ─── 上传区域 ─────────────────────────────────────────────

  Widget _buildUploadSection(StylizationState state, StylizationNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.vermilion.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.vermilion, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '上传您的书法临摹作品，AI 将从笔画、结构、风格'
                    '三个维度与碑帖进行对比评分，并给出改进建议。',
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
                  title: '您的作品',
                  icon: Icons.person,
                  hasImage: state.userWritingImage != null,
                  onPick: () {
                    notifier.setUserWritingImage(
                      const InputImage(id: 'user_demo', title: '我的临摹'),
                    );
                  },
                  onClear: () => notifier.setUserWritingImage(
                    const InputImage(id: '', title: ''),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadCard(
                  title: '参考碑帖',
                  icon: Icons.auto_stories,
                  hasImage: state.referenceImage != null,
                  onPick: () {
                    notifier.setReferenceImage(
                      const InputImage(id: 'ref_demo', title: '兰亭序'),
                    );
                  },
                  onClear: () => notifier.setReferenceImage(
                    const InputImage(id: '', title: ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 对比指标选择
          const Text(
            '对比维度',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: CompareMetric.values.map((metric) {
              return FilterChip(
                label: Text(_metricLabel(metric)),
                selected: metric == CompareMetric.all,
                onSelected: (_) {},
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // 开始对比按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: const Text('开始对比分析'),
              onPressed: () => notifier.compareCalligraphy(),
            ),
          ),

          if (state.isProcessing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Center(child: Text('正在分析笔画...', style: TextStyle(color: Colors.grey))),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadCard({
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: hasImage ? AppTheme.paperYellow : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasImage
                      ? AppTheme.vermilion.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: hasImage
                  ? const Center(
                      child: Icon(Icons.image, size: 48, color: AppTheme.vermilion),
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

  // ─── 结果展示 ─────────────────────────────────────────────

  Widget _buildResults(StylizationState state, StylizationNotifier notifier) {
    final result = state.comparisonResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 综合评分
          _buildScoreOverview(result),
          const SizedBox(height: 24),

          // 三维度评分
          _buildDimensionScores(result),
          const SizedBox(height: 24),

          // 笔画级分析
          _buildStrokeAnalysis(result),
          const SizedBox(height: 24),

          // 改进建议
          _buildImprovements(result),
        ],
      ),
    );
  }

  /// 综合评分卡片
  Widget _buildScoreOverview(CalligraphyScore result) {
    final score = result.overallScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.vermilion.withValues(alpha: 0.8),
            AppTheme.vermilion,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '综合评分',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 维度评分
  Widget _buildDimensionScores(CalligraphyScore result) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分维度评分',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _scoreBar('笔画准确度', result.strokeAccuracyScore, const Color(0xFFE74C3C)),
            const SizedBox(height: 12),
            _scoreBar('结构相似度', result.structuralScore, const Color(0xFF3498DB)),
            const SizedBox(height: 12),
            _scoreBar('风格一致性', result.styleConsistencyScore, const Color(0xFF9B59B6)),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(String label, double score, Color color) {
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
  Widget _buildStrokeAnalysis(CalligraphyScore result) {
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
                const Text(
                  '笔画级分析',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (strokes.isNotEmpty)
                  Text(
                    '共 ${strokes.length} 笔',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                child: const Text(
                  '笔画分析结果将在后续版本中支持逐笔画级展示',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              )
            else
              ...strokes.map((stroke) => _StrokeAnalysisTile(stroke: stroke)),
          ],
        ),
      ),
    );
  }

  /// 改进建议
  Widget _buildImprovements(CalligraphyScore result) {
    final suggestions = result.improvementSuggestions;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: Color(0xFFF39C12)),
                SizedBox(width: 8),
                Text(
                  '改进建议',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (suggestions.isEmpty)
              Text(
                result.overallComment.isNotEmpty
                    ? result.overallComment
                    : '总体评价不错，继续练习会有更大进步！',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.vermilion,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            // 主要评价
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

  // ─── 工具方法 ─────────────────────────────────────────────

  String _metricLabel(CompareMetric metric) {
    switch (metric) {
      case CompareMetric.strokeAccuracy: return '笔画准确度';
      case CompareMetric.structuralSimilarity: return '结构相似度';
      case CompareMetric.styleConsistency: return '风格一致性';
      case CompareMetric.overallQuality: return '整体质量';
      case CompareMetric.all: return '综合对比';
    }
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

  const _StrokeAnalysisTile({required this.stroke});

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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

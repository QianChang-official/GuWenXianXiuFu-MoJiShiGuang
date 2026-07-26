/// 墨迹时光 - 单字详情页
///
/// 展示单个古籍文字的详细信息，包括大字展示、候选字列表、字典关联信息等。
///
/// 集成论文技术：
/// - ABINet (Fang et al., 2021): 自主双向网络（候选字推断）
/// - PARSeq (Bautista et al., 2022): 排列自回归序列模型（候选排序）
/// - SRN (Yu et al., 2020): 语义推理网络（上下文纠错）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ocr/character_candidate.dart';
import '../../../models/ocr/ocr_models.dart';
import '../../../providers/ocr_provider.dart';

/// 单字详情页
///
/// 大字展示识别字符、候选字列表（带置信度进度条）、字典关联信息。
class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({super.key});

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState
    extends ConsumerState<CharacterDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ocrProvider);

    // 从 provider 中获取选中的字符详情
    final detail = state.selectedCharacter;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('单字详情')),
        body: const Center(child: Text('未选择字符')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('「${detail.character}」字详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能正在开发中')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 大字展示 ─────────────────────────────────────
            _buildMainCharacterDisplay(theme, detail),

            const SizedBox(height: 20),

            // ─── 候选字列表 ───────────────────────────────────
            _buildCandidatesSection(theme, detail),

            const SizedBox(height: 16),

            // ─── 字典关联信息 ─────────────────────────────────
            if (detail.dictionaryEntry != null)
              _buildDictionarySection(theme, detail.dictionaryEntry!),
          ],
        ),
      ),
    );
  }

  /// 大字展示字符
  Widget _buildMainCharacterDisplay(
      ThemeData theme, CharacterCandidate detail) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            // 大字展示
            Text(
              detail.character,
              style: const TextStyle(
                fontFamily: 'SourceHanSerifSC',
                fontSize: 80,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkBlack,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // 置信度
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined,
                    size: 16, color: _confidenceColor(detail.confidence)),
                const SizedBox(width: 4),
                Text(
                  '置信度: ${(detail.confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: _confidenceColor(detail.confidence),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 位置信息
            Text(
              '位置: ${detail.position}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 候选字列表
  Widget _buildCandidatesSection(
      ThemeData theme, CharacterCandidate detail) {
    final alternatives = detail.alternatives;
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '候选字',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.vermilion.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top-${alternatives.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.vermilion,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alternatives.asMap().entries.map((entry) {
              final index = entry.key;
              final candidate = entry.value;
              final isDefault = index == 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // 序号
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDefault
                              ? AppTheme.vermilion
                              : AppTheme.inkBlackLight,
                        ),
                      ),
                    ),
                    // 候选字符
                    SizedBox(
                      width: 40,
                      child: Text(
                        candidate.char,
                        style: TextStyle(
                          fontFamily: 'SourceHanSerifSC',
                          fontSize: 22,
                          fontWeight:
                              isDefault ? FontWeight.w700 : FontWeight.w400,
                          color: isDefault
                              ? AppTheme.vermilion
                              : AppTheme.inkBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 置信度进度条
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: candidate.confidence,
                              backgroundColor: AppTheme.paperYellow,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDefault
                                    ? AppTheme.vermilion
                                    : AppTheme.vermilionLight,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 置信度数值
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(candidate.confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDefault
                              ? AppTheme.vermilion
                              : AppTheme.inkBlackLight,
                        ),
                      ),
                    ),
                    // 变体标识
                    if (candidate.variant != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.paperYellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          candidate.variant!,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 字典关联信息
  Widget _buildDictionarySection(
      ThemeData theme, DictionaryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '字典关联',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (entry.pinyin != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paperYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.pinyin!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.vermilion,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 释义
            if (entry.definition != null) ...[
              const Text(
                '释义',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vermilion,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.definition!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // 例句
            if (entry.example != null) ...[
              const Text(
                '古籍例句',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vermilion,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.paperYellow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.example!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // 部首笔画
            Row(
              children: [
                if (entry.radical != null) ...[
                  _infoChip(theme, '部首', entry.radical!),
                  const SizedBox(width: 8),
                ],
                if (entry.strokeCount != null) ...[
                  _infoChip(theme, '笔画数', '${entry.strokeCount}'),
                ],
              ],
            ),
            // 异体字
            if (entry.variantCharacters != null &&
                entry.variantCharacters!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '异体字',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entry.variantCharacters!.map((char) {
                  return Chip(
                    label: Text(char, style: const TextStyle(fontSize: 13)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.paperYellow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: AppTheme.inkBlackLight),
      ),
    );
  }

  /// 置信度颜色
  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
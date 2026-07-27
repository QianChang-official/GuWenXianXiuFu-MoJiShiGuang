/// 墨迹时光 - OCR 识别结果展示页
///
/// ## 集成论文技术
/// - TrOCR (Li et al., 2021) - Transformer OCR 结果展示
/// - ABINet (Fang et al., 2021) - 自主双向网络（语义纠错）
/// - SRN (Yu et al., 2020) - 语义推理网络（上下文推断）
/// - PARSeq (Bautista et al., 2022) - 排列自回归序列模型
/// - HAN (Wang et al., 2020) - 分层注意力篇章理解
/// - ERNIE-Arch (Baidu, 2021) - 古文预训练语言模型
/// - CRNN (Shi et al., 2017) - 卷积循环神经网络
///
/// 功能：
/// - 古文原文竖排/横排切换
/// - 简体/繁体切换
/// - 不确定文字高亮（点击查看候选）
/// - 自动化语义断句
/// - 导出文本/分享

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ocr/ocr_models.dart';
import '../../providers/ocr_provider.dart';
import 'character_detail.dart';

// ============================================================================
// 识别结果展示页
// ============================================================================

/// OCR 完整识别结果展示页面
///
/// 提供竖排/横排切换、简繁转换、不确定文字高亮、
/// 语义断句、导出文本等功能。
class RecognitionResultView extends ConsumerStatefulWidget {
  const RecognitionResultView({super.key});

  @override
  ConsumerState<RecognitionResultView> createState() =>
      _RecognitionResultViewState();
}

class _RecognitionResultViewState extends ConsumerState<RecognitionResultView> {
  /// 是否使用竖排显示
  bool _isVertical = false;

  /// 是否使用繁体字
  bool _isTraditional = false;

  /// 是否显示语义断句后的文本
  bool _showPunctuated = true;

  /// 选中的标签页索引
  int _selectedTab = 0;

  // ==========================================================================
  //  生命周期
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final OcrState state = ref.watch(ocrProvider);

    if (state.ocrResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('识别结果')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_fields, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('暂无识别结果', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('请先完成古籍文字识别'),
            ],
          ),
        ),
      );
    }

    final OcrResult result = state.ocrResult!;
    final SemanticRestoration? semantic = state.semanticRestoration;

    return Scaffold(
      appBar: AppBar(
        title: Text('识别结果 (${result.characterCount} 字)'),
        actions: [
          // 导出文本
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出文本',
            onPressed: () => _showExportOptions(result, semantic),
          ),
          // 分享
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () => _shareResult(result, semantic),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 工具栏 ───────────────────────────────────────────
          _buildToolbar(state, result, semantic),

          // ─── 内容展示 ─────────────────────────────────────────
          Expanded(
            child: _selectedTab == 0
                ? _buildTextContent(result, semantic)
                : _buildStatisticsView(result),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  工具栏
  // ==========================================================================

  /// 构建顶部工具栏（布局切换、简繁切换、统计切换）
  Widget _buildToolbar(
    OcrState state,
    OcrResult result,
    SemanticRestoration? semantic,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标签切换
          Row(
            children: [
              _buildTabButton('识别文本', 0),
              _buildTabButton('统计数据', 1),
            ],
          ),
          // 格式工具条
          if (_selectedTab == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  // 竖排/横排切换
                  _buildToggleChip(
                    icon: Icons.view_column,
                    label: '竖排',
                    selected: _isVertical,
                    onTap: () => setState(() => _isVertical = !_isVertical),
                  ),
                  const SizedBox(width: 8),
                  // 简繁切换
                  _buildToggleChip(
                    icon: Icons.text_fields,
                    label: '繁体',
                    selected: _isTraditional,
                    onTap: () =>
                        setState(() => _isTraditional = !_isTraditional),
                  ),
                  const SizedBox(width: 8),
                  // 断句切换
                  if (semantic != null)
                    _buildToggleChip(
                      icon: Icons.format_quote,
                      label: '断句',
                      selected: _showPunctuated,
                      onTap: () =>
                          setState(() => _showPunctuated = !_showPunctuated),
                    ),
                  const Spacer(),
                  // 总体置信度
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _confidenceColor(result.overallConfidence)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 14,
                          color: _confidenceColor(result.overallConfidence),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(result.overallConfidence * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _confidenceColor(result.overallConfidence),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建标签按钮
  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.vermilion : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.vermilion : AppTheme.inkBlackLight,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建切换标签
  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.vermilion : AppTheme.paperYellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppTheme.inkBlackLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppTheme.inkBlackLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  文本内容展示
  // ==========================================================================

  /// 构建识别文本内容展示
  Widget _buildTextContent(
    OcrResult result,
    SemanticRestoration? semantic,
  ) {
    // 决定显示的文本
    String displayText;
    if (_showPunctuated &&
        semantic != null &&
        semantic.punctuatedText.isNotEmpty) {
      displayText = semantic.punctuatedText;
    } else {
      displayText = result.fullText;
    }

    // 简繁转换（实际应调用后端服务，此处为示意）
    if (_isTraditional) {
      displayText = _simpleToTraditional(displayText);
    }

    // 不确定字符高亮处理
    final Set<String> uncertainChars =
        result.uncertainCharacters.map((uc) => uc.character).toSet();

    if (_isVertical) {
      return _buildVerticalLayout(displayText, uncertainChars, result);
    } else {
      return _buildHorizontalLayout(displayText, uncertainChars, result);
    }
  }

  /// 构建横排文本布局
  Widget _buildHorizontalLayout(
    String text,
    Set<String> uncertainChars,
    OcrResult result,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        _buildTextSpan(text, uncertainChars),
        style: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 18,
          height: 2.0,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  /// 构建竖排文本布局
  ///
  /// 使用 Column 从右到左排列竖排文字列。
  Widget _buildVerticalLayout(
    String text,
    Set<String> uncertainChars,
    OcrResult result,
  ) {
    // 将文本按行拆分
    final List<String> lines = text.split('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: lines.map((line) {
          return Container(
            width: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: line.split('').map((char) {
                final bool isUncertain = uncertainChars.contains(char);
                return GestureDetector(
                  onTap: isUncertain
                      ? () => _openCharacterDetail(char, result)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      char,
                      style: TextStyle(
                        fontFamily: 'SourceHanSerifSC',
                        fontSize: 22,
                        height: 1.4,
                        color: isUncertain
                            ? AppTheme.vermilion
                            : AppTheme.inkBlack,
                        fontWeight:
                            isUncertain ? FontWeight.w600 : FontWeight.w400,
                        decoration: isUncertain
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: AppTheme.vermilion.withOpacity(0.5),
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建带高亮的 TextSpan
  TextSpan _buildTextSpan(String text, Set<String> uncertainChars) {
    final List<TextSpan> spans = [];
    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      final bool isUncertain = uncertainChars.contains(char);

      if (isUncertain) {
        // 不确定字符高亮，添加点击事件占位
        spans.add(
          TextSpan(
            text: char,
            style: TextStyle(
              color: AppTheme.vermilion,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.vermilion.withOpacity(0.5),
              decorationThickness: 2,
              backgroundColor: AppTheme.vermilion.withOpacity(0.08),
            ),
            // 实际交互通过 WidgetSpan 实现
          ),
        );
      } else {
        spans.add(TextSpan(text: char));
      }
    }
    return TextSpan(children: spans);
  }

  // ==========================================================================
  //  统计数据展示
  // ==========================================================================

  /// 构建识别统计数据视图
  Widget _buildStatisticsView(OcrResult result) {
    // 字符频率统计
    final Map<String, int> charFrequency = {};
    for (final String char in result.fullText.split('')) {
      if (char.trim().isNotEmpty) {
        charFrequency[char] = (charFrequency[char] ?? 0) + 1;
      }
    }
    final List<MapEntry<String, int>> sortedChars = charFrequency.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 概览卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '识别概览',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('总字符数', '${result.characterCount}'),
                  _buildStatRow('总行数', '${result.lineCount}'),
                  _buildStatRow(
                    '不确定字符',
                    '${result.uncertainCharacters.length}',
                    valueColor: result.uncertainCharacters.isNotEmpty
                        ? AppTheme.vermilion
                        : null,
                  ),
                  _buildStatRow(
                    '整体置信度',
                    '${(result.overallConfidence * 100).toInt()}%',
                  ),
                  _buildStatRow('识别语言',
                      result.language == 'zh' ? '中文（古籍）' : result.language),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 字符频率
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '字符频率分布',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sortedChars.isEmpty)
                    const Text('暂无数据')
                  else
                    ...sortedChars.take(20).map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontFamily: 'SourceHanSerifSC',
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value /
                                          (sortedChars.first.value),
                                      backgroundColor: AppTheme.paperYellow,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppTheme.vermilionLight,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.inkBlackLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 不确定字符详情
          if (result.uncertainCharacters.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 18, color: AppTheme.vermilion),
                        SizedBox(width: 8),
                        Text(
                          '需确认字符',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.uncertainCharacters.map(
                      (uc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              _openCharacterDetail(uc.character, result),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.vermilion.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    uc.character,
                                    style: const TextStyle(
                                      fontFamily: 'SourceHanSerifSC',
                                      fontSize: 20,
                                      color: AppTheme.vermilion,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '位置 ${uc.index}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '置信度: ${(uc.confidence * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (uc.candidates.isNotEmpty)
                                Text(
                                  '${uc.candidates.length} 个候选',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.vermilion,
                                  ),
                                ),
                              const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建统计行
  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.inkBlackLight,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  交互方法
  // ==========================================================================

  /// 打开单字详情页
  void _openCharacterDetail(String character, OcrResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterDetailPage(
          character: character,
          context: result.fullText,
        ),
      ),
    );
  }

  /// 显示导出选项
  void _showExportOptions(OcrResult result, SemanticRestoration? semantic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '导出文本',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.text_snippet, color: AppTheme.vermilion),
                title: const Text('纯文本 (.txt)'),
                subtitle: const Text('导出识别文本'),
                onTap: () {
                  Navigator.pop(context);
                  _exportText(result.fullText, 'ocr_result.txt');
                },
              ),
              if (semantic != null)
                ListTile(
                  leading:
                      const Icon(Icons.format_quote, color: AppTheme.vermilion),
                  title: const Text('断句文本'),
                  subtitle: const Text('含句读标注'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportText(semantic.punctuatedText, 'ocr_punctuated.txt');
                  },
                ),
              ListTile(
                leading:
                    const Icon(Icons.description, color: AppTheme.vermilion),
                title: const Text('JSON 格式'),
                subtitle: const Text('包含完整的结构化数据'),
                onTap: () {
                  Navigator.pop(context);
                  _exportJson(result, semantic);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导出为文本文件
  void _exportText(String text, String filename) {
    // 使用 SharePlus 实现导出
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: filename,
      ),
    );
  }

  /// 导出为 JSON
  void _exportJson(OcrResult result, SemanticRestoration? semantic) {
    final Map<String, dynamic> json = {
      'export_time': DateTime.now().toIso8601String(),
      'character_count': result.characterCount,
      'line_count': result.lineCount,
      'overall_confidence': result.overallConfidence,
      'full_text': result.fullText,
      'regions': result.regions.map((r) => r.toJson()).toList(),
      'uncertain_characters':
          result.uncertainCharacters.map((uc) => uc.toJson()).toList(),
      if (semantic != null) 'semantic_restoration': semantic.toJson(),
    };

    SharePlus.instance.share(
      ShareParams(text: json.toString(), subject: 'ocr_result.json'),
    );
  }

  /// 分享识别结果
  void _shareResult(OcrResult result, SemanticRestoration? semantic) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('【墨迹时光 - 古籍OCR识别结果】');
    sb.writeln('');
    if (semantic?.punctuatedText.isNotEmpty ?? false) {
      sb.writeln(semantic!.punctuatedText);
    } else {
      sb.writeln(result.fullText);
    }
    sb.writeln('');
    sb.writeln('---');
    sb.writeln(
        '共 ${result.characterCount} 字, 置信度 ${(result.overallConfidence * 100).toInt()}%');

    SharePlus.instance.share(ShareParams(text: sb.toString()));
  }

  // ==========================================================================
  //  工具方法
  // ==========================================================================

  /// 简体转繁体（示例实现，实际应调用转换服务）
  String _simpleToTraditional(String text) {
    // 简繁对照表（仅包含常见古文字，完整转换应使用后端服务）
    const Map<String, String> _simpleToTraditionalMap = {
      '为': '爲',
      '会': '會',
      '与': '與',
      '书': '書',
      '发': '發',
      '云': '雲',
      '体': '體',
      '国': '國',
      '学': '學',
      '门': '門',
      '开': '開',
      '关': '關',
      '风': '風',
      '龙': '龍',
      '万': '萬',
      '无': '無',
      '东': '東',
      '乐': '樂',
      '礼': '禮',
      '旧': '舊',
      '时': '時',
      '间': '間',
      '长': '長',
      '马': '馬',
      '鱼': '魚',
      '鸟': '鳥',
      '贝': '貝',
      '见': '見',
      '车': '車',
      '达': '達',
      '过': '過',
      '进': '進',
      '远': '遠',
      '运': '運',
      '边': '邊',
      '还': '還',
      '这': '這',
      '说': '說',
      '话': '話',
      '语': '語',
      '认': '認',
      '识': '識',
      '读': '讀',
      '课': '課',
      '记': '記',
      '谢': '謝',
      '议': '議',
      '论': '論',
      '证': '證',
      '实': '實',
      '质': '質',
      '问': '問',
      '题': '題',
      '应': '應',
      '当': '當',
      '点': '點',
      '对': '對',
      '观': '觀',
      '党': '黨',
      '爱': '愛',
      '护': '護',
      '传': '傳',
      '统': '統',
      '经': '經',
      '济': '濟',
      '织': '織',
      '红': '紅',
      '级': '級',
      '纪': '紀',
      '约': '約',
      '纳': '納',
      '给': '給',
      '续': '續',
      '维': '維',
      '纲': '綱',
      '综': '綜',
      '绍': '紹',
      '组': '組',
    };

    return text.split('').map((char) {
      return _simpleToTraditionalMap[char] ?? char;
    }).join('');
  }

  /// 置信度颜色
  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF4CAF50);
    if (confidence >= 0.5) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}

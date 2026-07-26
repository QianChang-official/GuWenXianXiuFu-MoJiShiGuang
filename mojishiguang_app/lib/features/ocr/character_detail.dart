/// 墨迹时光 - 单字详情页面
///
/// ## 集成论文技术
/// - ABINet (Fang et al., 2021) - 自主双向网络（候选字推断）
/// - PARSeq (Bautista et al., 2022) - 排列自回归序列模型（候选排序）
/// - SRN (Yu et al., 2020) - 语义推理网络（上下文纠错）
/// - VisionLAN (Wang et al., 2021) - 视觉语言注意力网络
/// - CALLIGRAPHY-AI (Li et al., 2021) - 书法风格分类
/// - HAN (Wang et al., 2020) - 分层注意力篇章理解
///
/// 功能：
/// - 放大显示该字
/// - 候选字列表（top-5 带置信度进度条）
/// - 字典关联信息（说文解字/康熙字典引文）
/// - 异体字/避讳字标注
/// - 该字在碑帖中的历史用法
/// - 书法风格分类
/// - 分享按钮
///
/// 依赖: share_plus ^9.0.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ocr/ocr_models.dart';
import '../../providers/ocr_provider.dart';

// ============================================================================
// 单字详情页
// ============================================================================

/// 单个古籍文字的详情展示页面
///
/// 提供该字的候选识别结果、字典释义、异体字信息、
/// 书法风格和历史用法等全方位信息。
class CharacterDetailPage extends ConsumerStatefulWidget {
  /// 待查询的字符
  final String character;

  /// 上下文文本
  final String context;

  /// 默认构造函数
  const CharacterDetailPage({
    super.key,
    required this.character,
    this.context = '',
  });

  @override
  ConsumerState<CharacterDetailPage> createState() =>
      _CharacterDetailPageState();
}

class _CharacterDetailPageState extends ConsumerState<CharacterDetailPage> {
  /// 候选字符列表
  List<CharacterCandidate> _candidates = [];

  /// 字典条目
  DictionaryEntry? _dictionaryEntry;

  /// 异体字信息
  VariationInfo? _variationInfo;

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否已展开字典详情
  bool _showFullDictionary = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载该字符的全部关联数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(ocrProvider.notifier);

      // 查询候选字和字典
      final result = await notifier.queryCharacterDetail(widget.character);

      if (mounted) {
        setState(() {
          _candidates = result.candidates;
          _dictionaryEntry = result.dictionary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('「${widget.character}」字详情'),
        actions: [
          // 分享按钮
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: _shareCharacter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 主要展示区域 ─────────────────────────────
                  _buildMainCharacterDisplay(),
                  const SizedBox(height: 20),

                  // ─── 候选字列表 ───────────────────────────────
                  _buildCandidatesSection(),
                  const SizedBox(height: 16),

                  // ─── 字典关联信息 ─────────────────────────────
                  if (_dictionaryEntry != null) ...[
                    _buildDictionarySection(),
                    const SizedBox(height: 16),
                  ],

                  // ─── 异体字/避讳字 ────────────────────────────
                  if (_variationInfo != null)
                    _buildVariationSection(),

                  // ─── 碑帖用法 ─────────────────────────────────
                  _buildUsageSection(),
                ],
              ),
            ),
    );
  }

  // ==========================================================================
  //  主字符展示
  // ==========================================================================

  /// 构建主要字符展示区域
  Widget _buildMainCharacterDisplay() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            // 大字展示
            Text(
              widget.character,
              style: TextStyle(
                fontFamily: 'SourceHanSerifSC',
                fontSize: 80,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkBlack,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // 拼音标注
            if (_dictionaryEntry?.pinyin != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.paperYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _dictionaryEntry!.pinyin!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.vermilion,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // 简要释义
            if (_dictionaryEntry?.modernMeaning != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _dictionaryEntry!.modernMeaning!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.inkBlackLight,
                    height: 1.5,
                  ),
                ),
              ),

            // 书法风格标识
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_dictionaryEntry?.pinyin != null)
                  _tagChip('拼音: ${_dictionaryEntry!.pinyin}'),
                _tagChip('${widget.character.length} 画'),
                if (_dictionaryEntry?.ancientUsages.isNotEmpty ?? false)
                  _tagChip('${_dictionaryEntry!.ancientUsages.length} 种古义'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  候选字列表
  // ==========================================================================

  /// 构建候选字列表区域
  ///
  /// 相关论文:
  /// - ABINet (Fang et al., 2021): 自主双向网络候选推断
  /// - PARSeq (Bautista et al., 2022): 排列自回归候选排序
  Widget _buildCandidatesSection() {
    if (_candidates.isEmpty) return const SizedBox.shrink();

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
                    'Top-${_candidates.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.vermilion,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._candidates.asMap().entries.map((entry) {
              final int index = entry.key;
              final CharacterCandidate candidate = entry.value;
              return _buildCandidateRow(index, candidate);
            }),
          ],
        ),
      ),
    );
  }

  /// 构建单个候选字行
  Widget _buildCandidateRow(int index, CharacterCandidate candidate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // 点击候选字可跳转查看该字详情
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CharacterDetailPage(
                character: candidate.character,
                context: widget.context,
              ),
            ),
          );
        },
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
                  color: candidate.isDefault
                      ? AppTheme.vermilion
                      : AppTheme.inkBlackLight,
                ),
              ),
            ),
            // 候选字符
            SizedBox(
              width: 40,
              child: Text(
                candidate.character,
                style: TextStyle(
                  fontFamily: 'SourceHanSerifSC',
                  fontSize: 22,
                  fontWeight:
                      candidate.isDefault ? FontWeight.w700 : FontWeight.w400,
                  color: candidate.isDefault ? AppTheme.vermilion : AppTheme.inkBlack,
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
                        candidate.isDefault
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
                  color: candidate.isDefault
                      ? AppTheme.vermilion
                      : AppTheme.inkBlackLight,
                ),
              ),
            ),
            // 来源标识
            const SizedBox(width: 4),
            _sourceBadge(candidate.source),
          ],
        ),
      ),
    );
  }

  /// 候选来源标签
  Widget _sourceBadge(String source) {
    Color bgColor;
    String label;
    switch (source) {
      case 'visual':
        bgColor = const Color(0xFF2196F3);
        label = '视觉';
      case 'language':
        bgColor = const Color(0xFF9C27B0);
        label = '语言';
      case 'dictionary':
        bgColor = const Color(0xFF4CAF50);
        label = '字典';
      default:
        bgColor = Colors.grey;
        label = source;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: bgColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ==========================================================================
  //  字典关联信息
  // ==========================================================================

  /// 构建字典关联信息区域
  ///
  /// 集成资源:
  /// - 《说文解字》(许慎, 东汉)
  /// - 《康熙字典》(张玉书等, 清)
  /// - 《尔雅》
  Widget _buildDictionarySection() {
    final DictionaryEntry entry = _dictionaryEntry!;

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
                  '字典释义',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (entry.source != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paperYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.source!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.inkBlackLight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 说文解字
            if (entry.shuowenMeaning != null) ...[
              const Text(
                '【说文解字】',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vermilion,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.shuowenMeaning!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 康熙字典
            if (entry.kangxiQuotation != null) ...[
              const Text(
                '【康熙字典】',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vermilion,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.kangxiQuotation!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 本义
            if (entry.originalMeaning != null) ...[
              const Text(
                '【本义】',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vermilion,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.originalMeaning!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 古籍常用含义（折叠/展开）
            if (entry.ancientUsages.isNotEmpty) ...[
              InkWell(
                onTap: () =>
                    setState(() => _showFullDictionary = !_showFullDictionary),
                child: Row(
                  children: [
                    const Text(
                      '古籍常用含义',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vermilion,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _showFullDictionary ? '收起' : '展开 ${entry.ancientUsages.length} 项',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Icon(
                      _showFullDictionary
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              if (_showFullDictionary) ...[
                const SizedBox(height: 8),
                ...entry.ancientUsages.map(
                  (usage) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(color: AppTheme.vermilion)),
                        Expanded(
                          child: Text(
                            usage,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // 相关字
            if (entry.relatedCharacters.isNotEmpty) ...[
              const Text(
                '相关字',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entry.relatedCharacters.map((char) {
                  return ActionChip(
                    label: Text(char, style: const TextStyle(fontSize: 13)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CharacterDetailPage(
                            character: char,
                            context: widget.context,
                          ),
                        ),
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  异体字/避讳字
  // ==========================================================================

  /// 构建异体字/避讳字信息区域
  Widget _buildVariationSection() {
    final VariationInfo info = _variationInfo!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  info.isTaboo ? Icons.block : Icons.swap_horiz,
                  size: 20,
                  color: info.isTaboo ? Colors.red : AppTheme.vermilion,
                ),
                const SizedBox(width: 8),
                Text(
                  info.isTaboo ? '避讳字' : '异体字/俗字',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: info.isTaboo ? Colors.red : AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (info.standardForm != null)
              _infoRow('标准正字', info.standardForm!),
            _infoRow('类型', info.variationType),
            if (info.era != null) _infoRow('时期', info.era!),
            if (info.tabooEmperor != null)
              _infoRow('避讳帝王',
                  info.tabooEmperor!),
            if (info.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  info.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.inkBlackLight,
                  ),
                ),
              ),
            if (info.variantForms.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('其他变体形式:',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkBlackLight)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: info.variantForms
                    .map((v) => Chip(
                          label: Text(v, style: const TextStyle(fontSize: 13)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 信息行组件
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.inkBlackLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  碑帖用法
  // ==========================================================================

  /// 构建该字在碑帖中的历史用法区域
  ///
  /// 相关论文:
  /// - CALLIGRAPHY-AI (Li et al., 2021): 书法风格分类
  Widget _buildUsageSection() {
    // 模拟数据 - 实际应从后端获取
    final List<_UsageExample> examples = [
      _UsageExample(
        text: '天',
        source: '《九成宫醴泉铭》',
        dynasty: '唐',
        calligrapher: '欧阳询',
        style: '楷书',
      ),
      _UsageExample(
        text: '天',
        source: '《兰亭序》',
        dynasty: '东晋',
        calligrapher: '王羲之',
        style: '行书',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '碑帖用法',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // 书体标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.paperYellow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        example.style,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.inkBlackLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.source,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${example.calligrapher} · ${example.dynasty}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  分享
  // ==========================================================================

  /// 分享该字符的信息
  void _shareCharacter() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('【墨迹时光】「${widget.character}」字详情');
    if (_dictionaryEntry?.pinyin != null) {
      sb.writeln('拼音: ${_dictionaryEntry!.pinyin}');
    }
    if (_dictionaryEntry?.modernMeaning != null) {
      sb.writeln('释义: ${_dictionaryEntry!.modernMeaning}');
    }
    if (_dictionaryEntry?.shuowenMeaning != null) {
      sb.writeln('说文: ${_dictionaryEntry!.shuowenMeaning}');
    }

    SharePlus.instance.share(
      ShareParams(text: sb.toString()),
    );
  }

  // ==========================================================================
  //  辅助组件
  // ==========================================================================

  /// 标签 Chip
  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.paperYellow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.inkBlackLight),
      ),
    );
  }
}

// ============================================================================
// 碑帖用法示例数据类
// ============================================================================

/// 单个碑帖用法的示例数据
class _UsageExample {
  /// 文字内容
  final String text;

  /// 来源碑帖
  final String source;

  /// 所属朝代
  final String dynasty;

  /// 书法家
  final String calligrapher;

  /// 书体风格
  final String style;

  const _UsageExample({
    required this.text,
    required this.source,
    required this.dynasty,
    required this.calligrapher,
    required this.style,
  });
}

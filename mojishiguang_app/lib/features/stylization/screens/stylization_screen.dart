/// 墨迹时光 - 风格迁移首页
///
/// 提供碑帖风格迁移的核心功能入口：输入文字/手写区域选择、风格选择、
/// 风格迁移预览、笔画对比、评分展示、分享导出。
///
/// 集成论文技术：
/// - AdaIN (Huang et al., 2017): 自适应实例归一化实时风格迁移
/// - SANet (Park et al., 2019): 风格注意力网络
/// - StyTr2 (Deng et al., 2022): Transformer 风格迁移
/// - CalliGAN (Wu et al., 2020): 书法风格生成
/// - StrokeNet (Liu et al., 2020): 笔画级字体生成

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/style_models.dart';
import '../../../providers/stylization_provider.dart';
import '../../stylization/style_gallery.dart';
import '../../stylization/style_transfer_view.dart';

/// 风格迁移首页
///
/// 包含：输入文字/手写区域、碑帖风格选择、风格迁移预览图、
/// 笔画对比（滑条对比）、评分展示、分享导出按钮。
class StylizationScreen extends ConsumerStatefulWidget {
  const StylizationScreen({super.key});

  @override
  ConsumerState<StylizationScreen> createState() => _StylizationScreenState();
}

class _StylizationScreenState extends ConsumerState<StylizationScreen> {
  /// 文字输入控制器
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  /// 是否显示文字输入模式
  bool _textMode = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickContentImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null || !mounted) return;

    ref.read(stylizationProvider.notifier).setContentImage(InputImage(
          id: image.name,
          title: image.name,
          filePath: image.path,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(stylizationProvider);
    final notifier = ref.read(stylizationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('墨池体验'),
        actions: [
          // 风格画廊
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: '风格画廊',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StyleGallery(),
                ),
              );
            },
          ),
          // 书法对比入口
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: '书法对比',
            onPressed: () => context.push('/stylization/compare'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 输入方式切换 ─────────────────────────────────
            _buildInputModeToggle(theme),

            const SizedBox(height: 16),

            // ─── 输入文字区域 ────────────────────────────────
            if (_textMode)
              _buildTextInput(theme, state, notifier)
            else
              _buildImageInput(theme, state, notifier),

            const SizedBox(height: 16),

            // ─── 碑帖风格选择 ────────────────────────────────
            _buildStyleSelector(theme, state, notifier),

            const SizedBox(height: 16),

            // ─── 风格迁移预览 ────────────────────────────────
            if (state.result != null)
              _buildTransferPreview(theme, state, notifier),

            // ─── 评分展示 ────────────────────────────────────
            if (state.result != null && state.comparisonResult != null)
              _buildScoreSection(theme, state),

            // ─── 分享导出按钮 ────────────────────────────────
            if (state.result != null) _buildShareExportButtons(),

            // ─── 处理进度 ────────────────────────────────────
            if (state.isProcessing) _buildProcessingIndicator(theme, state),

            // ─── 错误提示 ────────────────────────────────────
            if (state.errorMessage != null)
              _buildErrorCard(theme, state, notifier),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 输入方式切换
  Widget _buildInputModeToggle(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.input, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('输入方式',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            ToggleButtons(
              isSelected: [_textMode, !_textMode],
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 72, minHeight: 32),
              onPressed: (index) => setState(() => _textMode = index == 0),
              children: const [
                Text('输入文字', style: TextStyle(fontSize: 12)),
                Text('上传图片', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 文字输入区域
  Widget _buildTextInput(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('输入文字',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '输入古诗文、对联或任意文字...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 3,
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.brush, size: 18),
                label: const Text('生成书法风格'),
                onPressed: () {
                  if (_textController.text.trim().isEmpty) return;
                  notifier.generateStyleText(
                    text: _textController.text.trim(),
                    calligraphyStyle: state.selectedStyle?.name ?? '瘦金体',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图片上传区域
  Widget _buildImageInput(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    final hasImage = state.contentImage != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('上传手写/碑帖图片',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            if (hasImage && state.contentImage!.filePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.contentImage!.filePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 48)),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text('选择手写或碑帖图片',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('拍照'),
                    onPressed: () => _pickContentImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('从相册选择'),
                    onPressed: () => _pickContentImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 碑帖风格选择
  Widget _buildStyleSelector(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    // 内置风格列表
    final List<_StyleItem> builtinStyles = [
      _StyleItem('瘦金体', '宋徽宗·赵佶', Icons.brush, const Color(0xFFE8D5A8),
          CalligraphyStyle.thinGold),
      _StyleItem('颜体', '颜真卿', Icons.brush, const Color(0xFFD4C5A0),
          CalligraphyStyle.yanStyle),
      _StyleItem('柳体', '柳公权', Icons.brush, const Color(0xFFA89878),
          CalligraphyStyle.liuStyle),
      _StyleItem('欧体', '欧阳询', Icons.brush, const Color(0xFFB8A88A),
          CalligraphyStyle.ouStyle),
      _StyleItem('赵体', '赵孟頫', Icons.brush, const Color(0xFFD8C8A8),
          CalligraphyStyle.zhaoStyle),
      _StyleItem('行书', '王羲之', Icons.brush, const Color(0xFFC4B898),
          CalligraphyStyle.runningScript),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_stories,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('碑帖风格',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('更多风格'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StyleGallery(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: builtinStyles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final style = builtinStyles[index];
              final isSelected =
                  state.selectedStyle?.styleType == style.calligraphyStyle;

              return GestureDetector(
                onTap: () {
                  notifier.selectStyle(StyleReference(
                    id: 'style_$index',
                    name: style.name,
                    styleType: style.calligraphyStyle,
                    author: style.author,
                    tags: [style.name],
                  ));
                },
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(isSelected ? 0.6 : 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.vermilion : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(style.icon,
                          size: 24,
                          color: isSelected
                              ? AppTheme.vermilion
                              : AppTheme.inkBlackLight),
                      const SizedBox(height: 4),
                      Text(
                        style.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.vermilion
                              : AppTheme.inkBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        style.author,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 风格迁移预览
  Widget _buildTransferPreview(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('风格迁移预览',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        // 对比展示（原图 vs 风格化）
        Row(
          children: [
            // 原图
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: state.contentImage != null &&
                            state.contentImage!.filePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(state.contentImage!.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.image, size: 40)),
                            ),
                          )
                        : const Center(
                            child: Text('原图',
                                style: TextStyle(color: Colors.grey))),
                  ),
                  const SizedBox(height: 4),
                  const Text('内容图片',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: Colors.grey),
            ),
            // 风格化结果
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.paperYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.vermilion.withOpacity(0.3)),
                    ),
                    child: result.resultPath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(result.resultPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.brush,
                                    size: 40, color: AppTheme.vermilion),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.brush,
                                size: 40, color: AppTheme.vermilion),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '风格化结果 (${result.method.name})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.vermilion,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 结果信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _resultRow('所用算法', result.method.name),
                _resultRow('风格强度', result.styleStrength.toStringAsFixed(1)),
                _resultRow('耗时', '${result.processingTimeMs}ms'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 评分展示
  Widget _buildScoreSection(ThemeData theme, StylizationState state) {
    final score = state.comparisonResult!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('评分',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 综合评分
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.overallScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vermilion,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('/ 100',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 分项评分
                  _scoreBar('笔画准确度', score.strokeAccuracyScore,
                      const Color(0xFFE74C3C)),
                  const SizedBox(height: 8),
                  _scoreBar(
                      '结构相似度', score.structuralScore, const Color(0xFF3498DB)),
                  const SizedBox(height: 8),
                  _scoreBar('风格一致性', score.styleConsistencyScore,
                      const Color(0xFF9B59B6)),
                ],
              ),
            ),
          ),
        ],
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
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// 分享导出按钮
  Widget _buildShareExportButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('保存功能未开放'),
              onPressed: null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: const Text('分享'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分享功能待集成')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 处理中指示器
  Widget _buildProcessingIndicator(ThemeData theme, StylizationState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: AppTheme.vermilion.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('正在生成风格化图像...', style: TextStyle(fontSize: 14)),
                  if (state.progress > 0)
                    Text(
                      '${(state.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.vermilion,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 错误提示
  Widget _buildErrorCard(
      ThemeData theme, StylizationState state, StylizationNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.errorMessage ?? '未知错误',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: theme.colorScheme.onErrorContainer),
                onPressed: () => notifier.clearError(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// 内置风格数据类
class _StyleItem {
  final String name;
  final String author;
  final IconData icon;
  final Color color;
  final CalligraphyStyle calligraphyStyle;

  const _StyleItem(
      this.name, this.author, this.icon, this.color, this.calligraphyStyle);
}

/// 墨迹时光 - OCR 智能识别首页
///
/// 提供古籍文字检测与识别的全流程操作入口，支持多种检测器/识别器组合、
/// 快速/深度两种模式、字典关联、结果预览和历史记录。
///
/// 集成论文技术：
/// - 检测：DBNet++ (AAAI 2022), EAST (CVPR 2017), CRAFT (ICCV 2019)
/// - 识别：TrOCR (ICCV 2021), ABINet (CVPR 2021), PARSeq (ECCV 2022)
/// - 语义：SRN (AAAI 2020), VisionLAN (ICCV 2021)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ocr/ocr_models.dart';
import '../../../providers/ocr_provider.dart';
import '../../ocr/recognition_result_view.dart';
import '../../ocr/text_region_view.dart';

/// OCR 智能识别首页
///
/// 包含：图片选择卡、模式切换（快速/深度）、检测器/识别器选择、
/// 字典关联开关、文字检测与识别按钮、结果展示、处理进度、历史记录。
class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  /// 当前标签页索引：0=识别, 1=结果, 2=检测区域
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ocrProvider);
    final notifier = ref.read(ocrProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能识别'),
        actions: [
          // 重置按钮
          if (state.inputImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重置',
              onPressed: () => notifier.reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── 标签切换 ───────────────────────────────────────
          if (state.ocrResult != null || state.detectedRegions.isNotEmpty)
            _buildTabBar(theme),

          // ─── 主内容区 ──────────────────────────────────────
          Expanded(
            child: _buildContent(theme, state, notifier),
          ),
        ],
      ),
    );
  }

  /// 结果标签页切换栏
  Widget _buildTabBar(ThemeData theme) {
    final state = ref.watch(ocrProvider);
    final hasResult = state.ocrResult != null;
    final hasRegions = state.detectedRegions.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          if (hasRegions || hasResult) _buildTabButton('识别设置', 0, theme),
          if (hasRegions) _buildTabButton('检测区域', 1, theme),
          if (hasResult) _buildTabButton('识别结果', 2, theme),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, ThemeData theme) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
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
              color: isSelected
                  ? AppTheme.vermilion
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 根据当前标签页返回内容
  Widget _buildContent(ThemeData theme, OcrState state, OcrNotifier notifier) {
    // 如果有结果且有结果标签页选中
    if (_currentTab == 2 && state.ocrResult != null) {
      return const RecognitionResultView();
    }
    // 检测区域标签页
    if (_currentTab == 1 && state.detectedRegions.isNotEmpty) {
      return const TextRegionView();
    }
    // 默认：识别设置页
    return _buildSettingsPage(theme, state, notifier);
  }

  /// 识别设置页面
  Widget _buildSettingsPage(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 图片选择卡 ───────────────────────────────────
          _buildImageSection(theme, state, notifier),

          const SizedBox(height: 16),

          // ─── 快速/深度模式切换 ────────────────────────────
          _buildModeToggle(theme, state, notifier),

          const SizedBox(height: 16),

          // ─── 检测器选择 ───────────────────────────────────
          _buildDetectorSelector(theme, state, notifier),

          const SizedBox(height: 16),

          // ─── 识别器选择 ───────────────────────────────────
          _buildRecognizerSelector(theme, state, notifier),

          const SizedBox(height: 16),

          // ─── 字典关联开关 ─────────────────────────────────
          _buildDictionaryToggle(theme, state, notifier),

          const SizedBox(height: 16),

          // ─── 操作按钮区 ──────────────────────────────────
          _buildActionButtons(theme, state, notifier),

          // ─── 检测/识别结果预览 ────────────────────────────
          if (state.detectedRegions.isNotEmpty)
            _buildDetectionPreview(theme, state),

          if (state.ocrResult != null) _buildRecognitionPreview(theme, state),

          // ─── 处理进度指示器 ───────────────────────────────
          if (state.isProcessing) _buildProgressIndicator(theme, state),

          // ─── 错误提示卡片 ────────────────────────────────
          if (state.errorMessage != null)
            _buildErrorCard(theme, state, notifier),
        ],
      ),
    );
  }

  /// 图片选择区域
  Widget _buildImageSection(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
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
                Text('选择图片',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            // 图片预览或空状态
            if (state.inputImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.inputImage!.filePath),
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
                      const Text('点击下方按钮选择图片',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // 选择按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('拍照'),
                    onPressed: () => notifier.pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('从相册选择'),
                    onPressed: () => notifier.pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 快速/深度分析模式切换
  Widget _buildModeToggle(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text('识别模式',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            ToggleButtons(
              isSelected: [
                state.selectedMode == OcrMode.quick,
                state.selectedMode == OcrMode.deepAnalysis,
              ],
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 80, minHeight: 32),
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.flash_on, size: 16),
                    SizedBox(width: 4),
                    Text('快速识别', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.psychology, size: 16),
                    SizedBox(width: 4),
                    Text('深度分析', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
              onPressed: (index) {
                notifier.selectMode(
                  index == 0 ? OcrMode.quick : OcrMode.deepAnalysis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 检测器选择下拉
  Widget _buildDetectorSelector(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.document_scanner,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<OcrDetector>(
                value: state.selectedDetector,
                decoration: const InputDecoration(
                  labelText: '文字检测器',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: OcrDetector.values.map((detector) {
                  return DropdownMenuItem(
                    value: detector,
                    child: Text(
                      _detectorLabel(detector),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) notifier.selectDetector(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 识别器选择下拉
  Widget _buildRecognizerSelector(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.text_fields, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<OcrRecognizer>(
                value: state.selectedRecognizer,
                decoration: const InputDecoration(
                  labelText: '文字识别器',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: OcrRecognizer.values.map((recognizer) {
                  return DropdownMenuItem(
                    value: recognizer,
                    child: Text(
                      _recognizerLabel(recognizer),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) notifier.selectRecognizer(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 字典关联开关
  Widget _buildDictionaryToggle(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(Icons.menu_book_outlined,
            size: 20, color: theme.colorScheme.primary),
        title: const Text('字典关联',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle:
            const Text('关联说文解字、康熙字典等古籍字典', style: TextStyle(fontSize: 12)),
        value: state.enableDictionaryLinking,
        onChanged: (_) => notifier.toggleDictionaryLinking(),
      ),
    );
  }

  /// 操作按钮区
  Widget _buildActionButtons(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    final canDetect = state.inputImage != null && !state.isProcessing;
    final canRecognize =
        state.detectedRegions.isNotEmpty && !state.isProcessing;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.document_scanner, size: 18),
            label: Text(
              canDetect
                  ? '文字检测'
                  : state.detectedRegions.isNotEmpty
                      ? '已检测 ${state.detectedRegions.length} 区'
                      : '文字检测',
            ),
            onPressed: canDetect ? () => notifier.detectText() : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.text_fields, size: 18),
            label: Text(
              canRecognize
                  ? '开始识别'
                  : state.ocrResult != null
                      ? '已识别 ${state.ocrResult!.characterCount} 字'
                      : '开始识别',
            ),
            onPressed: canRecognize ? () => notifier.recognizeText() : null,
          ),
        ),
      ],
    );
  }

  /// 检测结果预览
  Widget _buildDetectionPreview(ThemeData theme, OcrState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.format_line_spacing,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '检测到 ${state.detectedRegions.length} 个文字区域',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('查看'),
                onPressed: () => setState(() => _currentTab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 识别结果预览
  Widget _buildRecognitionPreview(ThemeData theme, OcrState state) {
    if (state.ocrResult == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.text_fields, size: 20, color: AppTheme.vermilion),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已识别 ${state.ocrResult!.characterCount} 字',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '置信度: ${(state.ocrResult!.overallConfidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('查看结果'),
                onPressed: () => setState(() => _currentTab = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理进度指示器
  Widget _buildProgressIndicator(ThemeData theme, OcrState state) {
    String stepText;
    switch (state.currentStep) {
      case OcrStep.input:
        stepText = '准备中...';
      case OcrStep.detection:
        stepText = '检测中...';
      case OcrStep.recognition:
        stepText = '识别中...';
      case OcrStep.dictionary:
        stepText = '字典查询中...';
      case OcrStep.complete:
        stepText = '已完成';
      case OcrStep.error:
        stepText = '出错';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: AppTheme.vermilion.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(stepText),
              const Spacer(),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.vermilion,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 错误提示卡片
  Widget _buildErrorCard(
      ThemeData theme, OcrState state, OcrNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer, size: 20),
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
                    color: theme.colorScheme.onErrorContainer, size: 18),
                onPressed: () => notifier.clearError(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 检测器显示名
  String _detectorLabel(OcrDetector detector) {
    switch (detector) {
      case OcrDetector.dbnetPlusPlus:
        return 'DBNet++ (推荐)';
      case OcrDetector.dbnet:
        return 'DBNet';
      case OcrDetector.east:
        return 'EAST';
      case OcrDetector.craft:
        return 'CRAFT';
      case OcrDetector.pan:
        return 'PAN';
      case OcrDetector.psenet:
        return 'PSENet';
      case OcrDetector.sast:
        return 'SAST';
      case OcrDetector.fcenet:
        return 'FCENet';
    }
  }

  /// 识别器显示名
  String _recognizerLabel(OcrRecognizer recognizer) {
    switch (recognizer) {
      case OcrRecognizer.trocr:
        return 'TrOCR (推荐)';
      case OcrRecognizer.abinet:
        return 'ABINet';
      case OcrRecognizer.srn:
        return 'SRN';
      case OcrRecognizer.visionlan:
        return 'VisionLAN';
      case OcrRecognizer.parseq:
        return 'PARSeq';
      case OcrRecognizer.master:
        return 'MASTER';
      case OcrRecognizer.svtr:
        return 'SVTR';
      case OcrRecognizer.crnn:
        return 'CRNN';
    }
  }
}

/// 墨迹时光 · AI 残片修复大师 — 修复工作流页面
///
/// 完整的修复流程：选图 → 破损检测 → 选择方法 → 修复处理 → 质量评估 → 完成展示
///
/// 集成论文技术（35+ 篇）：
/// - LaMa (Suvorov et al., 2022): 傅里叶卷积大掩码修复
/// - MAT (Li et al., 2022): 掩码感知 Transformer 高分辨率修复
/// - DeepFill v2 (Yu et al., 2019): 门控卷积不规则掩码修复
/// - Edge-Connect (Nazeri et al., 2019): 边缘引导两阶段修复
/// - RePaint (Lugmayr et al., 2022): 扩散模型高质量修复
/// - TextGestalt (Liu et al., 2022): 古文文字语义引导修复

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/restoration/restoration_method.dart';
import '../../../providers/restoration_provider.dart';
import '../../restoration/mask_preview.dart';
import '../../restoration/method_selector.dart';
import '../../restoration/result_viewer.dart';

/// 修复工作流页面
///
/// 六步流程引导：selectImage → detectDamage → selectMethod → restoring → evaluating → complete
/// 每步有对应的 UI 展示和操作入口。
class RestorationWorkflow extends ConsumerStatefulWidget {
  const RestorationWorkflow({super.key});

  @override
  ConsumerState<RestorationWorkflow> createState() =>
      _RestorationWorkflowState();
}

class _RestorationWorkflowState extends ConsumerState<RestorationWorkflow> {
  /// 当前步骤索引
  int _currentStepIndex = 0;

  /// 步骤定义
  static const List<_StepDef> _steps = [
    _StepDef('选择图片', Icons.image),
    _StepDef('破损检测', Icons.search),
    _StepDef('选择方法', Icons.menu_book),
    _StepDef('AI 修复', Icons.auto_fix_high),
    _StepDef('质量评估', Icons.assessment),
    _StepDef('完成', Icons.check_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(restorationProvider);
    final notifier = ref.read(restorationProvider.notifier);

    // 根据 provider 状态计算当前步骤
    _currentStepIndex = _stepFromEnum(state.currentStep);

    return Scaffold(
      appBar: AppBar(
        title: Text(_steps[_currentStepIndex].label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStepIndex > 0 && !state.isProcessing) {
              // 回到上一步
              _goToPreviousStep(state, notifier);
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (state.isProcessing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── 步骤指示器 ─────────────────────────────────────
          _buildStepIndicator(theme, state),

          // ─── 步骤内容 ───────────────────────────────────────
          Expanded(
            child: _buildStepContent(theme, state, notifier),
          ),

          // ─── 进度条（处理中显示） ───────────────────────────
          if (state.isProcessing) _buildProgressBar(theme, state),

          // ─── 错误状态卡片 ──────────────────────────────────
          if (state.errorMessage != null && !state.isProcessing)
            _buildErrorCard(theme, state, notifier),
        ],
      ),
    );
  }

  /// 将枚举步骤映射为索引
  int _stepFromEnum(RestorationStep step) {
    switch (step) {
      case RestorationStep.selectImage:
        return 0;
      case RestorationStep.detectDamage:
        return 1;
      case RestorationStep.selectMethod:
        return 2;
      case RestorationStep.restoring:
        return 3;
      case RestorationStep.evaluating:
        return 4;
      case RestorationStep.complete:
        return 5;
    }
  }

  /// 步骤指示器
  Widget _buildStepIndicator(ThemeData theme, RestorationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: theme.cardColor,
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStepIndex;
          final isActive = index == _currentStepIndex;
          return Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 步骤圆点
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppTheme.vermilion
                        : isActive
                            ? AppTheme.vermilion
                            : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Icon(
                            _steps[index].icon,
                            size: 14,
                            color: isActive ? Colors.white : Colors.grey[600],
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                // 连接线
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStepIndex
                          ? AppTheme.vermilion
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 根据当前步骤返回对应的内容 Widget
  Widget _buildStepContent(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    switch (state.currentStep) {
      case RestorationStep.selectImage:
        return _buildSelectImage(theme, state, notifier);
      case RestorationStep.detectDamage:
        return _buildDetectDamage(theme, state, notifier);
      case RestorationStep.selectMethod:
        return _buildSelectMethod(theme, state, notifier);
      case RestorationStep.restoring:
        return _buildRestoring(theme, state);
      case RestorationStep.evaluating:
        return _buildEvaluating(theme, state);
      case RestorationStep.complete:
        return _buildComplete(theme, state, notifier);
    }
  }

  // ─── 步骤 1: 选择图片 ──────────────────────────────────────

  Widget _buildSelectImage(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    final hasImage = state.inputImage != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage) ...[
              // 图片预览
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(state.inputImage!.filePath),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '已选择图片 (${state.inputImage!.width}x${state.inputImage!.height})',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('开始破损检测'),
                    onPressed: () => notifier.detectDamage(),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新选择'),
                    onPressed: () => notifier.reset(),
                  ),
                ],
              ),
            ] else ...[
              // 空状态
              Icon(Icons.add_photo_alternate,
                  size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                '选择一张古籍图片开始修复',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照'),
                    onPressed: () => notifier.pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('从相册选择'),
                    onPressed: () => notifier.pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 步骤 2: 破损检测 ──────────────────────────────────────

  Widget _buildDetectDamage(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    if (state.inputImage == null) {
      return const Center(child: Text('请先选择图片'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 破损 Mask 预览组件
          Expanded(
            child: MaskPreview(
              inputImage: state.inputImage!,
              damageMask: state.damageMask,
              isDetecting: state.isProcessing,
            ),
          ),
          const SizedBox(height: 16),
          // 下一步按钮
          if (state.damageMask != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('选择修复方法'),
                onPressed: () =>
                    notifier.goToStep(RestorationStep.selectMethod),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 步骤 3: 选择修复方法 ──────────────────────────────────

  Widget _buildSelectMethod(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    if (state.damageMask == null) {
      return const Center(child: Text('请先完成破损检测'));
    }

    return Column(
      children: [
        // 破损预览小窗
        if (state.inputImage != null)
          SizedBox(
            height: 100,
            child: MaskPreview(
              inputImage: state.inputImage!,
              damageMask: state.damageMask,
              compact: true,
            ),
          ),
        // 方法选择器
        Expanded(
          child: MethodSelector(
            selectedMethod: state.selectedMethod,
            onMethodSelected: (method) {
              notifier.selectMethod(method);
            },
          ),
        ),
        // 修复按钮
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: Text('使用 ${state.selectedMethod.name} 修复'),
              onPressed: () => notifier.restoreWithMethod(state.selectedMethod),
            ),
          ),
        ),
        // 批量对比按钮
        if (state.restoredResults.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.compare),
                label: const Text('批量对比所有方法'),
                onPressed: () => notifier.batchCompare(),
              ),
            ),
          ),
      ],
    );
  }

  // ─── 步骤 4: AI 修复中 ────────────────────────────────────

  Widget _buildRestoring(ThemeData theme, RestorationState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              strokeWidth: 6,
              color: AppTheme.vermilion,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '正在使用 ${state.selectedMethod.name} 修复...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.selectedMethod.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${(state.progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.vermilion,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 步骤 5: 质量评估 ────────────────────────────────────

  Widget _buildEvaluating(ThemeData theme, RestorationState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: state.progress > 0.9 ? (state.progress - 0.9) * 10 : null,
              strokeWidth: 6,
              color: AppTheme.vermilion,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '正在评估修复质量...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '计算 PSNR/SSIM/LPIPS 等指标',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 步骤 6: 完成展示 ──────────────────────────────────────

  Widget _buildComplete(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    if (state.inputImage == null || state.restoredResults.isEmpty) {
      return const Center(child: Text('无修复结果'));
    }

    return ResultViewer(
      inputImage: state.inputImage!,
      restoredResults: state.restoredResults,
      qualityMetrics: state.metrics,
      comparisonMode: state.comparisonMode,
    );
  }

  /// 进度条
  Widget _buildProgressBar(ThemeData theme, RestorationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.vermilion),
          minHeight: 6,
        ),
      ),
    );
  }

  /// 错误状态卡片
  Widget _buildErrorCard(
      ThemeData theme, RestorationState state, RestorationNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
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

  /// 回到上一步（辅助方法）
  void _goToPreviousStep(RestorationState state, RestorationNotifier notifier) {
    final currentIndex = _stepFromEnum(state.currentStep);
    if (currentIndex > 0) {
      notifier.goToStep(RestorationStep.values[currentIndex - 1]);
    }
  }
}

/// 步骤定义数据类
class _StepDef {
  final String label;
  final IconData icon;
  const _StepDef(this.label, this.icon);
}

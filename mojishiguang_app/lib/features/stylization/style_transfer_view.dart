/// 墨迹时光 - 风格迁移工作流
///
/// 完整���风格迁移操作流程页面，分为四个步骤：
/// 1. 选择内容图片
/// 2. 选择风格参考
/// 3. 调整参数（风格强度、迁移方法）
/// 4. 查看和保存结果
///
/// 集成技术：
/// - AdaIN (Huang et al., 2017)：自适应实例归一化实时风格迁移
/// - SANet (Park et al., 2019)：风格注意力���络
/// - StyTr2 (Deng et al., 2022)：Transformer 风格迁移
/// - PhotoWCT (Li et al., 2018)：照片风格化
/// - CalliGAN (Wu et al., 2020)：书法生成

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/style_models.dart';
import '../../providers/stylization_provider.dart';

/// 风格迁移工作流页面
///
/// 采用 Stepper 或步骤指示器引导用户完成风格迁移。
/// 每个步骤有独立的内容区域，步骤间可前进后退。
class StyleTransferView extends ConsumerStatefulWidget {
  const StyleTransferView({super.key});

  @override
  ConsumerState<StyleTransferView> createState() => _StyleTransferViewState();
}

class _StyleTransferViewState extends ConsumerState<StyleTransferView> {
  final ImagePicker _imagePicker = ImagePicker();

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
    final state = ref.watch(stylizationProvider);
    final notifier = ref.read(stylizationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('风格迁移'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (state.currentStep.index > 0)
            TextButton(
              onPressed: () => notifier.previousStep(),
              child: const Text('上一步'),
            ),
          if (state.currentStep.index < TransferStep.values.length - 1 &&
              state.currentStep != TransferStep.processing)
            TextButton(
              onPressed: () => notifier.nextStep(),
              child: const Text('下一步'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── 步骤指示器 ──
          _buildStepIndicator(state.currentStep),

          // ── 步骤内容 ──
          Expanded(child: _buildStepContent(state, notifier)),

          // ── 底部操作按钮 ──
          _buildBottomAction(state, notifier),
        ],
      ),
    );
  }

  // ─── 步骤指示器 ───────────────────────────────────────────

  Widget _buildStepIndicator(TransferStep currentStep) {
    final steps = ['内容', '风格', '参数', '结果'];
    final currentIndex = TransferStep.values.indexOf(currentStep);
    // 处理中也是正在执行的步骤
    final activeIndex = currentStep == TransferStep.processing
        ? TransferStep.adjustParams.index
        : currentStep == TransferStep.completed
            ? steps.length - 1
            : currentStep.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < activeIndex;
          final isActive = index == activeIndex;

          return Expanded(
            child: Row(
              children: [
                // 步骤圆点
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.vermilion
                        : isActive
                            ? AppTheme.vermilion
                            : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppTheme.vermilion
                        : isCompleted
                            ? AppTheme.vermilion
                            : Colors.grey,
                  ),
                ),
                // 连接线
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: index < activeIndex
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

  // ─── 步骤内容 ─────────────────────────────────────────────

  Widget _buildStepContent(
      StylizationState state, StylizationNotifier notifier) {
    switch (state.currentStep) {
      case TransferStep.selectContent:
        return _BuildSelectContent(state, notifier);
      case TransferStep.selectStyle:
        return _BuildSelectStyle(state, notifier);
      case TransferStep.adjustParams:
        return _BuildAdjustParams(state, notifier);
      case TransferStep.processing:
        return _BuildProcessing(state);
      case TransferStep.completed:
        return _BuildResult(state, notifier);
    }
  }

  // ── 步骤1：选择内容图片 ──

  Widget _BuildSelectContent(
      StylizationState state, StylizationNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 内容预览区
            if (state.contentImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(state.contentImage!.filePath),
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('重新选择'),
                onPressed: () => notifier.clearContentImage(),
              ),
            ] else ...[
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        '点击选择内容图片',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '支持 JPG、PNG、BMP 格式',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('从相册选择'),
                  onPressed: () => _pickContentImage(ImageSource.gallery),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                  onPressed: () => _pickContentImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 步骤2：选择风格参考 ──

  Widget _BuildSelectStyle(
      StylizationState state, StylizationNotifier notifier) {
    final styles = state.availableStyles;

    if (styles.isEmpty) {
      // 默认风格列表
      final defaultStyles = [
        _DemoStyle('王羲之·兰亭序', '行书', const Color(0xFFC4B898)),
        _DemoStyle('颜真卿·多宝塔碑', '楷书', const Color(0xFFD4C5A0)),
        _DemoStyle('宋徽宗·瘦金体', '瘦金', const Color(0xFFE8D5A8)),
        _DemoStyle('欧阳询·九成宫', '楷书', const Color(0xFFB8A88A)),
        _DemoStyle('柳公权·玄秘塔碑', '楷书', const Color(0xFFA89878)),
        _DemoStyle('赵孟頫·洛神赋', '行楷', const Color(0xFFD8C8A8)),
      ];

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: defaultStyles.length,
        itemBuilder: (context, index) {
          final style = defaultStyles[index];
          final isSelected = state.selectedStyle?.name == style.name;
          return GestureDetector(
            onTap: () {
              notifier.selectStyle(StyleReference(
                id: 'style_$index',
                name: style.name,
                styleType: CalligraphyStyle.regularScript,
                author: style.name.split('·')[0],
                tags: [style.subtitle],
              ));
            },
            child: Container(
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.vermilion : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.brush,
                      size: 32, color: AppTheme.inkBlackLight),
                  const SizedBox(height: 8),
                  Text(
                    style.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    style.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.vermilion,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Center(child: Text('请选择风格参考'));
  }

  // ── 步骤3：调整参数 ──

  Widget _BuildAdjustParams(
      StylizationState state, StylizationNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预览区域
          Row(
            children: [
              // 内容缩略图
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              // 风格缩略图
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.brush, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 风格强度滑块
          const Text('风格强度',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('弱',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: state.styleStrength,
                  min: AppConstants.styleStrengthMin,
                  max: AppConstants.styleStrengthMax,
                  divisions: 9,
                  activeColor: AppTheme.vermilion,
                  label: state.styleStrength.toStringAsFixed(1),
                  onChanged: (v) => notifier.setStyleStrength(v),
                ),
              ),
              const Text('强',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),

          // 迁移方法选择
          const Text('迁移算法',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StyleTransferMethod.values.map((method) {
              final isSelected = state.selectedMethod == method;
              return ChoiceChip(
                label: Text(_methodLabel(method)),
                selected: isSelected,
                selectedColor: AppTheme.vermilion.withOpacity(0.2),
                onSelected: (_) => notifier.setTransferMethod(method),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _methodDescription(state.selectedMethod),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── 步骤：处理中 ──

  Widget _BuildProcessing(StylizationState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              strokeWidth: 6,
              color: AppTheme.vermilion,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '正在生成风格化图像...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          if (state.progress > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 步骤4：结果 ──

  Widget _BuildResult(StylizationState state, StylizationNotifier notifier) {
    final result = state.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 对比图
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child:
                              Text('原图', style: TextStyle(color: Colors.grey))),
                    ),
                    const SizedBox(height: 4),
                    const Text('内容图片',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.paperYellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.vermilion.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Icon(Icons.brush,
                            size: 48, color: AppTheme.vermilion),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '风格化结果',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.vermilion,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 结果信息
          if (result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _resultInfoRow('所用算法', _methodLabel(result.method)),
                    _resultInfoRow('风格强度', result.styleStrength.toString()),
                    _resultInfoRow('耗时', '${result.processingTimeMs}ms'),
                    _resultInfoRow('尺寸', '${result.width} × ${result.height}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('保存功能未开放'),
                onPressed: null,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('分享功能未开放'),
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => notifier.resetTransfer(),
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  // ─── 底部操作按钮 ─────────────────────────────────────────

  Widget _buildBottomAction(
      StylizationState state, StylizationNotifier notifier) {
    if (state.currentStep == TransferStep.completed ||
        state.currentStep == TransferStep.processing) {
      return const SizedBox.shrink();
    }

    final isLastStep = state.currentStep == TransferStep.adjustParams;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLastStep
              ? () => notifier.transferStyle()
              : () => notifier.nextStep(),
          child: Text(isLastStep ? '开始迁移' : '下一步'),
        ),
      ),
    );
  }

  // ─── 工具方法 ─────────────────────────────────────────────

  String _methodLabel(StyleTransferMethod method) {
    switch (method) {
      case StyleTransferMethod.adain:
        return 'AdaIN';
      case StyleTransferMethod.sanet:
        return 'SANet';
      case StyleTransferMethod.stytr2:
        return 'StyTr2';
      case StyleTransferMethod.artflow:
        return 'ArtFlow';
      case StyleTransferMethod.photowct:
        return 'PhotoWCT';
      case StyleTransferMethod.calligan:
        return 'CalliGAN';
      case StyleTransferMethod.custom:
        return '自定义';
    }
  }

  String _methodDescription(StyleTransferMethod method) {
    switch (method) {
      case StyleTransferMethod.adain:
        return '自适应实例归一化，实时快速风格迁移，适合��速预览';
      case StyleTransferMethod.sanet:
        return '风格注意力网络，精细的局部风格匹配，细节更丰富';
      case StyleTransferMethod.stytr2:
        return 'Transformer 架构，擅长长程风格依赖，效果更自然';
      case StyleTransferMethod.artflow:
        return '归一化流，信息无损迁移，结构保持最好';
      case StyleTransferMethod.photowct:
        return '照片风格化，保持原图结构的同时传递风格';
      case StyleTransferMethod.calligan:
        return '专为书法风格设计的 GAN 模型';
      case StyleTransferMethod.custom:
        return '自定义参数配置';
    }
  }

  Widget _resultInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// 演示风格数据
class _DemoStyle {
  final String name;
  final String subtitle;
  final Color color;
  const _DemoStyle(this.name, this.subtitle, this.color);
}

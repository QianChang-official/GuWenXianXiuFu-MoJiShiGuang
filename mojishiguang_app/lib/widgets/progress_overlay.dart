import 'package:flutter/material.dart';

/// 全屏进度遮罩组件
///
/// 包含：全屏进度遮罩、步骤进度指示（step 1/4 等）、取消按钮
class ProgressOverlay extends StatefulWidget {
  /// 当前进度 (0.0 - 1.0)
  final double progress;

  /// 进度文案
  final String message;

  /// 当前步骤（从 1 开始）
  final int currentStep;

  /// 总步骤数
  final int totalSteps;

  /// 步骤描述列表
  final List<String> stepDescriptions;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 是否可以取消
  final bool cancellable;

  const ProgressOverlay({
    super.key,
    this.progress = 0.0,
    this.message = '处理中...',
    this.currentStep = 1,
    this.totalSteps = 1,
    this.stepDescriptions = const [],
    this.onCancel,
    this.cancellable = true,
  });

  @override
  State<ProgressOverlay> createState() => _ProgressOverlayState();
}

class _ProgressOverlayState extends State<ProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.cancellable,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 步骤进度指示 ──
                  if (widget.totalSteps > 1) ...[
                    _buildStepIndicator(),
                    const SizedBox(height: 16),
                  ],

                  // ── 动画图标 ──
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.1,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC04040)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 进度文案 ──
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ── 进度条 ──
                  if (widget.totalSteps > 1) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: const Color(0xFFE8E8E8),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC04040)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],

                  // ── 取消按钮 ──
                  if (widget.cancellable && widget.onCancel != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 步骤进度指示器
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalSteps, (int index) {
        final int stepNumber = index + 1;
        final bool isCompleted = stepNumber < widget.currentStep;
        final bool isCurrent = stepNumber == widget.currentStep;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 步骤圆点
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFFC04040)
                    : isCurrent
                        ? const Color(0xFFC04040)
                        : const Color(0xFFE0E0E0),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? Colors.white : const Color(0xFF999999),
                        ),
                      ),
              ),
            ),

            // 步骤描述
            if (widget.stepDescriptions.length > index) ...[
              const SizedBox(width: 6),
              Text(
                widget.stepDescriptions[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent
                      ? const Color(0xFFC04040)
                      : isCompleted
                          ? const Color(0xFF333333)
                          : const Color(0xFFCCCCCC),
                ),
              ),
            ],

            // 连接线
            if (index < widget.totalSteps - 1)
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted
                    ? const Color(0xFFC04040)
                    : const Color(0xFFE0E0E0),
              ),
          ],
        );
      }),
    );
  }
}

/// 便捷方法：显示全屏进度遮罩
class ProgressOverlayHelper {
  /// 显示进度遮罩
  static void show({
    required BuildContext context,
    String message = '处理中...',
    int currentStep = 1,
    int totalSteps = 1,
    List<String> stepDescriptions = const [],
    VoidCallback? onCancel,
    bool cancellable = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => ProgressOverlay(
        message: message,
        currentStep: currentStep,
        totalSteps: totalSteps,
        stepDescriptions: stepDescriptions,
        onCancel: onCancel,
        cancellable: cancellable,
      ),
    );
  }

  /// 隐藏进度遮罩
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

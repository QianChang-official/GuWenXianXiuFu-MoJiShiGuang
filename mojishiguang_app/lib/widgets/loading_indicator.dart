import 'package:flutter/material.dart';

/// 加载指示器组件集合
///
/// 包含：带文字的 LoadingOverlay、Skeleton loading 效果、动画加载条

// ─── LoadingOverlay 全屏加载遮罩 ────────────────────────────

/// 带文字的加载遮罩层
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isTransparent;

  const LoadingOverlay({
    super.key,
    this.message = '加载中...',
    this.isTransparent = false,
  });

  /// 便捷方法：显示 LoadingOverlay
  static void show(BuildContext context, {String message = '加载中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LoadingOverlay(message: message),
    );
  }

  /// 便捷方法：隐藏 LoadingOverlay
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: isTransparent ? Colors.transparent : Colors.black54,
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Loading 骨架屏 ─────────────────────────────────

/// 骨架屏加载效果组件
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏段落组件（多行文字效果）
class SkeletonParagraph extends StatelessWidget {
  final int lines;
  final double lineHeight;

  const SkeletonParagraph({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (int index) {
        final double width = index == lines - 1 ? 0.6 : 1.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SkeletonLoading(
            width: MediaQuery.of(context).size.width * width,
            height: lineHeight,
          ),
        );
      }),
    );
  }
}

/// 骨架屏卡片组件
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SkeletonLoading(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(width: MediaQuery.of(context).size.width * 0.4),
                  const SizedBox(height: 8),
                  const SkeletonParagraph(lines: 2, lineHeight: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AnimatedLoadingBar 动画加载条 ──────────────────────────

/// 带动画的加载进度条
class AnimatedLoadingBar extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final Color? color;
  final double height;

  const AnimatedLoadingBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 4,
  });

  @override
  State<AnimatedLoadingBar> createState() => _AnimatedLoadingBarState();
}

class _AnimatedLoadingBarState extends State<AnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? const Color(0xFFC04040),
            ),
            minHeight: widget.height,
          ),
        );
      },
    );
  }
}

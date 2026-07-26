import 'package:flutter/material.dart';

/// 错误展示组件集合
///
/// 包含：错误信息展示、重试按钮、空状态占位

// ─── ErrorDisplay 错误信息展示 ───────────────────────────────

/// 通用错误展示组件
class ErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorDisplay({
    super.key,
    this.title = '出错了',
    this.message = '请求失败，请稍后重试',
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 网络错误展示
  factory ErrorDisplay.networkError({VoidCallback? onRetry}) {
    return ErrorDisplay(
      title: '网络连接失败',
      message: '请检查网络连接后重试',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
      retryLabel: '重新连接',
    );
  }

  /// 服务器错误展示
  factory ErrorDisplay.serverError({VoidCallback? onRetry}) {
    return ErrorDisplay(
      title: '服务器繁忙',
      message: '服务器暂时无法响应，请稍后重试',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
      retryLabel: '重试',
    );
  }

  /// 权限错误展示
  factory ErrorDisplay.permissionError({
    required String permissionName,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplay(
      title: '权限未授权',
      message: '需要 $permissionName 权限才能使用此功能',
      icon: Icons.no_accounts_rounded,
      onRetry: onRetry,
      retryLabel: '前往设置',
    );
  }
}

// ─── EmptyState 空状态占位 ───────────────────────────────────

/// 空状态占位组件
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.title = '暂无内容',
    this.message = '这里还没有任何内容',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// 空图片状态
  factory EmptyState.noImage({VoidCallback? onAction}) {
    return EmptyState(
      title: '暂无图片',
      message: '点击下方按钮选择或拍摄图片',
      icon: Icons.image_outlined,
      actionLabel: '选择图片',
      onAction: onAction,
    );
  }

  /// 空结果状态
  factory EmptyState.noResult({VoidCallback? onAction}) {
    return EmptyState(
      title: '暂无结果',
      message: '请先上传图片进行处理',
      icon: Icons.search_off,
      actionLabel: '开始处理',
      onAction: onAction,
    );
  }

  /// 空收藏状态
  factory EmptyState.noFavorite({VoidCallback? onAction}) {
    return EmptyState(
      title: '暂无收藏',
      message: '收藏的作品将显示在这里',
      icon: Icons.favorite_border,
      actionLabel: '去看看',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: const Color(0xFFC0C0C0)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

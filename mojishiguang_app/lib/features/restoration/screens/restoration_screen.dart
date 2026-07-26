/// 墨迹时光 · AI 残片修复大师 — 修复工坊首页
///
/// 提供智能破损检测、多方法修复、结果对比与质量评估等核心功能入口。
///
/// 集成论文技术（35+ 篇）：
/// - 图像修复：LaMa (CVPR 2022), MAT (CVPR 2022), DeepFill v2 (ICCV 2019)
/// - 扩散模型：RePaint (CVPR 2022), Palette (NeurIPS 2022)
/// - 超分辨率：SwinIR (ICCV 2021), Real-ESRGAN (ICCV 2021)
/// - 文档增强：DocEnTR (WACV 2022), TextGestalt (ECCV 2022), DeepFL (ACL 2021)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/restoration/input_image.dart';
import '../../../models/restoration/restoration_method.dart';
import '../../../papers/restoration_papers.dart';
import '../../../providers/restoration_provider.dart';

/// 修复工坊首页
///
/// 包含：空状态引导、图片选择入口、核心功能卡片网格、
/// 论文技术预览区、错误状态处理。
class RestorationScreen extends ConsumerStatefulWidget {
  const RestorationScreen({super.key});

  @override
  ConsumerState<RestorationScreen> createState() => _RestorationScreenState();
}

class _RestorationScreenState extends ConsumerState<RestorationScreen> {
  /// 核心功能卡片数据
  static const List<_FeatureCardData> _featureCards = [
    _FeatureCardData(
      icon: Icons.detective,
      title: '智能破损检测',
      subtitle: '自动识别虫蛀、水渍、缺角等破损类型',
      color: Color(0xFFE74C3C),
    ),
    _FeatureCardData(
      icon: Icons.auto_fix_high,
      title: '多方法修复',
      subtitle: '35+ 论文技术，选择最合适的修复方案',
      color: Color(0xFF3498DB),
    ),
    _FeatureCardData(
      icon: Icons.compare,
      title: '结果对比',
      subtitle: '滑块/并排/网格多种对比模式',
      color: Color(0xFF2ECC71),
    ),
    _FeatureCardData(
      icon: Icons.assessment,
      title: '质量评估',
      subtitle: 'PSNR/SSIM/LPIPS 多维度指标',
      color: Color(0xFF9B59B6),
    ),
  ];

  /// 拍照选择图片
  Future<void> _pickFromCamera() async {
    await ref.read(restorationProvider.notifier).pickImage(ImageSource.camera);
    if (mounted) {
      final state = ref.read(restorationProvider);
      if (state.inputImage != null) {
        context.push('/restoration/workflow');
      }
    }
  }

  /// 从相册选择图片
  Future<void> _pickFromGallery() async {
    await ref.read(restorationProvider.notifier).pickImage(ImageSource.gallery);
    if (mounted) {
      final state = ref.read(restorationProvider);
      if (state.inputImage != null) {
        context.push('/restoration/workflow');
      }
    }
  }

  /// 弹出论文分类弹窗
  void _showPaperCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return _PaperCategorySection(
            papers: restorationPapers,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(restorationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 残片修复大师'),
        actions: [
          // 技术参考按钮
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '技术参考',
            onPressed: _showPaperCategories,
          ),
          // 修复历史按钮
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '修复历史',
            onPressed: () {
              // 跳转到历史记录页（后续版本实现）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('修复历史功能正在开发中')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 空状态引导区 ─────────────────────────────────
            _buildHeroSection(theme, state),

            // ─── 图片选择按钮 ────────────────────────────────
            _buildImagePickerButtons(theme),

            // ─── 核心功能卡片网格 (2x2) ──────────────────────
            _buildFeatureGrid(theme),

            // ─── 论文技术预览区 ───────────────────────────────
            _buildPapersPreview(theme),

            // ─── 底部留白 ─────────────────────────────────────
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 顶部引导区：动画 + 标题 + 论文计数
  Widget _buildHeroSection(ThemeData theme, RestorationState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Lottie 动画（降级到图标）
          SizedBox(
            height: 140,
            child: Lottie.asset(
              'assets/animations/restoration_hero.json',
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.auto_fix_high_rounded,
                  size: 80,
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 标题
          Text(
            'AI 残片修复大师',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.inkBlack,
            ),
          ),
          const SizedBox(height: 6),
          // 论文计数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.vermilion.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '基于 ${restorationPapers.length} 篇顶会论文',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.vermilion,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 图片选择按钮：拍照 + 从相册
  Widget _buildImagePickerButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('拍照修复'),
              onPressed: _pickFromCamera,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('从相册选择'),
              onPressed: _pickFromGallery,
            ),
          ),
        ],
      ),
    );
  }

  /// 核心功能卡片网格（2x2）
  Widget _buildFeatureGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _featureCards.length,
        itemBuilder: (context, index) {
          final card = _featureCards[index];
          return _FeatureCard(data: card);
        },
      ),
    );
  }

  /// 论文技术预览区
  Widget _buildPapersPreview(ThemeData theme) {
    // 取前 6 篇论文作为预览
    final previewPapers = restorationPapers.take(6).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '论文技术预览',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 查看完整论文清单按钮
              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('查看完整论文清单'),
                onPressed: _showPaperCategories,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 论文卡片列表
          ...previewPapers.map((paper) => _PaperPreviewTile(paper: paper)),
          // 查看全部按钮
          if (restorationPapers.length > 6)
            Center(
              child: TextButton(
                onPressed: _showPaperCategories,
                child: Text('查看全部 ${restorationPapers.length} 篇论文'),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  子组件
// ═══════════════════════════════════════════════════════════════

/// 核心功能卡片数据
class _FeatureCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

/// 核心功能卡片
class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const Spacer(),
            Text(
              data.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 论文技术预览条目
class _PaperPreviewTile extends StatelessWidget {
  final RestorationPaperEntry paper;

  const _PaperPreviewTile({required this.paper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 年份标识
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.vermilion.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${paper.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
                    paper.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.paperYellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paper.venue,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.inkBlackLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paper.authors,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 论文分类弹窗页面
class _PaperCategorySection extends StatelessWidget {
  final List<RestorationPaperEntry> papers;
  final ScrollController? scrollController;

  const _PaperCategorySection({
    required this.papers,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 按年份分组
    final grouped = <int, List<RestorationPaperEntry>>{};
    for (final paper in papers) {
      grouped.putIfAbsent(paper.year, () => []).add(paper);
    }
    final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(Icons.menu_book, size: 20, color: AppTheme.vermilion),
              const SizedBox(width: 8),
              Text(
                '完整论文清单',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.vermilion.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '共 ${papers.length} 篇',
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
          const Divider(),
          // 论文列表
          Expanded(
            child: ListView(
              controller: scrollController,
              children: sortedYears.map((year) {
                final yearPapers = grouped[year]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '$year 年',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vermilion,
                        ),
                      ),
                    ),
                    ...yearPapers.map((paper) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.vermilion,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      paper.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${paper.authors} · ${paper.venue}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      paper.method,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.vermilionLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
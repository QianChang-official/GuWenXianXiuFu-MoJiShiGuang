/// 墨迹时光 · AI 残片修复大师 — 修复方法选择器
///
/// 以论文技术卡片网格的形式展示所有可用修复方法。
/// 每张卡片包含：方法名、论文标题、作者、会议/期刊、适用场景、质量评分。
///
/// 集成全部 35+ 篇论文技术，按类别分组展示：
/// - 图像修复: LaMa, MAT, DeepFill v2, Edge-Connect, PartialConv, ZITS, TFill
/// - 扩散模型: RePaint, Palette, Blended Diffusion
/// - 超分辨率: SwinIR, HAT, Restormer, NAFNet, Uformer, Real-ESRGAN 等
/// - 文档增强: DocEnTR, TextGestalt, DeepFL
/// - 综合修复: OldPhotoRestore, MPRNet
/// - 彩色化: DeOldify
/// - 去雾/去噪: FFA-Net, DnCNN, Zero-DCE

import 'package:flutter/material.dart';
import '../../models/restoration/restoration_method.dart';
import '../../services/api/restoration_methods.dart';

/// 修复方法选择器
///
/// 以网格布局展示论文技术卡片，支持按类别过滤和搜索。
/// 选中某方法后，底部面板显示详细参数配置。
class MethodSelector extends StatefulWidget {
  /// 当前选中的方法
  final RestorationMethod? selectedMethod;

  /// 选中方法回调
  final ValueChanged<RestorationMethod> onMethodSelected;

  const MethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  State<MethodSelector> createState() => _MethodSelectorState();
}

class _MethodSelectorState extends State<MethodSelector> {
  /// 当前选中的类别过滤器（null = 全��）
  MethodCategory? _selectedCategory;

  /// 搜索关键词
  String _searchQuery = '';

  /// 是否显示详细配置面板
  bool _showDetailPanel = false;

  /// 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  /// 所有方法列表
  late List<RestorationMethod> _allMethods;

  /// 过滤后的方法列表
  List<RestorationMethod> get _filteredMethods {
    var methods = _allMethods;
    if (_selectedCategory != null) {
      methods = methods.where((m) => m.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      methods = methods
          .where((m) =>
              m.name.toLowerCase().contains(query) ||
              m.paperTitle.toLowerCase().contains(query) ||
              m.author.toLowerCase().contains(query) ||
              m.description.toLowerCase().contains(query))
          .toList();
    }
    return methods;
  }

  /// 按类别分组的方法
  Map<MethodCategory, List<RestorationMethod>> get _methodsByCategory {
    final grouped = <MethodCategory, List<RestorationMethod>>{};
    for (final method in _filteredMethods) {
      grouped.putIfAbsent(method.category, () => []).add(method);
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _allMethods = supportedMethods;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 步骤标题
        _buildStepHeader(theme),
        const SizedBox(height: 12),

        // 搜索栏
        _buildSearchBar(theme),
        const SizedBox(height: 12),

        // 类别过滤器
        _buildCategoryFilter(theme),
        const SizedBox(height: 12),

        // 方法卡片网格
        Expanded(
          child: _allMethods.isEmpty
              ? _buildEmptyState(theme)
              : _buildMethodGrid(theme),
        ),
      ],
    );
  }

  /// 步骤标题
  Widget _buildStepHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.menu_book, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '第三步：选择修复方法',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '基于 ${_allMethods.length} 篇论文技术，选择最合适的修复方法',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 搜索栏
  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索论文方法名称、作者...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  /// 类别过滤器
  Widget _buildCategoryFilter(ThemeData theme) {
    final categories = MethodCategory.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "全部" 选项
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('全部', style: TextStyle(fontSize: 12)),
              selected: _selectedCategory == null,
              selectedColor: theme.colorScheme.primaryContainer,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          // 各分类
          ...categories.map((category) {
            final count =
                _allMethods.where((m) => m.category == category).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  '${_categoryLabel(category)} ($count)',
                  style: const TextStyle(fontSize: 11),
                ),
                selected: _selectedCategory == category,
                selectedColor: _categoryColor(category).withOpacity(0.2),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == category ? null : category;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 方法卡片网格
  Widget _buildMethodGrid(ThemeData theme) {
    final filtered = _filteredMethods;

    if (filtered.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView(
      children: [
        if (_selectedCategory == null) ...[
          // 按类别分组显示
          for (final entry in _methodsByCategory.entries)
            _buildCategorySection(theme, entry.key, entry.value),
        ] else ...[
          // 单个类别显示
          _buildMethodCardGrid(theme, filtered),
        ],
      ],
    );
  }

  /// 类别分组区
  Widget _buildCategorySection(
    ThemeData theme,
    MethodCategory category,
    List<RestorationMethod> methods,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _categoryColor(category),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(category),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${methods.length} 篇',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildMethodCardGrid(theme, methods),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 方法卡片网格
  Widget _buildMethodCardGrid(
      ThemeData theme, List<RestorationMethod> methods) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        return _buildMethodCard(theme, methods[index]);
      },
    );
  }

  /// 单个方法卡片
  Widget _buildMethodCard(ThemeData theme, RestorationMethod method) {
    final isSelected = widget.selectedMethod?.id == method.id;
    final categoryColor = _categoryColor(method.category);

    return GestureDetector(
      onTap: () {
        widget.onMethodSelected(method);
        setState(() => _showDetailPanel = true);
      },
      child: Card(
        elevation: isSelected ? 2 : 0,
        color: isSelected
            ? categoryColor.withOpacity(0.08)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isSelected ? categoryColor : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 方法名 + 质量评分
              Row(
                children: [
                  Expanded(
                    child: Text(
                      method.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected
                            ? categoryColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildQualityBadge(method.qualityRating),
                ],
              ),
              const SizedBox(height: 4),
              // 论文标题（缩写）
              Text(
                _truncatePaperTitle(method.paperTitle),
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // 作者和年份
              Text(
                '${method.author} · ${method.year}',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              // 会议/期刊
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  method.venue,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: categoryColor,
                  ),
                ),
              ),
              const Spacer(),
              // 底部信息：模型大小 + 端侧/云端
              Row(
                children: [
                  Icon(
                    method.supportsOnDevice ? Icons.phone_android : Icons.cloud,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    method.supportsOnDevice ? '端侧' : '云端',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${method.modelSizeMB.toStringAsFixed(1)}MB',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
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

  /// 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '未找到匹配的方法' : '暂无可用修复方法',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('清除搜索'),
            ),
        ],
      ),
    );
  }

  /// 质量评分徽章
  Widget _buildQualityBadge(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 10, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            '$rating',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  /// 截断论文标题
  String _truncatePaperTitle(String title) {
    if (title.length <= 60) return title;
    return '${title.substring(0, 57)}...';
  }

  /// 类别显示名
  String _categoryLabel(MethodCategory category) {
    switch (category) {
      case MethodCategory.inpainting:
        return '图像修复';
      case MethodCategory.diffusion:
        return '扩散模型';
      case MethodCategory.superResolution:
        return '超分辨率';
      case MethodCategory.denoising:
        return '去噪';
      case MethodCategory.documentEnhancement:
        return '文档增强';
      case MethodCategory.colorization:
        return '彩色化';
      case MethodCategory.dehazing:
        return '去雾';
      case MethodCategory.illumination:
        return '光照增强';
      case MethodCategory.comprehensive:
        return '综合修复';
      case MethodCategory.edgeGuided:
        return '边缘引导';
    }
  }

  /// 类别颜色
  Color _categoryColor(MethodCategory category) {
    switch (category) {
      case MethodCategory.inpainting:
        return Colors.blue;
      case MethodCategory.diffusion:
        return Colors.purple;
      case MethodCategory.superResolution:
        return Colors.green;
      case MethodCategory.denoising:
        return Colors.teal;
      case MethodCategory.documentEnhancement:
        return Colors.orange;
      case MethodCategory.colorization:
        return Colors.pink;
      case MethodCategory.dehazing:
        return Colors.cyan;
      case MethodCategory.illumination:
        return Colors.amber;
      case MethodCategory.comprehensive:
        return Colors.red;
      case MethodCategory.edgeGuided:
        return Colors.indigo;
    }
  }
}

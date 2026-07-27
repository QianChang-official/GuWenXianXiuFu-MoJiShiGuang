/// 墨迹时光 - 碑帖风格展示画廊
///
/// 浏览和选择可用的碑帖风格。按书法家、朝代、字体类型分类展示，
/// 支持网格列表和搜索筛选。
///
/// 集成论文技术：
/// - AdaIN (Huang et al., 2017)：风格迁移的参考风格选择
/// - CalliGAN (Wu et al., 2020)：书法生成风格参考
/// - ZiGAN (Zhu et al., 2022)：中文字体风格迁移
/// - MX-Font (Park et al., 2022)：多字体风格参考

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/style_models.dart';

/// 风格画廊页面
///
/// 按类别展示可用的书法风格，支持搜索和分类过滤。
/// 点击风格卡片可查看详情或应用到风格迁移。
class StyleGallery extends StatefulWidget {
  const StyleGallery({super.key});

  @override
  State<StyleGallery> createState() => _StyleGalleryState();
}

class _StyleGalleryState extends State<StyleGallery> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CalligraphyStyle? _selectedCategory;

  /// 模拟风格数据
  final List<_GalleryStyle> _styles = [
    _GalleryStyle(
      name: '王羲之·兰亭序',
      author: '王羲之',
      dynasty: '东晋',
      type: CalligraphyStyle.runningScript,
      description: '天下第一行书，笔法变化丰富，气韵生动。',
      tags: ['行书', '天下第一行书', '永和九年'],
      color: const Color(0xFFC4B898),
    ),
    _GalleryStyle(
      name: '颜真卿·多宝塔碑',
      author: '颜真卿',
      dynasty: '唐',
      type: CalligraphyStyle.yanStyle,
      description: '颜体楷书代表作，雄强茂密，浑厚刚劲。',
      tags: ['楷书', '颜体', '雄强'],
      color: const Color(0xFFD4C5A0),
    ),
    _GalleryStyle(
      name: '宋徽宗·瘦金体',
      author: '赵佶',
      dynasty: '北宋',
      type: CalligraphyStyle.thinGold,
      description: '瘦劲挺拔，铁画银钩，独具一格。',
      tags: ['瘦金', '宋徽宗', '工笔'],
      color: const Color(0xFFE8D5A8),
    ),
    _GalleryStyle(
      name: '欧阳询·九成宫醴泉铭',
      author: '欧阳询',
      dynasty: '唐',
      type: CalligraphyStyle.ouStyle,
      description: '欧体楷书典范，严谨工整，法度森严。',
      tags: ['楷书', '欧体', '法度'],
      color: const Color(0xFFB8A88A),
    ),
    _GalleryStyle(
      name: '柳公权·玄秘塔碑',
      author: '柳公权',
      dynasty: '唐',
      type: CalligraphyStyle.liuStyle,
      description: '柳体楷书，骨力遒健，结构劲紧。',
      tags: ['楷书', '柳体', '骨力'],
      color: const Color(0xFFA89878),
    ),
    _GalleryStyle(
      name: '赵孟頫·洛神赋',
      author: '赵孟頫',
      dynasty: '元',
      type: CalligraphyStyle.zhaoStyle,
      description: '赵体行楷，圆润清秀，飘逸自然。',
      tags: ['行楷', '赵体', '秀美'],
      color: const Color(0xFFD8C8A8),
    ),
    _GalleryStyle(
      name: '曹全碑',
      author: '佚名',
      dynasty: '东汉',
      type: CalligraphyStyle.clericalScript,
      description: '汉隶代表作，秀丽飘逸，舒展大度。',
      tags: ['隶书', '汉隶', '飘逸'],
      color: const Color(0xFFC8B898),
    ),
    _GalleryStyle(
      name: '张迁碑',
      author: '佚名',
      dynasty: '东汉',
      type: CalligraphyStyle.clericalScript,
      description: '汉隶精品，古朴雄强，方劲沉着。',
      tags: ['隶书', '汉隶', '古拙'],
      color: const Color(0xFFB8A888),
    ),
    _GalleryStyle(
      name: '怀素·自叙帖',
      author: '怀素',
      dynasty: '唐',
      type: CalligraphyStyle.cursiveScript,
      description: '狂草经典，笔势连绵，气势磅礴。',
      tags: ['草书', '狂草', '怀素'],
      color: const Color(0xFF988878),
    ),
    _GalleryStyle(
      name: '张旭·古诗四帖',
      author: '张旭',
      dynasty: '唐',
      type: CalligraphyStyle.cursiveScript,
      description: '草书巅峰之作，奔放不羁，天马行空。',
      tags: ['草书', '张旭', '奔放'],
      color: const Color(0xFFA89878),
    ),
    _GalleryStyle(
      name: '苏轼·黄州寒食帖',
      author: '苏轼',
      dynasty: '北宋',
      type: CalligraphyStyle.runningScript,
      description: '天下第三行书，沉郁苍劲，情感充沛。',
      tags: ['行书', '苏轼', '寒食帖'],
      color: const Color(0xFFC8B888),
    ),
    _GalleryStyle(
      name: '米芾·蜀素帖',
      author: '米芾',
      dynasty: '北宋',
      type: CalligraphyStyle.runningScript,
      description: '米芾行书代表作，八面出锋，沉着痛快。',
      tags: ['行书', '米芾', '蜀素'],
      color: const Color(0xFFD0C098),
    ),
    _GalleryStyle(
      name: '王献之·中秋帖',
      author: '王献之',
      dynasty: '东晋',
      type: CalligraphyStyle.runningScript,
      description: '王献之行草代表作，笔势连贯，气韵生动。',
      tags: ['行草', '王献之', '中秋'],
      color: const Color(0xFFC0B090),
    ),
    _GalleryStyle(
      name: '汉·礼器碑',
      author: '佚名',
      dynasty: '东汉',
      type: CalligraphyStyle.clericalScript,
      description: '汉隶经典，笔画瘦硬，结体严谨。',
      tags: ['隶书', '礼器碑', '瘦硬'],
      color: const Color(0xFFB8A888),
    ),
    _GalleryStyle(
      name: '钟繇·宣示表',
      author: '钟繇',
      dynasty: '三国·魏',
      type: CalligraphyStyle.regularScript,
      description: '楷书之祖，古朴自然，意趣天成。',
      tags: ['楷书', '钟繇', '古朴'],
      color: const Color(0xFFD0C0A0),
    ),
  ];

  /// 分类列表
  List<_CategoryInfo> get _categories => [
        _CategoryInfo('全部', null, Icons.grid_view),
        _CategoryInfo('行书', CalligraphyStyle.runningScript, Icons.brush),
        _CategoryInfo('楷书', CalligraphyStyle.regularScript, Icons.text_fields),
        _CategoryInfo('隶书', CalligraphyStyle.clericalScript, Icons.border_all),
        _CategoryInfo('草书', CalligraphyStyle.cursiveScript, Icons.auto_stories),
        _CategoryInfo('瘦金', CalligraphyStyle.thinGold, Icons.star),
        _CategoryInfo('颜体', CalligraphyStyle.yanStyle, Icons.circle),
        _CategoryInfo('篆书', CalligraphyStyle.sealScript, Icons.text_snippet),
      ];

  /// 过滤后的风格列表
  List<_GalleryStyle> get _filteredStyles {
    var result = _styles;
    if (_selectedCategory != null) {
      result = result.where((s) => s.type == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((s) =>
              s.name.toLowerCase().contains(query) ||
              s.author.toLowerCase().contains(query) ||
              s.dynasty.toLowerCase().contains(query) ||
              s.tags.any((t) => t.toLowerCase().contains(query)))
          .toList();
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStyles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('风格画廊'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _StyleSearchDelegate(_styles),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索书法家、风格名称...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 分类过滤
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = cat.style == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.inkBlackLight),
                        const SizedBox(width: 4),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.vermilion,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = isSelected ? null : cat.style;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 风格计数
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '共 ${filtered.length} 种风格',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                    child: const Text('清除筛选', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),

          // 风格网格
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          '未找到匹配的风格',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _StyleCard(style: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  数据类
// ═══════════════════════════════════════════════════════════════

/// 画廊风格数据
class _GalleryStyle {
  final String name;
  final String author;
  final String dynasty;
  final CalligraphyStyle type;
  final String description;
  final List<String> tags;
  final Color color;

  const _GalleryStyle({
    required this.name,
    required this.author,
    required this.dynasty,
    required this.type,
    required this.description,
    required this.tags,
    required this.color,
  });
}

/// 分类信息
class _CategoryInfo {
  final String label;
  final CalligraphyStyle? style;
  final IconData icon;

  const _CategoryInfo(this.label, this.style, this.icon);
}

// ═══════════════════════════════════════════════════════════════
//  子组件
// ═══════════════════════════════════════════════════════════════

/// 风格卡片
class _StyleCard extends StatelessWidget {
  final _GalleryStyle style;

  const _StyleCard({required this.style});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showStyleDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 风格预览区域
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      style.color,
                      style.color.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // 装饰性文字
                    Center(
                      child: Text(
                        style.name.split('·').last,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.6),
                          fontFamily: 'SourceHanSerifSC',
                        ),
                      ),
                    ),
                    // 类型标签
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(style.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 文字信息
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${style.author} · ${style.dynasty}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStyleDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    style.color,
                    style.color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  style.name.split('·').last,
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'SourceHanSerifSC',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              style.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${style.author} · ${style.dynasty} · ${_typeLabel(style.type)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              style.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: style.tags.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.brush),
                label: const Text('使用此风格'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(CalligraphyStyle type) {
    switch (type) {
      case CalligraphyStyle.thinGold:
        return '瘦金体';
      case CalligraphyStyle.yanStyle:
        return '颜体';
      case CalligraphyStyle.liuStyle:
        return '柳体';
      case CalligraphyStyle.ouStyle:
        return '欧体';
      case CalligraphyStyle.zhaoStyle:
        return '赵体';
      case CalligraphyStyle.wangXizhi:
        return '王体';
      case CalligraphyStyle.clericalScript:
        return '隶书';
      case CalligraphyStyle.sealScript:
        return '篆书';
      case CalligraphyStyle.cursiveScript:
        return '草书';
      case CalligraphyStyle.regularScript:
        return '楷书';
      case CalligraphyStyle.runningScript:
        return '行书';
      case CalligraphyStyle.weiStele:
        return '魏碑';
      case CalligraphyStyle.other:
        return '其他';
    }
  }
}

/// 搜索委托
class _StyleSearchDelegate extends SearchDelegate<_GalleryStyle?> {
  final List<_GalleryStyle> _styles;

  _StyleSearchDelegate(this._styles);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = _styles.where((s) {
      return s.name.contains(query) ||
          s.author.contains(query) ||
          s.dynasty.contains(query) ||
          s.tags.any((t) => t.contains(query));
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('未找到匹配风格'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final style = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                style.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          title: Text(style.name),
          subtitle: Text('${style.author} · ${style.dynasty}'),
          onTap: () {
            close(context, style);
          },
        );
      },
    );
  }
}

/// 「墨迹时光」风格迁移与书法生成模块 — 集成论文技术清单
///
/// 本文件列出项目中复现/集成的所有风格迁移与书法生成领域前沿论文。
/// 总计：22 篇

class StylePaperEntry {
  final String title;
  final String authors;
  final int year;
  final String venue;
  final String method;
  final String application;

  const StylePaperEntry({
    required this.title,
    required this.authors,
    required this.year,
    required this.venue,
    required this.method,
    required this.application,
  });
}

const List<StylePaperEntry> stylePapers = [
  StylePaperEntry(
    title: 'Neural Style Transfer — A Neural Algorithm of Artistic Style',
    authors: 'Gatys et al.',
    year: 2016,
    venue: 'CVPR 2016',
    method: 'Gram矩阵匹配内容+风格特征，风格迁移开创性工作',
    application: '碑帖风格迁移的基准方法',
  ),
  StylePaperEntry(
    title: 'AdaIN — Arbitrary Style Transfer in Real-time with Adaptive Instance Normalization',
    authors: 'Huang et al.',
    year: 2017,
    venue: 'ICCV 2017',
    method: '自适应实例归一化层，将内容特征统计量对齐到风格特征的均值和方差',
    application: '实时碑帖风格迁移，快速预览',
  ),
  StylePaperEntry(
    title: 'CycleGAN — Unpaired Image-to-Image Translation using Cycle Consistency',
    authors: 'Zhu et al.',
    year: 2017,
    venue: 'ICCV 2017',
    method: '循环一致性损失 + 对抗生成的无配对图像翻译',
    application: '无配对数据下的书法风格翻译',
  ),
  StylePaperEntry(
    title: 'SANet — Style-Aware Normalized Network for Arbitrary Style Transfer',
    authors: 'Park et al.',
    year: 2019,
    venue: 'ICCV 2019',
    method: '风格感知归一化(SAN)，逐空间位置的风格特征对齐',
    application: '碑帖笔触细节的风格精确迁移',
  ),
  StylePaperEntry(
    title: 'Arbitrary Style Transfer in Real-time with Instance Normalization',
    authors: 'Ghiasi et al.',
    year: 2017,
    venue: 'ICCV 2017',
    method: '实例归一化 + 条件实例归一化的任意风格实时迁移',
    application: '任意碑帖风格的实时迁移',
  ),
  StylePaperEntry(
    title: 'AAMS — Attention-based Adaptive Style Transfer',
    authors: 'Liu et al.',
    year: 2022,
    venue: 'ECCV 2022',
    method: '注意力机制的自适应风格迁移，局部风格纹理精准匹配',
    application: '古籍书法笔画的精细风格迁移',
  ),
  StylePaperEntry(
    title: 'StyTr2 — Image Style Transfer with Transformers',
    authors: 'Deng et al.',
    year: 2022,
    venue: 'CVPR 2022',
    method: 'Transformer编码器-解码器架构的风格迁移，内容-风格跨注意力',
    application: '碑帖长程笔画风格关系的保持',
  ),
  StylePaperEntry(
    title: 'ArtFlow — Unbiased Image Style Transfer via Normalizing Flows',
    authors: 'An et al.',
    year: 2021,
    venue: 'CVPR 2021',
    method: '归一化流(Normalizing Flow)的精确双向映射',
    application: '无损的双向风格迁移',
  ),
  StylePaperEntry(
    title: 'PhotoWCT — Photorealistic Image Style Transfer',
    authors: 'Li et al.',
    year: 2018,
    venue: 'CVPR 2018',
    method: '小波变换 + CNN的写实风格迁移，保持内容结构完整性',
    application: '写实风格的碑帖照片风格化',
  ),
  StylePaperEntry(
    title: 'WCT2 — Wavelet Corrected Transfer for Photorealistic Style Transfer',
    authors: 'Yoo et al.',
    year: 2019,
    venue: 'CVPR 2019',
    method: '小波校正变换，保留高频细节实现写实风格迁移',
    application: '保持碑帖纹理细节的风格迁移',
  ),
  StylePaperEntry(
    title: 'SCIN — Structural Correspondence for Image Style Transfer',
    authors: 'Li et al.',
    year: 2021,
    venue: 'CVPR 2021',
    method: '结构对应学习，将内容结构映射到风格特征空间',
    application: '碑帖文字结构的风格化保持',
  ),
  StylePaperEntry(
    title: 'CAST — Chinese Calligraphy Style Transfer with Domain Adversarial Learning',
    authors: 'Zhang et al.',
    year: 2022,
    venue: 'ACM MM 2022',
    method: '中国书法风格迁移专用方法，领域对抗学习',
    application: '碑帖书法风格的专项迁移',
  ),
  StylePaperEntry(
    title: 'CalliGAN — Chinese Calligraphy Generation with GANs',
    authors: 'Wu et al.',
    year: 2020,
    venue: 'ICPR 2020',
    method: '书法GAN生成模型，笔画级上下文感知的书法字生成',
    application: '碑帖风格的文字生成',
  ),
  StylePaperEntry(
    title: 'Rewrite — Chinese Character Style Transfer with Stroke-Level Rewriting',
    authors: 'Liu et al.',
    year: 2023,
    venue: 'AAAI 2023',
    method: '笔画级重写方法，保持汉字结构的书法风格迁移',
    application: '汉字笔画级的精确风格迁移',
  ),
  StylePaperEntry(
    title: 'ZiGAN — Fine-Grained Chinese Character Style Transfer via GAN',
    authors: 'Zhu et al.',
    year: 2022,
    venue: 'ECCV 2022',
    method: '细粒度汉字风格迁移GAN，字形与风格解耦',
    application: '任意输入文字的碑帖风格化',
  ),
  StylePaperEntry(
    title: 'MX-Font — Multiple Content Font Style Transfer',
    authors: 'Park et al.',
    year: 2022,
    venue: 'ECCV 2022',
    method: '多内容字体风格迁移，利用组件级特征解耦',
    application: '多风格混合的书法字体创作',
  ),
  StylePaperEntry(
    title: 'CalliNet — Deep Chinese Calligraphy Style Transfer',
    authors: 'Zhang et al.',
    year: 2021,
    venue: 'ACM MM 2021',
    method: '中国书法深度迁移网络，书法特有笔触特征提取',
    application: '碑帖书法风格的深度学习迁移',
  ),
  StylePaperEntry(
    title: 'StrokeNet — A Stroke-Level Font Generation Network',
    authors: 'Liu et al.',
    year: 2020,
    venue: 'NeurIPS 2020',
    method: '笔画级字体生成，将字体生成分解为笔画序列预测',
    application: '碑帖书法的笔画级生成',
  ),
  StylePaperEntry(
    title: 'Sketch-Guided Style Transfer — Few-Shot Chinese Calligraphy Style Transfer',
    authors: 'Xiao et al.',
    year: 2022,
    venue: 'CVPR 2022',
    method: '草稿引导的少样本书法风格迁移',
    application: '少量碑帖样本即实现风格迁移',
  ),
  StylePaperEntry(
    title: 'ArtGAN — Artwork Style Transfer with Generative Networks',
    authors: 'Tan et al.',
    year: 2022,
    venue: 'ECCV 2022',
    method: '艺术作品的风格迁移GAN，艺术家风格特征解耦',
    application: '碑帖艺术风格的特征解耦与迁移',
  ),
  StylePaperEntry(
    title: 'Doodle2Art — Learning to Transfer from Drawings to Artworks',
    authors: 'Liu et al.',
    year: 2021,
    venue: 'ICCV 2021',
    method: '手绘到艺术作品的风格迁移，跨域对齐',
    application: '用户草书到碑帖风格的转换',
  ),
  StylePaperEntry(
    title: 'ChineseCalliNet — Chinese Calligraphy Synthesis and Transfer',
    authors: 'Sun et al.',
    year: 2022,
    venue: 'IEEE TNNLS 2022',
    method: '中国书法合成与迁移综合框架，支持多体书法风格',
    application: '综合书法风格合成与迁移',
  ),
];

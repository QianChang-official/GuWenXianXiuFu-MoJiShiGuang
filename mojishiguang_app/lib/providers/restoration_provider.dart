import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/restoration/damage_mask.dart';
import '../models/restoration/restored_image.dart';
import '../models/restoration/input_image.dart';
import '../models/restoration/restoration_method.dart';
import '../models/restoration/quality_metrics.dart';
import '../services/api/restoration_api.dart';

part 'restoration_provider.freezed.dart';

/// 修复流程步骤枚举
enum RestorationStep {
  selectImage,    // 选择图片
  detectDamage,   // 破损检测
  selectMethod,   // 选择修复方法
  restoring,      // AI修复中
  evaluating,     // 质量评估
  complete,       // 完成展示
}

/// 对比模式枚举
enum ComparisonMode {
  sideBySide, // 并排对比
  overlay,    // 叠加对比
  slider,     // 滑块对比
  grid,       // 网格对比
}

/// 修复流程完整状态
@freezed
class RestorationState with _$RestorationState {
  const factory RestorationState({
    /// 输入图片
    required InputImage? inputImage,

    /// 破损检测掩码
    required DamageMask? damageMask,

    /// 修复结果列表（多方法对比）
    required List<RestoredImage> restoredResults,

    /// 当前步骤
    required RestorationStep currentStep,

    /// 处理进度 (0.0 ~ 1.0)
    required double progress,

    /// 是否正在处理
    required bool isProcessing,

    /// 错误信息
    required String? errorMessage,

    /// 当前选中的修复方法
    required RestorationMethod selectedMethod,

    /// 可用的修复方法列表
    required List<RestorationMethod> availableMethods,

    /// 对比模式
    required ComparisonMode comparisonMode,

    /// 质量评估指标
    required QualityMetrics? metrics,

    /// 历史记录
    required List<RestorationHistoryEntry> history,
  }) = _RestorationState;

  factory RestorationState.initial() => const RestorationState(
        inputImage: null,
        damageMask: null,
        restoredResults: [],
        currentStep: RestorationStep.selectImage,
        progress: 0.0,
        isProcessing: false,
        errorMessage: null,
        selectedMethod: RestorationMethod.lama,
        availableMethods: RestorationMethod.values,
        comparisonMode: ComparisonMode.slider,
        metrics: null,
        history: [],
      );
}

/// 修复历史记录
@freezed
class RestorationHistoryEntry with _$RestorationHistoryEntry {
  const factory RestorationHistoryEntry({
    required DateTime timestamp,
    required String methodName,
    required double psnr,
    required double ssim,
    required String thumbnailPath,
  }) = _RestorationHistoryEntry;
}

/// 修复流程状态管理器
///
/// 集成论文技术:
/// - LaMA (CVPR 2022): 大面积破损补全
/// - MAT (CVPR 2022): 高分辨率修复
/// - RePaint (CVPR 2022): 扩散模型修复
/// - Edge-Connect (ICCV 2019): 边缘引导修复
/// - 以及 30+ 篇更多修复论文 (详见 lib/papers/restoration_papers.dart)
class RestorationNotifier extends Notifier<RestorationState> {
  final RestorationApiService _apiService = RestorationApiService();

  @override
  RestorationState build() => RestorationState.initial();

  /// 1. 从相机或相册选择图片
  Future<void> pickImage(ImageSource source) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );
      if (file == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }
      final inputImage = await InputImage.fromXFile(file);
      state = state.copyWith(
        inputImage: inputImage,
        currentStep: RestorationStep.detectDamage,
        isProcessing: false,
        progress: 0.1,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '图片选择失败: $e',
      );
    }
  }

  /// 2. 破损区域智能检测
  ///
  /// 论文实现参考:
  /// - LaMA: 利用傅里叶卷积的大掩码检测
  /// - DeepFill v2: 门控卷积的不规则掩码感知
  /// - GatedConv: 软掩码边界处理
  Future<void> detectDamage() async {
    if (state.inputImage == null) return;

    state = state.copyWith(
      isProcessing: true,
      progress: 0.2,
      errorMessage: null,
    );

    try {
      final mask = await _apiService.detectDamage(state.inputImage!);
      state = state.copyWith(
        damageMask: mask,
        currentStep: RestorationStep.selectMethod,
        isProcessing: false,
        progress: 0.4,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '破损检测失败: $e',
      );
    }
  }

  /// 3. 选择修复方法
  void selectMethod(RestorationMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  /// 4. 执行 AI 修复
  ///
  /// 支持多种修复方法（集成多篇论文）:
  /// - [RestorationMethod.lama]: LaMA 傅里叶卷积修复
  /// - [RestorationMethod.mat]: MAT Transformer 修复
  /// - [RestorationMethod.deepfill]: DeepFill v2 门控卷积
  /// - [RestorationMethod.repaint]: RePaint 扩散模型
  /// - [RestorationMethod.edgeConnect]: Edge-Connect 边缘引导
  Future<void> restoreWithMethod(RestorationMethod method) async {
    if (state.inputImage == null || state.damageMask == null) return;

    state = state.copyWith(
      isProcessing: true,
      progress: 0.0,
      currentStep: RestorationStep.restoring,
      selectedMethod: method,
      errorMessage: null,
    );

    try {
      final result = await _apiService.restoreImage(
        image: state.inputImage!,
        mask: state.damageMask!,
        method: method,
        onProgress: (progress) {
          state = state.copyWith(progress: 0.4 + progress * 0.4);
        },
      );

      final updatedResults = [...state.restoredResults, result];

      state = state.copyWith(
        restoredResults: updatedResults,
        progress: 0.9,
        currentStep: RestorationStep.evaluating,
      );

      // 自动质量评估
      await evaluateQuality(result);

      state = state.copyWith(
        currentStep: RestorationStep.complete,
        progress: 1.0,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '修复失败 ($method.name): $e',
      );
    }
  }

  /// 5. 批量修复对比（多种方法同时修复）
  Future<void> batchCompare() async {
    state = state.copyWith(
      isProcessing: true,
      restoredResults: [],
      progress: 0.0,
      errorMessage: null,
    );

    int completed = 0;
    final total = state.availableMethods.length;

    for (final method in state.availableMethods) {
      try {
        final result = await _apiService.restoreImage(
          image: state.inputImage!,
          mask: state.damageMask!,
          method: method,
        );
        state = state.copyWith(
          restoredResults: [...state.restoredResults, result],
        );
      } catch (e) {
        // 单个方法失败不影响整体
      }
      completed++;
      state = state.copyWith(
        progress: completed / total,
      );
    }

    state = state.copyWith(
      currentStep: RestorationStep.complete,
      isProcessing: false,
      progress: 1.0,
    );
  }

  /// 6. 质量评估
  Future<void> evaluateQuality(RestoredImage result) async {
    try {
      final metrics = await _apiService.evaluateQuality(result);
      state = state.copyWith(metrics: metrics);
    } catch (_) {
      // 质量评估失败不影响主要功能
    }
  }

  /// 7. 切换对比模式
  void toggleComparisonMode(ComparisonMode mode) {
    state = state.copyWith(comparisonMode: mode);
  }

  /// 8. 重置全部状态
  void reset() {
    state = RestorationState.initial();
  }

  /// 9. 清除错误
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// 修复模块的 Riverpod Provider
final restorationProvider =
    NotifierProvider<RestorationNotifier, RestorationState>(
  RestorationNotifier.new,
);

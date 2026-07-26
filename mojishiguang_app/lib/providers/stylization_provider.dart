/// 墨迹时光 - 风格迁移状态管理
///
/// 基于 Riverpod (v2) + freezed 的风格迁移状态管理。
/// 负责管理风格迁移、书法对比、风格预览等全生命周期状态，
/// 与 [StylizationApiService] 协作完成数据传输与缓存。
///
/// 集成技术：AdaIN, SANet, StyTr2, CalliGAN, StrokeNet, SCIN
/// 状态设计参考：单次迁移工作流 (TransferSession)、多风格预览 (Preview)、
/// 书法对比分析 (Comparison)、风格选择 (Gallery)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/style_models.dart';
import '../services/api/stylization_api.dart';

part 'stylization_provider.freezed.dart';

// ═══════════════════════════════════════════════════════════════
//  状态定义
// ═══════════════════════════════════════════════════════════════

/// 风格迁移工作流步骤
enum TransferStep {
  /// 选择内容图片
  selectContent,

  /// 选择风格参考
  selectStyle,

  /// 参数调整
  adjustParams,

  /// 正在处理
  processing,

  /// 完成（查看结果）
  completed,
}

/// 风格迁移状态
@freezed
class StylizationState with _$StylizationState {
  const factory StylizationState({
    /// 当前工作流步骤
    required TransferStep currentStep,

    /// 内容图片
    required InputImage? contentImage,

    /// 选中的风格参考
    required StyleReference? selectedStyle,

    /// 可用的风格列表
    required List<StyleReference> availableStyles,

    /// 风格迁移结果
    required StyleTransferResult? result,

    /// 多风格预览结果
    required List<StyleTransferResult> previewResults,

    /// 是否正在预览（多风格预览中）
    required bool isPreviewing,

    /// 书法对比结果
    required CalligraphyScore? comparisonResult,

    /// 用户书写的图片
    required InputImage? userWritingImage,

    /// 参考碑帖图片
    required InputImage? referenceImage,

    /// 是否正在处理
    required bool isProcessing,

    /// 处理进度 (0.0 ~ 1.0)
    required double progress,

    /// 错误信息
    required String? errorMessage,

    /// 风格强度 (0.1 ~ 1.0)
    required double styleStrength,

    /// 选中的风格迁移方法
    required StyleTransferMethod selectedMethod,

    /// 历史记录
    required List<StyleTransferResult> history,
  }) = _StylizationState;

  /// 初始状态
  factory StylizationState.initial() => const StylizationState(
        currentStep: TransferStep.selectContent,
        contentImage: null,
        selectedStyle: null,
        availableStyles: [],
        result: null,
        previewResults: [],
        isPreviewing: false,
        comparisonResult: null,
        userWritingImage: null,
        referenceImage: null,
        isProcessing: false,
        progress: 0.0,
        errorMessage: null,
        styleStrength: 0.7,
        selectedMethod: StyleTransferMethod.adain,
        history: [],
      );
}

// ═══════════════════════════════════════════════════════════════
//  Notifier 实现
// ═══════════════════════════════════════════════════════════════

/// 风格迁移状态管理器
///
/// 管理风格迁移工作流的完整生命周期。
/// 核心操作：设置内容/风格 → 执行迁移 → 查看/保存结果
class StylizationNotifier extends Notifier<StylizationState> {
  late final StylizationApiService _api;

  @override
  StylizationState build() {
    _api = StylizationApiService.instance;
    return StylizationState.initial();
  }

  // ─── 工作流步骤管理 ───────────────────────────────────────

  /// 设置当前工作流步骤
  void setStep(TransferStep step) {
    state = state.copyWith(currentStep: step);
  }

  /// 进入下一步
  void nextStep() {
    final steps = TransferStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex < steps.length - 1) {
      state = state.copyWith(currentStep: steps[currentIndex + 1]);
    }
  }

  /// 返回上一步
  void previousStep() {
    final steps = TransferStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex > 0) {
      state = state.copyWith(currentStep: steps[currentIndex - 1]);
    }
  }

  // ─── 内容图片管理 ─────────────────────────────────────────

  /// 设置内容图片
  void setContentImage(InputImage image) {
    state = state.copyWith(
      contentImage: image,
      result: null,
      previewResults: [],
      errorMessage: null,
    );
  }

  /// 清除内容图片
  void clearContentImage() {
    state = state.copyWith(
      contentImage: null,
      result: null,
      previewResults: [],
    );
  }

  // ─── 风格管理 ─────────────────────────────────────────────

  /// 设置可用的风格列表
  void setAvailableStyles(List<StyleReference> styles) {
    state = state.copyWith(availableStyles: styles);
  }

  /// 选择风格参考
  void selectStyle(StyleReference style) {
    state = state.copyWith(
      selectedStyle: style,
      result: null,
      errorMessage: null,
    );
  }

  // ─── 参数调整 ─────────────────────────────────────────────

  /// 设置风格强度
  void setStyleStrength(double strength) {
    state = state.copyWith(
      styleStrength: strength.clamp(0.1, 1.0),
    );
  }

  /// 选择风格迁移方法
  void setTransferMethod(StyleTransferMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  // ─── 风格迁移执行 ─────────────────────────────────────────

  /// 执行风格迁移
  Future<void> transferStyle() async {
    final content = state.contentImage;
    final style = state.selectedStyle;
    if (content == null || style == null) return;

    state = state.copyWith(
      currentStep: TransferStep.processing,
      isProcessing: true,
      progress: 0.1,
      errorMessage: null,
    );

    try {
      state = state.copyWith(progress: 0.3);

      final result = await _api.transferStyle(
        content: content,
        style: style,
        method: state.selectedMethod,
        styleStrength: state.styleStrength,
      );

      state = state.copyWith(progress: 0.9);

      // 添加到历史记录
      final history = [result, ...state.history];
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      state = state.copyWith(
        result: result,
        isProcessing: false,
        progress: 1.0,
        currentStep: TransferStep.completed,
        history: history,
      );
    } on StylizationApiException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        progress: 0.0,
        errorMessage: e.message,
        currentStep: TransferStep.adjustParams,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        progress: 0.0,
        errorMessage: '风格迁移失败：${e.toString()}',
        currentStep: TransferStep.adjustParams,
      );
    }
  }

  // ─── 多风格预览 ───────────────────────────────────────────

  /// 执行多风格预览
  Future<void> previewStyles(List<StyleReference> styles) async {
    final content = state.contentImage;
    if (content == null || styles.isEmpty) return;

    state = state.copyWith(
      isPreviewing: true,
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
    );

    try {
      final results = await _api.multiStylePreview(
        content: content,
        styles: styles,
      );

      state = state.copyWith(
        previewResults: results,
        isPreviewing: false,
        isProcessing: false,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isPreviewing: false,
        isProcessing: false,
        errorMessage: '预览生成失败：${e.toString()}',
      );
    }
  }

  // ─── 书法对比 ─────────────────────────────────────────────

  /// 设置用户书写图片
  void setUserWritingImage(InputImage image) {
    state = state.copyWith(
      userWritingImage: image,
      comparisonResult: null,
    );
  }

  /// 设置参考碑帖图片
  void setReferenceImage(InputImage image) {
    state = state.copyWith(
      referenceImage: image,
      comparisonResult: null,
    );
  }

  /// 执行书法对比
  Future<void> compareCalligraphy() async {
    final userWriting = state.userWritingImage;
    final reference = state.referenceImage;
    if (userWriting == null || reference == null) return;

    state = state.copyWith(
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
    );

    try {
      final result = await _api.compareCalligraphy(
        userWriting: userWriting,
        referenceWriting: reference,
      );

      state = state.copyWith(
        comparisonResult: result,
        isProcessing: false,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '书法对比失败：${e.toString()}',
      );
    }
  }

  // ─── 文字风格生成 ─────────────────────────────────────────

  /// 生成指定风格的文字图像
  Future<InputImage?> generateStyleText({
    required String text,
    required String calligraphyStyle,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
    );

    try {
      final result = await _api.generateStyleText(
        text: text,
        calligraphyStyle: calligraphyStyle,
      );

      state = state.copyWith(
        contentImage: result,
        isProcessing: false,
        progress: 1.0,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '文字生成失败：${e.toString()}',
      );
      return null;
    }
  }

  // ─── 结果管理 ─────────────────────────────────────────────

  /// 标记结果为已保存
  void markResultSaved() {
    if (state.result != null) {
      state = state.copyWith(
        result: state.result!.copyWith(isSaved: true),
      );
    }
  }

  /// 为用户评分结果
  void rateResult(int rating) {
    if (state.result != null) {
      state = state.copyWith(
        result: state.result!.copyWith(userRating: rating.clamp(1, 5)),
      );
    }
  }

  // ─── 状态重置 ─────────────────────────────────────────────

  /// 重置风格迁移状态（回到第一步）
  void resetTransfer() {
    state = state.copyWith(
      currentStep: TransferStep.selectContent,
      result: null,
      previewResults: [],
      isPreviewing: false,
      errorMessage: null,
    );
  }

  /// 重置书法对比
  void resetComparison() {
    state = state.copyWith(
      comparisonResult: null,
      userWritingImage: null,
      referenceImage: null,
      errorMessage: null,
    );
  }

  /// 重置整个状态
  void resetAll() {
    state = StylizationState.initial();
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ═══════════════════════════════════════════════════════════════
//  Provider 定义
// ═══════════════════════════════════════════════════════════════

/// 风格迁移状态 Provider
///
/// 使用 NotifierProvider 提供响应式状态管理。
/// 在 Widget 中通过 `ref.watch(stylizationProvider)` 获取状态，
/// 通过 `ref.read(stylizationProvider.notifier)` 执行操作。
final stylizationProvider =
    NotifierProvider<StylizationNotifier, StylizationState>(
  StylizationNotifier.new,
);

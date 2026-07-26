import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ocr/ocr_models.dart';
import '../services/api/ocr_api.dart';

part 'ocr_provider.freezed.dart';

/// OCR 流程步骤
enum OcrStep {
  input,       // 输入图片
  detection,   // 文字区域检测
  recognition, // OCR识别
  dictionary,  // 字典关联
  complete,    // 完成
}

/// OCR 完整状态
@freezed
class OcrState with _$OcrState {
  const factory OcrState({
    required InputImage? inputImage,
    required List<TextRegion> detectedRegions,
    required OcrResult? ocrResult,
    required CharacterDetail? selectedCharacter,
    required OcrStep currentStep,
    required bool isProcessing,
    required double progress,
    required String? errorMessage,
    required OcrDetector selectedDetector,
    required OcrRecognizer selectedRecognizer,
    required bool enableDictionaryLinking,
    required bool showSimplified,
    required bool verticalLayout,
  }) = _OcrState;

  factory OcrState.initial() => const OcrState(
        inputImage: null,
        detectedRegions: [],
        ocrResult: null,
        selectedCharacter: null,
        currentStep: OcrStep.input,
        isProcessing: false,
        progress: 0.0,
        errorMessage: null,
        selectedDetector: OcrDetector.dbnetPlusPlus,
        selectedRecognizer: OcrRecognizer.trocr,
        enableDictionaryLinking: true,
        showSimplified: false,
        verticalLayout: true,
      );
}

class OcrNotifier extends Notifier<OcrState> {
  final OcrApiService _apiService = OcrApiService();

  @override
  OcrState build() => OcrState.initial();

  /// 选择图片
  Future<void> pickImage(ImageSource source) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 4096,
        imageQuality: 95,
      );
      if (file == null) return;
      state = state.copyWith(
        inputImage: InputImage(path: file.path),
        currentStep: OcrStep.detection,
        isProcessing: false,
        progress: 0.1,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: '图片选择失败: $e');
    }
  }

  /// 文字区域检测 (集成 DBNet++/EAST/CRAFT 等)
  Future<void> detectText() async {
    if (state.inputImage == null) return;
    state = state.copyWith(isProcessing: true, progress: 0.2, errorMessage: null);
    try {
      final regions = await _apiService.detectTextRegions(
        state.inputImage!,
        detector: state.selectedDetector,
      );
      state = state.copyWith(
        detectedRegions: regions,
        currentStep: OcrStep.recognition,
        isProcessing: false,
        progress: 0.4,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: '文字检测失败: $e');
    }
  }

  /// OCR识别 (集成 TrOCR/ABINet/PARSeq 等)
  Future<void> recognizeText() async {
    if (state.inputImage == null) return;
    state = state.copyWith(isProcessing: true, progress: 0.5, errorMessage: null);
    try {
      final result = await _apiService.recognizeAncientText(
        image: state.inputImage!,
        regions: state.detectedRegions,
        recognizer: state.selectedRecognizer,
        enableDictionary: state.enableDictionaryLinking,
      );
      state = state.copyWith(
        ocrResult: result,
        currentStep: OcrStep.dictionary,
        isProcessing: false,
        progress: 0.8,
      );
      // 自动字典关联
      await queryDictionary(result);
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: '文字识别失败: $e');
    }
  }

  /// 字典关联查询
  Future<void> queryDictionary(OcrResult result) async {
    try {
      // 对不确定字符查询字典
      for (final char in result.uncertainCharacters) {
        await _apiService.queryCandidates(character: char, context: result.recognizedText);
      }
    } catch (_) {}
    state = state.copyWith(
      currentStep: OcrStep.complete,
      isProcessing: false,
      progress: 1.0,
    );
  }

  /// 查询单字详情
  Future<void> queryCharacterDetail(CharacterDetail detail) async {
    state = state.copyWith(selectedCharacter: detail);
  }

  void selectDetector(OcrDetector detector) {
    state = state.copyWith(selectedDetector: detector);
  }

  void selectRecognizer(OcrRecognizer recognizer) {
    state = state.copyWith(selectedRecognizer: recognizer);
  }

  void toggleDictionaryLinking() {
    state = state.copyWith(enableDictionaryLinking: !state.enableDictionaryLinking);
  }

  void toggleSimplified() {
    state = state.copyWith(showSimplified: !state.showSimplified);
  }

  void toggleVerticalLayout() {
    state = state.copyWith(verticalLayout: !state.verticalLayout);
  }

  void reset() => state = OcrState.initial();
  void clearError() => state = state.copyWith(errorMessage: null);
}

final ocrProvider = NotifierProvider<OcrNotifier, OcrState>(OcrNotifier.new);

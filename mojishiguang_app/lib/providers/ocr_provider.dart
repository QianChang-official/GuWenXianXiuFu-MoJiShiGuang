import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ocr/ocr_models.dart';
import '../services/api/ocr_api.dart';

class OcrState {
  final OcrInputImage? inputImage;
  final List<TextRegion> detectedRegions;
  final OcrResult? ocrResult;
  final CharacterDetail? selectedCharacter;
  final SemanticRestoration? semanticRestoration;
  final OcrStep currentStep;
  final OcrMode selectedMode;
  final bool isProcessing;
  final double progress;
  final String? errorMessage;
  final OcrDetector selectedDetector;
  final OcrRecognizer selectedRecognizer;
  final bool enableDictionaryLinking;
  final bool showSimplified;
  final bool verticalLayout;

  const OcrState({
    required this.inputImage,
    required this.detectedRegions,
    required this.ocrResult,
    required this.selectedCharacter,
    required this.semanticRestoration,
    required this.currentStep,
    required this.selectedMode,
    required this.isProcessing,
    required this.progress,
    required this.errorMessage,
    required this.selectedDetector,
    required this.selectedRecognizer,
    required this.enableDictionaryLinking,
    required this.showSimplified,
    required this.verticalLayout,
  });

  factory OcrState.initial() => const OcrState(
        inputImage: null,
        detectedRegions: [],
        ocrResult: null,
        selectedCharacter: null,
        semanticRestoration: null,
        currentStep: OcrStep.input,
        selectedMode: OcrMode.quick,
        isProcessing: false,
        progress: 0.0,
        errorMessage: null,
        selectedDetector: OcrDetector.dbnetPlusPlus,
        selectedRecognizer: OcrRecognizer.trocr,
        enableDictionaryLinking: true,
        showSimplified: false,
        verticalLayout: true,
      );

  String? get imagePath => inputImage?.filePath;

  OcrState copyWith({
    Object? inputImage = _unchanged,
    List<TextRegion>? detectedRegions,
    Object? ocrResult = _unchanged,
    Object? selectedCharacter = _unchanged,
    Object? semanticRestoration = _unchanged,
    OcrStep? currentStep,
    OcrMode? selectedMode,
    bool? isProcessing,
    double? progress,
    Object? errorMessage = _unchanged,
    OcrDetector? selectedDetector,
    OcrRecognizer? selectedRecognizer,
    bool? enableDictionaryLinking,
    bool? showSimplified,
    bool? verticalLayout,
  }) {
    return OcrState(
      inputImage: identical(inputImage, _unchanged)
          ? this.inputImage
          : inputImage as OcrInputImage?,
      detectedRegions: detectedRegions ?? this.detectedRegions,
      ocrResult: identical(ocrResult, _unchanged)
          ? this.ocrResult
          : ocrResult as OcrResult?,
      selectedCharacter: identical(selectedCharacter, _unchanged)
          ? this.selectedCharacter
          : selectedCharacter as CharacterDetail?,
      semanticRestoration: identical(semanticRestoration, _unchanged)
          ? this.semanticRestoration
          : semanticRestoration as SemanticRestoration?,
      currentStep: currentStep ?? this.currentStep,
      selectedMode: selectedMode ?? this.selectedMode,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
      selectedDetector: selectedDetector ?? this.selectedDetector,
      selectedRecognizer: selectedRecognizer ?? this.selectedRecognizer,
      enableDictionaryLinking:
          enableDictionaryLinking ?? this.enableDictionaryLinking,
      showSimplified: showSimplified ?? this.showSimplified,
      verticalLayout: verticalLayout ?? this.verticalLayout,
    );
  }
}

const Object _unchanged = Object();

class OcrNotifier extends Notifier<OcrState> {
  final OcrApiService _apiService = OcrApiService();

  @override
  OcrState build() => OcrState.initial();

  Future<void> pickImage(ImageSource source) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 4096,
        imageQuality: 95,
      );
      if (file == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }
      final List<int> bytes = await file.readAsBytes();
      state = state.copyWith(
        inputImage: OcrInputImage(filePath: file.path, bytes: bytes),
        detectedRegions: const [],
        ocrResult: null,
        selectedCharacter: null,
        semanticRestoration: null,
        currentStep: OcrStep.detection,
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

  Future<void> detectText() async {
    final OcrInputImage? image = state.inputImage;
    if (image == null) return;
    state = state.copyWith(
      isProcessing: true,
      currentStep: OcrStep.detection,
      progress: 0.2,
      errorMessage: null,
    );
    try {
      final List<TextRegion> regions = await _apiService.detectTextRegions(
        image.bytes,
        detector: state.selectedDetector,
      );
      state = state.copyWith(
        detectedRegions: regions,
        currentStep: OcrStep.recognition,
        isProcessing: false,
        progress: 0.4,
      );
    } catch (e) {
      state = state.copyWith(
        currentStep: OcrStep.error,
        isProcessing: false,
        errorMessage: '文字检测失败: $e',
      );
    }
  }

  Future<void> recognizeText() async {
    final OcrInputImage? image = state.inputImage;
    if (image == null) return;
    state = state.copyWith(
      isProcessing: true,
      currentStep: OcrStep.recognition,
      progress: 0.5,
      errorMessage: null,
    );
    try {
      final OcrResult result = await _apiService.recognizeAncientText(
        imageBytes: image.bytes,
        regions: state.detectedRegions,
        recognizer: state.selectedRecognizer,
        enableDictionary: state.enableDictionaryLinking,
      );
      state = state.copyWith(
        ocrResult: result,
        currentStep: OcrStep.dictionary,
        progress: 0.8,
      );
      await _completeRecognition(result);
    } catch (e) {
      state = state.copyWith(
        currentStep: OcrStep.error,
        isProcessing: false,
        errorMessage: '文字识别失败: $e',
      );
    }
  }

  Future<void> _completeRecognition(OcrResult result) async {
    try {
      if (state.enableDictionaryLinking) {
        for (final UncertainCharacter character in result.uncertainCharacters) {
          await _apiService.queryCandidates(
            character: character.character,
            context: result.fullText,
          );
        }
      }
      final SemanticRestoration semantic =
          await _apiService.restoreSemantics(result.fullText);
      state = state.copyWith(semanticRestoration: semantic);
    } catch (_) {
      // OCR 结果仍可用，候选字或语义增强失败不阻断主流程。
    }
    state = state.copyWith(
      currentStep: OcrStep.complete,
      isProcessing: false,
      progress: 1.0,
    );
  }

  Future<CharacterDetail> queryCharacterDetail(String character) async {
    final String context = state.ocrResult?.fullText ?? '';
    final List<CharacterCandidate> candidates =
        await _apiService.queryCandidates(
      character: character,
      context: context,
    );
    final DictionaryEntry dictionary =
        await _apiService.lookupDictionary(character);
    final VariationInfo variation =
        await _apiService.identifyVariation(character);
    final CharacterDetail detail = CharacterDetail(
      character: character,
      candidates: candidates,
      dictionary: dictionary,
      variation: variation,
    );
    state = state.copyWith(selectedCharacter: detail);
    return detail;
  }

  void selectMode(OcrMode mode) {
    state = state.copyWith(selectedMode: mode);
  }

  void selectDetector(OcrDetector detector) {
    state = state.copyWith(selectedDetector: detector);
  }

  void selectRecognizer(OcrRecognizer recognizer) {
    state = state.copyWith(selectedRecognizer: recognizer);
  }

  void toggleDictionaryLinking() {
    state = state.copyWith(
      enableDictionaryLinking: !state.enableDictionaryLinking,
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/ocr_provider.dart';
import '../character_detail.dart';

class CharacterDetailScreen extends ConsumerWidget {
  const CharacterDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(ocrProvider).selectedCharacter;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('单字详情')),
        body: const Center(child: Text('未选择字符')),
      );
    }

    return CharacterDetailPage(character: detail.character);
  }
}

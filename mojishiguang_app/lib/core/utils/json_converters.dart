import 'dart:typed_data';
import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<dynamic> json) => Uint8List.fromList(
      json.cast<num>().map((value) => value.toInt()).toList());

  @override
  List<int> toJson(Uint8List bytes) => bytes.toList(growable: false);
}

class NullableUint8ListConverter
    implements JsonConverter<Uint8List?, List<dynamic>?> {
  const NullableUint8ListConverter();

  @override
  Uint8List? fromJson(List<dynamic>? json) => json == null
      ? null
      : Uint8List.fromList(
          json.cast<num>().map((value) => value.toInt()).toList(),
        );

  @override
  List<int>? toJson(Uint8List? bytes) => bytes?.toList(growable: false);
}

class RectConverter implements JsonConverter<Rect, Map<String, dynamic>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) => Rect.fromLTRB(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['right'] as num).toDouble(),
        (json['bottom'] as num).toDouble(),
      );

  @override
  Map<String, dynamic> toJson(Rect rect) => {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      };
}

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) =>
      Offset((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble());

  @override
  Map<String, dynamic> toJson(Offset offset) => {
        'dx': offset.dx,
        'dy': offset.dy,
      };
}

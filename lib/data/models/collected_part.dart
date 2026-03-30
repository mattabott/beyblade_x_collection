import 'package:freezed_annotation/freezed_annotation.dart';

part 'collected_part.freezed.dart';
part 'collected_part.g.dart';

enum PartCategory { blade, ratchet, bit }

@freezed
class CollectedPart with _$CollectedPart {
  const factory CollectedPart({
    required String name,
    required PartCategory category,
    @Default(1) int quantity,
  }) = _CollectedPart;

  factory CollectedPart.fromJson(Map<String, dynamic> json) =>
      _$CollectedPartFromJson(json);
}

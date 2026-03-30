import 'package:freezed_annotation/freezed_annotation.dart';

part 'beyblade_slot.freezed.dart';
part 'beyblade_slot.g.dart';

@freezed
class BeybladeSlot with _$BeybladeSlot {
  const factory BeybladeSlot({
    String? blade,
    String? ratchet,
    String? bit,
  }) = _BeybladeSlot;

  factory BeybladeSlot.fromJson(Map<String, dynamic> json) =>
      _$BeybladeSlotFromJson(json);
}

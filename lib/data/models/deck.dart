import 'package:freezed_annotation/freezed_annotation.dart';
import 'beyblade_slot.dart';

part 'deck.freezed.dart';
part 'deck.g.dart';

@freezed
class Deck with _$Deck {
  const factory Deck({
    required String name,
    required List<BeybladeSlot> slots,
  }) = _Deck;

  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
}

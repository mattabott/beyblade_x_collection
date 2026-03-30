import 'package:freezed_annotation/freezed_annotation.dart';
import 'collected_part.dart';
import 'deck.dart';

part 'user_collection.freezed.dart';
part 'user_collection.g.dart';

@freezed
class UserCollection with _$UserCollection {
  const factory UserCollection({
    @Default([]) List<CollectedPart> parts,
    @Default([]) List<Deck> decks,
    @Default([]) List<String> wishlist,
  }) = _UserCollection;

  factory UserCollection.fromJson(Map<String, dynamic> json) =>
      _$UserCollectionFromJson(json);
}

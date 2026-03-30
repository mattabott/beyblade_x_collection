import 'package:flutter_test/flutter_test.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';

void main() {
  group('UserCollection', () {
    test('deserializes from JSON', () {
      final json = {
        'parts': [
          {'name': 'Sword Dran', 'category': 'blade', 'quantity': 2},
          {'name': '1-60', 'category': 'ratchet', 'quantity': 1},
        ],
        'decks': [
          {
            'name': 'Deck 1',
            'slots': [
              {'blade': 'Sword Dran', 'ratchet': '1-60', 'bit': 'Flat (F)'},
            ],
          },
        ],
        'wishlist': ['Phoenix Wing'],
      };
      final collection = UserCollection.fromJson(json);
      expect(collection.parts.length, 2);
      expect(collection.parts[0].name, 'Sword Dran');
      expect(collection.parts[0].category, PartCategory.blade);
      expect(collection.parts[0].quantity, 2);
      expect(collection.decks.length, 1);
      expect(collection.decks[0].name, 'Deck 1');
      expect(collection.wishlist, ['Phoenix Wing']);
    });

    test('serializes to JSON', () {
      final collection = UserCollection(
        parts: [CollectedPart(name: 'Sword Dran', category: PartCategory.blade, quantity: 1)],
        decks: [],
        wishlist: ['Rush (R)'],
      );
      final json = collection.toJson();
      expect((json['parts'] as List).length, 1);
      expect((json['wishlist'] as List).first, 'Rush (R)');
    });

    test('defaults to empty lists', () {
      final collection = UserCollection();
      expect(collection.parts, isEmpty);
      expect(collection.decks, isEmpty);
      expect(collection.wishlist, isEmpty);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/data/models/collected_part.dart';
import 'package:beyblade_x_collection/data/models/deck.dart';
import 'package:beyblade_x_collection/data/models/beyblade_slot.dart';
import 'package:beyblade_x_collection/data/models/user_collection.dart';
import 'package:beyblade_x_collection/data/repositories/collection_repository_impl.dart';
import 'package:beyblade_x_collection/domain/repositories/collection_repository.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(local: ref.watch(localDatasourceProvider));
});

final collectionProvider =
    AsyncNotifierProvider<CollectionNotifier, UserCollection>(
  CollectionNotifier.new,
);

class CollectionNotifier extends AsyncNotifier<UserCollection> {
  @override
  Future<UserCollection> build() async {
    final repo = ref.watch(collectionRepositoryProvider);
    return repo.getCollection();
  }

  Future<void> _save(UserCollection collection) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.saveCollection(collection);
    state = AsyncData(collection);
  }

  Future<void> addPart(String name, PartCategory category, {int quantity = 1}) async {
    final current = state.value;
    if (current == null) return;
    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere((p) => p.name == name && p.category == category);
    if (index >= 0) {
      parts[index] = parts[index].copyWith(quantity: parts[index].quantity + quantity);
    } else {
      parts.add(CollectedPart(name: name, category: category, quantity: quantity));
    }
    await _save(current.copyWith(parts: parts));
  }

  Future<void> removePart(String name, PartCategory category) async {
    final current = state.value;
    if (current == null) return;
    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere((p) => p.name == name && p.category == category);
    if (index >= 0) {
      if (parts[index].quantity > 1) {
        parts[index] = parts[index].copyWith(quantity: parts[index].quantity - 1);
      } else {
        parts.removeAt(index);
      }
    }
    await _save(current.copyWith(parts: parts));
  }

  Future<void> addToWishlist(String partName) async {
    final current = state.value;
    if (current == null) return;
    if (current.wishlist.contains(partName)) return;
    final wishlist = [...current.wishlist, partName];
    await _save(current.copyWith(wishlist: wishlist));
  }

  Future<void> removeFromWishlist(String partName) async {
    final current = state.value;
    if (current == null) return;
    final wishlist = current.wishlist.where((n) => n != partName).toList();
    await _save(current.copyWith(wishlist: wishlist));
  }

  Future<void> moveWishlistToCollection(String partName, PartCategory category) async {
    final current = state.value;
    if (current == null) return;
    final wishlist = current.wishlist.where((n) => n != partName).toList();
    final parts = List<CollectedPart>.from(current.parts);
    final index = parts.indexWhere((p) => p.name == partName && p.category == category);
    if (index >= 0) {
      parts[index] = parts[index].copyWith(quantity: parts[index].quantity + 1);
    } else {
      parts.add(CollectedPart(name: partName, category: category, quantity: 1));
    }
    await _save(current.copyWith(parts: parts, wishlist: wishlist));
  }

  Future<void> createDeck(String name) async {
    final current = state.value;
    if (current == null) return;
    final decks = [
      ...current.decks,
      Deck(name: name, slots: [const BeybladeSlot(), const BeybladeSlot(), const BeybladeSlot()]),
    ];
    await _save(current.copyWith(decks: decks));
  }

  Future<void> updateDeck(int index, Deck deck) async {
    final current = state.value;
    if (current == null) return;
    final decks = List<Deck>.from(current.decks);
    decks[index] = deck;
    await _save(current.copyWith(decks: decks));
  }

  Future<void> deleteDeck(int index) async {
    final current = state.value;
    if (current == null) return;
    final decks = List<Deck>.from(current.decks);
    decks.removeAt(index);
    await _save(current.copyWith(decks: decks));
  }

  Future<String> exportCollection() async {
    final current = state.value;
    if (current == null) return '';
    final repo = ref.read(collectionRepositoryProvider);
    return repo.exportCollection(current);
  }

  Future<bool> importCollection(String jsonString) async {
    final repo = ref.read(collectionRepositoryProvider);
    final imported = await repo.importCollection(jsonString);
    if (imported != null) {
      await _save(imported);
      return true;
    }
    return false;
  }
}

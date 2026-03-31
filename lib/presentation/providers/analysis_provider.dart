import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_combo.dart';
import 'package:beyblade_x_collection/domain/usecases/rank_parts.dart';
import 'package:beyblade_x_collection/domain/usecases/compare_parts.dart';
import 'package:beyblade_x_collection/domain/usecases/suggest_deck.dart';

final suggestComboProvider = Provider<SuggestCombo>((ref) => SuggestCombo());
final suggestDeckProvider = Provider<SuggestDeck>((ref) => SuggestDeck());
final rankPartsProvider = Provider<RankParts>((ref) => RankParts());
final comparePartsProvider = Provider<CompareParts>((ref) => CompareParts());

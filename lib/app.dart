import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/screens/home/home_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/collection/collection_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/collection/add_part_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/deck/deck_list_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/deck/deck_edit_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/analysis_menu_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/compare_parts_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/rank_parts_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/analysis/suggest_combo_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:beyblade_x_collection/presentation/screens/settings/settings_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen()),
    GoRoute(path: '/collection/add', builder: (_, __) => const AddPartScreen()),
    GoRoute(path: '/deck', builder: (_, __) => const DeckListScreen()),
    GoRoute(
      path: '/deck/edit/:index',
      builder: (_, state) {
        final index = int.parse(state.pathParameters['index']!);
        return DeckEditScreen(deckIndex: index);
      },
    ),
    GoRoute(path: '/analysis', builder: (_, __) => const AnalysisMenuScreen()),
    GoRoute(
        path: '/analysis/compare',
        builder: (_, __) => const ComparePartsScreen()),
    GoRoute(
        path: '/analysis/rank', builder: (_, __) => const RankPartsScreen()),
    GoRoute(
        path: '/analysis/suggest',
        builder: (_, __) => const SuggestComboScreen()),
    GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class BeybladeApp extends StatelessWidget {
  const BeybladeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Beyblade X Manager',
      theme: BeybladeTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

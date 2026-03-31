import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/widgets/deck_preview.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Deck'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDeckDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: collectionAsync.when(
        data: (collection) {
          if (collection.decks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined,
                      size: 64, color: BeybladeTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('Nessun deck creato',
                      style: TextStyle(color: BeybladeTheme.textSecondary)),
                  SizedBox(height: 8),
                  Text('Tocca + per creare un deck',
                      style: TextStyle(
                          color: BeybladeTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: collection.decks.length,
            itemBuilder: (context, index) => DeckPreview(
              deck: collection.decks[index],
              onTap: () => context.push('/deck/edit/$index'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Errore')),
      ),
    );
  }

  void _showCreateDeckDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo Deck'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome del deck'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(collectionProvider.notifier).createDeck(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
}

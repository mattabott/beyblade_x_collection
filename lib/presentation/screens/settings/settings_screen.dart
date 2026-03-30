import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';
import 'package:beyblade_x_collection/presentation/providers/collection_provider.dart';
import 'package:beyblade_x_collection/presentation/providers/parts_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(partsDatabaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'DATABASE',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.storage, color: BeybladeTheme.primary),
                  title: const Text('Versione Database'),
                  subtitle: dbAsync.when(
                    data: (db) => Text(
                      'v${db.version} — ${db.blades.length} blade, '
                      '${db.ratchets.length} ratchet, ${db.bits.length} bit',
                    ),
                    loading: () => const Text('Caricamento...'),
                    error: (_, __) => const Text('Errore'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download,
                      color: BeybladeTheme.primary),
                  title: const Text('Aggiorna Database'),
                  subtitle: const Text('Scarica l\'ultima versione dal server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _updateDatabase(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'COLLEZIONE',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.upload, color: Color(0xFF2ECC71)),
                  title: const Text('Esporta Collezione'),
                  subtitle: const Text('Condividi come file JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportCollection(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.download, color: Color(0xFF4A90D9)),
                  title: const Text('Importa Collezione'),
                  subtitle: const Text('Carica da file JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importCollection(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'INFO',
            style: TextStyle(
              color: BeybladeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline,
                  color: BeybladeTheme.textSecondary),
              title: Text('Beyblade X Manager'),
              subtitle: Text('v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDatabase(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aggiornamento in corso...'),
        backgroundColor: BeybladeTheme.primary,
      ),
    );
    await ref.read(partsDatabaseProvider.notifier).forceUpdate();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database aggiornato!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  Future<void> _exportCollection(BuildContext context, WidgetRef ref) async {
    final jsonString =
        await ref.read(collectionProvider.notifier).exportCollection();
    if (jsonString.isEmpty) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/beyblade_collection.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'La mia collezione Beyblade X',
    );
  }

  Future<void> _importCollection(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa Collezione'),
        content: const Text(
          'Questa operazione sostituira la collezione attuale. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success =
        await ref.read(collectionProvider.notifier).importCollection(jsonString);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Collezione importata!' : 'Errore: file non valido',
          ),
          backgroundColor:
              success ? const Color(0xFF2ECC71) : BeybladeTheme.secondary,
        ),
      );
    }
  }
}

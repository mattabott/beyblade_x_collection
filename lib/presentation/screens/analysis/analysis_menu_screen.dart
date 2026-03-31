import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beyblade_x_collection/core/theme/beyblade_theme.dart';

class AnalysisMenuScreen extends StatelessWidget {
  const AnalysisMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AnalysisTile(icon: Icons.compare_arrows, title: 'Confronta Parti', subtitle: 'Confronta stats di 2 o piu parti con radar chart', color: BeybladeTheme.secondary, onTap: () => context.push('/analysis/compare')),
            const SizedBox(height: 12),
            _AnalysisTile(icon: Icons.leaderboard, title: 'Classifica Parti', subtitle: 'Ordina le parti per statistica', color: const Color(0xFF2ECC71), onTap: () => context.push('/analysis/rank')),
            const SizedBox(height: 12),
            _AnalysisTile(icon: Icons.auto_awesome, title: 'Suggerisci Combo', subtitle: 'Trova le migliori combinazioni per strategia', color: BeybladeTheme.accent, onTap: () => context.push('/analysis/suggest')),
          ],
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AnalysisTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: Text(subtitle, style: const TextStyle(color: BeybladeTheme.textSecondary, fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Shared layout for the static legal pages.
class LegalScaffold extends StatelessWidget {
  final String subtitle;
  final String lastUpdated;
  final List<Widget> children;

  const LegalScaffold({
    super.key,
    required this.subtitle,
    this.lastUpdated = 'Last updated: June 2025',
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        foregroundColor: p.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('Budget Buddy',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: p.textSecondary)),
                Text(lastUpdated, style: TextStyle(color: p.textMuted, fontSize: 13)),
                const SizedBox(height: 32),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled paragraph section (`Section` in the React legal pages).
class LegalSection extends StatelessWidget {
  final String title;
  final String body;
  const LegalSection({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: p.textSecondary, fontSize: 14.5, height: 1.55)),
        ],
      ),
    );
  }
}

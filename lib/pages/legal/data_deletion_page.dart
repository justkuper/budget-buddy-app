import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class DataDeletionPage extends StatefulWidget {
  const DataDeletionPage({super.key});

  @override
  State<DataDeletionPage> createState() => _DataDeletionPageState();
}

class _DataDeletionPageState extends State<DataDeletionPage> {
  bool _done = false;

  static const _keys = ['bb-data', 'bb-data-version', 'bb-session', 'bb-plaid', 'bb-lang', 'bb-theme'];

  Future<void> _delete() async {
    for (final k in _keys) {
      await Prefs.instance.remove(k);
    }
    await context.read<AuthProvider>().signOut();
    if (mounted) setState(() => _done = true);
  }

  Future<void> _confirm() async {
    final p = AppPaletteScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.bgCard,
        title: const Row(children: [Text('🗑️  '), Text('Delete all data?')]),
        content: const Text('This permanently removes your data from this device. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _delete();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final user = context.watch<AuthProvider>().user;

    if (_done) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('Data deleted',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'All your Budget Buddy data has been removed from this device. Your account session has been cleared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 240,
                  child: PrimaryButton(label: 'Back to login', onPressed: () => context.go('/auth/login')),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('User Data Deletion',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.textPrimary)),
                const SizedBox(height: 24),
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: p.bgInput,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                              ? NetworkImage(user.avatar!)
                              : null,
                          child: (user.avatar == null || user.avatar!.isEmpty)
                              ? Text(user.name.isEmpty ? 'U' : user.name.characters.first.toUpperCase(),
                                  style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                            Text(user.email, style: TextStyle(color: p.textMuted, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                Text('Deleting your data will permanently remove the following from this device:',
                    style: TextStyle(color: p.textSecondary, height: 1.5)),
                const SizedBox(height: 8),
                ...[
                  'All transactions, budgets, and bills',
                  'Your account session and profile',
                  'Linked bank account connections',
                  'App preferences and settings',
                ].map((line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('•  $line', style: TextStyle(color: p.textSecondary)),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: const Text(
                    '⚠️ This action cannot be undone. Data stored at third-party providers (Google, Facebook, Plaid) must be deleted through those services separately.',
                    style: TextStyle(color: Color(0xFF8A5A00), fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 0,
                  ),
                  child: const Text('Delete my data'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Shared chrome for the auth screens: gradient logo header + a rounded card.
/// Ported from the `.auth-page` / `.auth-card` layout in Auth.css.
class AuthShell extends StatelessWidget {
  final String? tagline;
  final String emoji;
  final Widget card;
  final bool showControls;

  const AuthShell({
    super.key,
    this.tagline,
    this.emoji = '💰',
    required this.card,
    this.showControls = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  if (showControls)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: locale.toggle,
                          icon: Text(locale.lang == 'en' ? '🇺🇸' : '🇪🇸'),
                        ),
                        IconButton(
                          onPressed: theme.toggle,
                          icon: Text(theme.isDark ? '☀️' : '🌙'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Container(
                    width: 72, height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 16),
                  Text('Budget Buddy',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.textPrimary)),
                  if (tagline != null) ...[
                    const SizedBox(height: 6),
                    Text(tagline!, style: TextStyle(color: p.textMuted)),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: p.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: p.border),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
                      ],
                    ),
                    child: card,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error banner used across auth screens (`.auth-error`).
class AuthError extends StatelessWidget {
  final String message;
  const AuthError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD0D0)),
      ),
      child: Text('⚠️ $message', style: const TextStyle(color: AppColors.expense, fontSize: 13)),
    );
  }
}

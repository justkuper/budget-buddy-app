import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Header bar shown at the top of each main page (`TopBar.jsx`).
class TopBar extends StatelessWidget {
  final String? title;
  final bool showBack;
  final VoidCallback? onBack;

  const TopBar({super.key, this.title, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = context.watch<AuthProvider>().user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          if (showBack)
            _IconButton(icon: Icons.arrow_back, onTap: onBack ?? () => context.pop())
          else
            const Text('💰', style: TextStyle(fontSize: 24)),
          if (title != null) ...[
            const SizedBox(width: 12),
            Text(title!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.textPrimary)),
          ],
          const Spacer(),
          _IconButton(
            label: locale.lang == 'en' ? '🇺🇸' : '🇪🇸',
            onTap: locale.toggle,
          ),
          const SizedBox(width: 4),
          _IconButton(
            label: theme.isDark ? '☀️' : '🌙',
            onTap: theme.toggle,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: _Avatar(name: user?.name, avatar: user?.avatar),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  const _IconButton({this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 40, height: 40,
        child: Center(
          child: icon != null
              ? Icon(icon, color: p.textPrimary, size: 22)
              : Text(label ?? '', style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? name;
  final String? avatar;
  const _Avatar({this.name, this.avatar});

  @override
  Widget build(BuildContext context) {
    if (avatar != null && avatar!.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatar!));
    }
    final initial = (name == null || name!.isEmpty) ? 'U' : name!.characters.first.toUpperCase();
    return Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

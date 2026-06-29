import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'bottom_nav.dart';

const List<NavDestination> _sidebarItems = [
  NavDestination('/', '🏠', 'dashboard'),
  NavDestination('/transactions', '💸', 'transactions'),
  NavDestination('/budget', '🎯', 'budget'),
  NavDestination('/bills', '📋', 'bills'),
  NavDestination('/reports', '📊', 'reports'),
  NavDestination('/linked-accounts', '🏦', 'linkedAccounts'),
];

/// Desktop/web sidebar (`Sidebar.jsx`).
class Sidebar extends StatelessWidget {
  final String location;
  const Sidebar({super.key, required this.location});

  bool _isActive(String path) => path == '/' ? location == '/' : location.startsWith(path);

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: p.bgCard,
        border: Border(right: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text('Budget Buddy',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary)),
                ],
              ),
            ),
            ..._sidebarItems.map((item) {
              final active = _isActive(item.path);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go(item.path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Text(
                          context.t(item.key),
                          style: TextStyle(
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? AppColors.primary : p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            _ControlButton(
              icon: locale.lang == 'en' ? '🇺🇸' : '🇪🇸',
              label: locale.lang == 'en' ? 'English' : 'Español',
              onTap: locale.toggle,
            ),
            _ControlButton(
              icon: theme.isDark ? '☀️' : '🌙',
              label: theme.isDark ? 'Light mode' : 'Dark mode',
              onTap: theme.toggle,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/settings'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.bgInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _SidebarAvatar(name: user?.name, avatar: user?.avatar),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary, fontSize: 13)),
                            Text(user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, size: 18, color: p.textMuted),
                        onPressed: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/auth/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarAvatar extends StatelessWidget {
  final String? name;
  final String? avatar;
  const _SidebarAvatar({this.name, this.avatar});

  @override
  Widget build(BuildContext context) {
    if (avatar != null && avatar!.isNotEmpty) {
      return CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatar!));
    }
    final initial = (name == null || name!.isEmpty) ? 'U' : name!.characters.first.toUpperCase();
    return Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

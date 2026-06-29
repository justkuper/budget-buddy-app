import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class NavDestination {
  final String path;
  final String icon;
  final String key;
  const NavDestination(this.path, this.icon, this.key);
}

const List<NavDestination> kBottomNavItems = [
  NavDestination('/', '🏠', 'dashboard'),
  NavDestination('/transactions', '💸', 'transactions'),
  NavDestination('/budget', '🎯', 'budget'),
  NavDestination('/bills', '📋', 'bills'),
  NavDestination('/reports', '📊', 'reports'),
];

/// Mobile bottom navigation bar (`BottomNav.jsx`).
class BottomNav extends StatelessWidget {
  final String location;
  const BottomNav({super.key, required this.location});

  bool _isActive(String path) => path == '/' ? location == '/' : location.startsWith(path);

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.bgCard,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: kBottomNavItems.map((item) {
              final active = _isActive(item.path);
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                        context.t(item.key),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColors.primary : p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

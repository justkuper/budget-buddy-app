import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bottom_nav.dart';
import 'sidebar.dart';

/// Responsive app shell: a sidebar on wide layouts (≥768px, matching the React
/// desktop breakpoint), a bottom nav on narrow/mobile layouts.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const AppScaffold({super.key, required this.child, required this.location});

  static const double _desktopBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Row(
          children: [
            Sidebar(location: location),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: BottomNav(location: location),
    );
  }
}

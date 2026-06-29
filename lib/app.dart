import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scaffold.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/auth/two_factor_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/transactions/transactions_page.dart';
import 'pages/budget/budget_page.dart';
import 'pages/bills/bills_page.dart';
import 'pages/reports/reports_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/linked_accounts/linked_accounts_page.dart';
import 'pages/legal/terms_page.dart';
import 'pages/legal/privacy_page.dart';
import 'pages/legal/data_deletion_page.dart';

class BudgetBuddyApp extends StatefulWidget {
  const BudgetBuddyApp({super.key});

  @override
  State<BudgetBuddyApp> createState() => _BudgetBuddyAppState();
}

class _BudgetBuddyAppState extends State<BudgetBuddyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = _buildRouter(auth);
  }

  GoRouter _buildRouter(AuthProvider auth) {
    const publicPaths = {'/terms', '/privacy', '/data-deletion'};

    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggingIn = state.matchedLocation.startsWith('/auth');
        final isPublic = publicPaths.contains(state.matchedLocation);
        if (auth.loading) return null;
        if (!auth.isAuthenticated && !loggingIn && !isPublic) return '/auth/login';
        if (auth.isAuthenticated && loggingIn) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/auth/signup', builder: (_, __) => const SignupPage()),
        GoRoute(path: '/auth/2fa', builder: (_, __) => const TwoFactorPage()),
        GoRoute(path: '/auth/2fa-setup', builder: (_, __) => const TwoFactorPage(isSetup: true)),
        GoRoute(path: '/terms', builder: (_, __) => const TermsPage()),
        GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPage()),
        GoRoute(path: '/data-deletion', builder: (_, __) => const DataDeletionPage()),
        ShellRoute(
          builder: (context, state, child) =>
              AppScaffold(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
            GoRoute(path: '/transactions', builder: (_, __) => const TransactionsPage()),
            GoRoute(path: '/budget', builder: (_, __) => const BudgetPage()),
            GoRoute(path: '/bills', builder: (_, __) => const BillsPage()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
            GoRoute(path: '/linked-accounts', builder: (_, __) => const LinkedAccountsPage()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final palette = themeProvider.isDark ? AppPalette.dark : AppPalette.light;

    return AppPaletteScope(
      palette: palette,
      child: MaterialApp.router(
        title: 'Budget Buddy',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.mode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: localeProvider.locale,
        supportedLocales: const [Locale('en'), Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/plaid_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_client.dart';
import 'services/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.instance.init();

  final api = ApiClient();
  final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => ThemeProvider(platformBrightness: platformBrightness)),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, DataProvider, PlaidProvider>(
          create: (ctx) => PlaidProvider(
            api: api,
            auth: ctx.read<AuthProvider>(),
            data: ctx.read<DataProvider>(),
          ),
          update: (_, auth, data, plaid) {
            plaid!.updateDependencies(auth, data);
            return plaid;
          },
        ),
      ],
      child: const BudgetBuddyApp(),
    ),
  );
}

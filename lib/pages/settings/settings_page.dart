import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/plaid_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_client.dart';
import '../../services/prefs.dart';
import '../../services/social_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'MXN'];

  bool _editing = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _avatar = TextEditingController();

  String _currency = Prefs.instance.getString('bb-currency') ?? 'USD';
  bool _notif = Prefs.instance.getString('bb-notif-enabled') != 'false';
  bool _twoFa = Prefs.instance.getString('bb-2fa-enabled') != 'false';
  String? _socialLoading;
  String? _socialError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _avatar.dispose();
    super.dispose();
  }

  Future<void> _connect(String provider) async {
    setState(() {
      _socialLoading = provider;
      _socialError = null;
    });
    try {
      final result = provider == 'google' ? await SocialAuth.google() : await SocialAuth.facebook();
      final auth = context.read<AuthProvider>();
      if (provider == 'google') {
        await auth.linkGoogle(result.raw);
      } else {
        await auth.linkFacebook(result.raw);
      }
    } on SocialCancelled {
      // Ignore cancellation.
    } catch (e) {
      setState(() => _socialError = 'Failed to connect $provider: $e');
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
  }

  Future<void> _toggle2Fa() async {
    if (!_twoFa) {
      context.go('/auth/2fa-setup');
      return;
    }
    // Turning off → confirm with an emailed code.
    final email = context.read<AuthProvider>().user?.email;
    final api = context.read<ApiClient>();
    String? token;
    try {
      final data = (await api.post('/api/send-2fa-code', body: {'method': 'email', 'contact': email})) as Map;
      token = data['token']?.toString();
    } catch (e) {
      if (mounted) _snack(e.toString());
      return;
    }
    if (!mounted || token == null) return;

    final code = TextEditingController();
    final p = AppPaletteScope.of(context);
    final confirmed = await showAppSheet<bool>(context, (ctx) {
      String? err;
      return StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.t('disable2FATitle'),
                style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 8),
            Text(ctx.t('disable2FADesc', {'email': email ?? ''}),
                style: TextStyle(color: p.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            if (err != null) AuthErrorInline(err),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(counterText: '', hintText: '000000'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense, foregroundColor: Colors.white, elevation: 0),
                    onPressed: () async {
                      try {
                        await api.post('/api/verify-2fa-code', body: {'token': token, 'code': code.text});
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setSheet(() => err = e.toString());
                      }
                    },
                    child: Text(ctx.t('disable2FA')),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });

    if (confirmed == true) {
      await Prefs.instance.setString('bb-2fa-enabled', 'false');
      if (mounted) setState(() => _twoFa = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final plaid = context.watch<PlaidProvider>();
    final user = auth.user;

    return Column(
      children: [
        TopBar(title: context.t('settings'), showBack: true, onBack: () => context.go('/')),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Profile
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                                ? NetworkImage(user.avatar!)
                                : null,
                            child: (user?.avatar == null || user!.avatar!.isEmpty)
                                ? Text((user?.name.isNotEmpty ?? false) ? user!.name.characters.first.toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? 'User',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.textPrimary)),
                                Text(user?.email ?? '', style: TextStyle(color: p.textMuted, fontSize: 13)),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              _name.text = user?.name ?? '';
                              _email.text = user?.email ?? '';
                              _avatar.text = user?.avatar ?? '';
                              setState(() => _editing = true);
                            },
                            child: Text(context.t('edit')),
                          ),
                        ],
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        Divider(color: p.border),
                        _editField(context.t('name'), _name),
                        _editField(context.t('email'), _email),
                        _editField(context.t('profilePhotoUrl'), _avatar),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _editing = false),
                                child: Text(context.t('cancel')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: context.t('save'),
                                onPressed: () {
                                  auth.updateProfile(
                                    name: _name.text,
                                    email: _email.text,
                                    avatar: _avatar.text.isEmpty ? null : _avatar.text,
                                  );
                                  setState(() => _editing = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Preferences
                AppCard(
                  child: Column(
                    children: [
                      _row('🌙', context.t('darkMode'),
                          trailing: Switch(value: theme.isDark, onChanged: (_) => theme.toggle())),
                      _divider(p),
                      _row('🌐', context.t('language'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _langChip('en', '🇺🇸 EN', locale),
                              const SizedBox(width: 6),
                              _langChip('es', '🇪🇸 ES', locale),
                            ],
                          )),
                      _divider(p),
                      _row('🔐', context.t('twoFactorAuth'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_twoFa ? context.t('on') : context.t('off'),
                                  style: TextStyle(color: p.textMuted, fontSize: 13)),
                              const SizedBox(width: 8),
                              Switch(value: _twoFa, onChanged: (_) => _toggle2Fa()),
                            ],
                          )),
                      _divider(p),
                      _row('💵', context.t('currency'),
                          trailing: DropdownButton<String>(
                            value: _currency,
                            underline: const SizedBox.shrink(),
                            items: _currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              Prefs.instance.setString('bb-currency', v);
                              setState(() => _currency = v);
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Social
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.t('socialAccounts').toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textMuted, letterSpacing: 1)),
                      if (_socialError != null) ...[
                        const SizedBox(height: 8),
                        Text('⚠️ $_socialError', style: const TextStyle(color: AppColors.expense, fontSize: 13)),
                      ],
                      _socialRow('Facebook', user?.hasFacebook ?? false, 'facebook'),
                      _socialRow('Google', user?.hasGoogle ?? false, 'google'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: _row('🏦', context.t('linkedAccounts'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
                        onPressed: () => context.go('/linked-accounts'),
                        child: Text(plaid.allAccounts.isNotEmpty
                            ? '${plaid.allAccounts.length} ${context.t('connected')} →'
                            : '${context.t('connect')} →'),
                      )),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: _row('🔔', context.t('notifications'),
                      trailing: Switch(
                        value: _notif,
                        onChanged: (v) {
                          Prefs.instance.setString('bb-notif-enabled', v.toString());
                          setState(() => _notif = v);
                        },
                      )),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: _row('🚪', context.t('signOut'),
                      danger: true,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF0F0), foregroundColor: AppColors.danger, elevation: 0),
                        onPressed: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/auth/login');
                        },
                        child: Text(context.t('signOut')),
                      )),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text('Budget Buddy v1.0.0\nMade with ❤️ for smarter spending',
                      textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editField(String label, TextEditingController controller) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textMuted)),
          const SizedBox(height: 4),
          TextField(controller: controller),
        ],
      ),
    );
  }

  Widget _row(String icon, String label, {Widget? trailing, bool danger = false}) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: danger ? AppColors.expense : p.textPrimary)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _divider(AppPalette p) => Divider(color: p.border, height: 16);

  Widget _langChip(String code, String label, LocaleProvider locale) {
    final p = AppPaletteScope.of(context);
    final active = locale.lang == code;
    return GestureDetector(
      onTap: () => locale.setLang(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : p.bgInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : p.border, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : p.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _socialRow(String label, bool connected, String provider) {
    final p = AppPaletteScope.of(context);
    final busy = _socialLoading == provider;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: p.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: connected ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('● ${connected ? context.t('connected') : context.t('notConnected')}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: connected ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: busy
                ? null
                : connected
                    ? () => context.read<AuthProvider>().unlinkProvider(provider)
                    : () => _connect(provider),
            child: Text(busy
                ? '…'
                : connected
                    ? context.t('disconnect')
                    : context.t('connect')),
          ),
        ],
      ),
    );
  }
}

/// Small inline error used inside the disable-2FA sheet.
class AuthErrorInline extends StatelessWidget {
  final String message;
  const AuthErrorInline(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text('⚠️ $message', style: const TextStyle(color: AppColors.expense, fontSize: 13)),
    );
  }
}

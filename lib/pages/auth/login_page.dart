import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/social_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import 'auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final result = await context.read<AuthProvider>().signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.go(result.mfaRequired ? '/auth/2fa' : '/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _social(Future<SocialResult> Function() fn) async {
    setState(() => _error = null);
    try {
      final result = await fn();
      if (!mounted) return;
      final confirmed = await _confirmSocial(result);
      if (confirmed != true) return;
      setState(() => _loading = true);
      final auth = context.read<AuthProvider>();
      if (result.provider == 'google') {
        await auth.signInWithGoogle(result.token, result.raw);
      } else {
        await auth.signInWithFacebook(result.token, result.raw);
      }
      if (mounted) context.go('/');
    } on SocialCancelled {
      // User dismissed — no error.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _confirmSocial(SocialResult r) {
    final p = AppPaletteScope.of(context);
    return showAppSheet<bool>(context, (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            r.provider == 'google' ? ctx.t('continueWithGoogle') : ctx.t('continueWithFacebook'),
            style: TextStyle(fontWeight: FontWeight.w600, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(ctx.t('socialAccessNote'), style: TextStyle(color: p.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              if (r.avatar != null && r.avatar!.isNotEmpty)
                CircleAvatar(radius: 22, backgroundImage: NetworkImage(r.avatar!))
              else
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(r.name.isEmpty ? 'U' : r.name.characters.first.toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                  Text(r.email, style: TextStyle(color: p.textMuted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.t('cancel')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: PrimaryButton(label: ctx.t('continue'), onPressed: () => Navigator.of(ctx).pop(true)),
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final locale = context.watch<LocaleProvider>();
    return AuthShell(
      showControls: true,
      tagline: locale.lang == 'en' ? 'Smart money management' : 'Gestión inteligente de dinero',
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('welcome'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 16),
          if (_error != null) AuthError(_error!),
          _Field(controller: _email, label: context.t('email'), hint: 'hello@example.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _Field(controller: _password, label: context.t('password'), hint: '••••••••', obscure: true),
          const SizedBox(height: 16),
          PrimaryButton(label: context.t('signIn'), loading: _loading, onPressed: _loading ? null : _submit),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: p.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(context.t('orContinueWith'), style: TextStyle(color: p.textMuted, fontSize: 12)),
              ),
              Expanded(child: Divider(color: p.border)),
            ],
          ),
          const SizedBox(height: 16),
          _SocialButton(
            label: context.t('continueWithGoogle'),
            bg: Colors.white,
            fg: const Color(0xFF1A1A2E),
            border: p.border,
            onTap: _loading ? null : () => _social(SocialAuth.google),
          ),
          const SizedBox(height: 10),
          _SocialButton(
            label: context.t('continueWithFacebook'),
            bg: const Color(0xFF1877F2),
            fg: Colors.white,
            onTap: _loading ? null : () => _social(SocialAuth.facebook),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              children: [
                Text(context.t('dontHaveAccount'), style: TextStyle(color: p.textSecondary)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.go('/auth/signup'),
                  child: Text(context.t('createAccount'),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final VoidCallback? onTap;
  const _SocialButton({required this.label, required this.bg, required this.fg, this.border, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: border != null ? BorderSide(color: border!) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

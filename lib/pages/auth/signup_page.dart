import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import 'auth_shell.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
      final auth = context.read<AuthProvider>();
      await auth.signUp(_email.text.trim(), _password.text);
      await auth.signIn(_email.text.trim(), _password.text);
      if (mounted) context.go('/auth/2fa-setup');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return AuthShell(
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('createAccount'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 16),
          if (_error != null) AuthError(_error!),
          Text(context.t('email'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'hello@example.com'),
          ),
          const SizedBox(height: 12),
          Text(context.t('password'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Min 8 characters'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: context.t('createAccount'), loading: _loading, onPressed: _loading ? null : _submit),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              children: [
                Text(context.t('alreadyHaveAccount'), style: TextStyle(color: p.textSecondary)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: Text(context.t('signIn'),
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

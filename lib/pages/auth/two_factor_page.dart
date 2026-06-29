import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import 'auth_shell.dart';

/// Two-factor screen. In setup mode it walks choose → contact → code → success;
/// in login mode it goes straight to the code step. Ported from TwoFactorPage.jsx.
class TwoFactorPage extends StatefulWidget {
  final bool isSetup;
  const TwoFactorPage({super.key, this.isSetup = false});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

enum _Step { choose, contact, code, success }

class _TwoFactorPageState extends State<TwoFactorPage> {
  late _Step _step = widget.isSetup ? _Step.choose : _Step.code;
  String _method = 'email';
  final _contact = TextEditingController();
  final _code = TextEditingController();
  String? _verifyToken;
  bool _sending = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _contact.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _contact.dispose();
    _code.dispose();
    super.dispose();
  }

  ApiClient get _api => context.read<ApiClient>();

  Future<void> _sendCode() async {
    if (_contact.text.trim().isEmpty) return;
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      final data = (await _api.post('/api/send-2fa-code',
          body: {'method': _method, 'contact': _contact.text.trim()})) as Map;
      setState(() {
        _verifyToken = data['token']?.toString();
        _step = _Step.code;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final full = _code.text.trim();
    if (full.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_verifyToken != null) {
        await _api.post('/api/verify-2fa-code', body: {'token': _verifyToken, 'code': full});
      } else {
        await context.read<AuthProvider>().confirmMFA(full);
      }
      if (!mounted) return;
      if (widget.isSetup) {
        setState(() => _step = _Step.success);
      } else {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      emoji: _step == _Step.success ? '✅' : '🔐',
      card: switch (_step) {
        _Step.choose => _buildChoose(),
        _Step.contact => _buildContact(),
        _Step.code => _buildCode(),
        _Step.success => _buildSuccess(),
      },
    );
  }

  Widget _buildChoose() {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Secure your account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Two-factor authentication adds an extra layer of security. Choose how you\'d like to receive your verification code.',
          style: TextStyle(color: p.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _methodButton('📧', 'Email', "We'll send a code to your email address", 'email'),
        const SizedBox(height: 12),
        _methodButton('📱', 'Text Message (SMS)', "We'll send a code to your phone number", 'sms'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip for now'),
          ),
        ),
      ],
    );
  }

  Widget _methodButton(String icon, String title, String subtitle, String method) {
    final p = AppPaletteScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() {
        _method = method;
        if (method == 'email') {
          _contact.text = context.read<AuthProvider>().user?.email ?? '';
        } else {
          _contact.clear();
        }
        _step = _Step.contact;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.bgInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: p.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildContact() {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(() => setState(() => _step = _Step.choose)),
        Text(_method == 'email' ? 'Enter your email' : 'Enter your phone number',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
        const SizedBox(height: 8),
        Text(
          _method == 'email'
              ? "We'll send a 6-digit verification code to this address."
              : "We'll text a 6-digit verification code to this number. Standard rates may apply.",
          style: TextStyle(color: p.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (_error != null) AuthError(_error!),
        TextField(
          controller: _contact,
          keyboardType: _method == 'email' ? TextInputType.emailAddress : TextInputType.phone,
          decoration: InputDecoration(
            hintText: _method == 'email' ? 'hello@example.com' : '+1 (555) 000-0000',
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _sending ? 'Sending code…' : 'Send code',
          loading: _sending,
          onPressed: _contact.text.trim().isEmpty ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _buildCode() {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isSetup) _backButton(() => setState(() => _step = _Step.contact)),
        Text('Enter verification code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
        const SizedBox(height: 8),
        Text(
          widget.isSetup
              ? 'A 6-digit code was sent. Enter it below to confirm.'
              : 'Enter the 6-digit code sent to your verified ${_method == 'email' ? 'email' : 'phone'}.',
          style: TextStyle(color: p.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (_error != null) AuthError(_error!),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(counterText: '', hintText: '000000'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _loading ? 'Verifying…' : 'Verify',
          loading: _loading,
          onPressed: _code.text.trim().length < 6 ? null : _verify,
        ),
        const SizedBox(height: 8),
        if (widget.isSetup)
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: _sending ? null : _sendCode, child: const Text("Didn't receive a code? Resend")),
          ),
        if (!widget.isSetup)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (mounted) context.go('/auth/login');
              },
              child: Text('Sign in with a different account', style: TextStyle(color: p.textMuted)),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccess() {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Text('🎉', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 16),
        Text('2FA Enabled!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary)),
        const SizedBox(height: 8),
        Text(
          "Your account is now protected. You'll be asked for a code each time you sign in.",
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Go to dashboard', onPressed: () => context.go('/')),
      ],
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: const Text('← Back'),
      ),
    );
  }
}

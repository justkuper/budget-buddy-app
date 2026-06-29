import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../providers/plaid_provider.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Opens the Plaid Link flow. Fetches a link_token from our backend via
/// [PlaidProvider], hands the resulting public_token back for exchange.
/// Ported from PlaidLinkButton.jsx + react-plaid-link.
class PlaidLinkButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? label;
  final bool outlined;

  /// When this value changes to a positive number and Link is ready, the flow
  /// opens automatically (mirrors the React `autoOpen` bank-picker trigger).
  final int autoOpen;

  const PlaidLinkButton({
    super.key,
    this.onSuccess,
    this.label,
    this.outlined = false,
    this.autoOpen = 0,
  });

  @override
  State<PlaidLinkButton> createState() => _PlaidLinkButtonState();
}

class _PlaidLinkButtonState extends State<PlaidLinkButton> {
  StreamSubscription<LinkSuccess>? _successSub;
  StreamSubscription<LinkExit>? _exitSub;

  String? _linkToken;
  String? _tokenError;
  bool _ready = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _successSub = PlaidLink.onSuccess.listen(_onSuccess);
    _exitSub = PlaidLink.onExit.listen(_onExit);
    _fetchToken();
  }

  @override
  void dispose() {
    _successSub?.cancel();
    _exitSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlaidLinkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpen != oldWidget.autoOpen && widget.autoOpen > 0 && _ready) {
      _open();
    }
  }

  Future<void> _fetchToken() async {
    try {
      final token = await context.read<PlaidProvider>().getLinkToken();
      if (!mounted) return;
      await PlaidLink.create(configuration: LinkTokenConfiguration(token: token));
      if (!mounted) return;
      setState(() {
        _linkToken = token;
        _ready = true;
      });
    } catch (e) {
      if (mounted) setState(() => _tokenError = e.toString());
    }
  }

  Future<void> _onSuccess(LinkSuccess event) async {
    if (!mounted) return;
    setState(() => _opening = false);
    await context.read<PlaidProvider>().onPlaidSuccess(event.publicToken);
    if (!mounted) return;
    widget.onSuccess?.call();
  }

  void _onExit(LinkExit event) {
    if (mounted) setState(() => _opening = false);
  }

  void _open() {
    if (!_ready || _linkToken == null) return;
    setState(() => _opening = true);
    PlaidLink.open();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final plaidLoading = context.watch<PlaidProvider>().loading;

    if (_tokenError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('⚠️ $_tokenError',
            style: const TextStyle(color: AppColors.expense, fontSize: 13)),
      );
    }

    final label = widget.label ?? context.t('linkBankAccount');
    final busy = _opening || plaidLoading;

    if (widget.outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: (_ready && !busy) ? _open : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: p.bgInput,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            side: const BorderSide(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return PrimaryButton(
      label: busy ? context.t('loading') : label,
      loading: busy,
      onPressed: (_ready && !busy) ? _open : null,
    );
  }
}

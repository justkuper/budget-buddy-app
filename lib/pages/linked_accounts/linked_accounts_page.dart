import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/plaid_item.dart';
import '../../providers/locale_provider.dart';
import '../../providers/plaid_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/plaid_link_button.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/ui.dart';

class _Bank {
  final String name;
  final String logo;
  final Color color;
  const _Bank(this.name, this.logo, this.color);
}

const List<_Bank> _supportedBanks = [
  _Bank('Chase', '🏦', Color(0xFF117ACA)),
  _Bank('Bank of America', '🏦', Color(0xFFE31837)),
  _Bank('Wells Fargo', '🏦', Color(0xFFD71E28)),
  _Bank('Citibank', '🏦', Color(0xFF003B70)),
  _Bank('Capital One', '💳', Color(0xFF004977)),
  _Bank('US Bank', '🏦', Color(0xFF00274C)),
  _Bank('PNC Bank', '🏦', Color(0xFFF58025)),
  _Bank('TD Bank', '🏦', Color(0xFF34B233)),
  _Bank('American Express', '💳', Color(0xFF016FD0)),
  _Bank('Discover', '💳', Color(0xFFF76F20)),
  _Bank('Ally Bank', '🏦', Color(0xFF7F35B2)),
  _Bank('Charles Schwab', '📈', Color(0xFF00A0DF)),
  _Bank('Fidelity', '📈', Color(0xFF006400)),
  _Bank('Vanguard', '📈', Color(0xFF8B0000)),
  _Bank('Robinhood', '📈', Color(0xFF00C805)),
  _Bank('SoFi', '🏦', Color(0xFF7B2D8B)),
  _Bank('Chime', '🏦', Color(0xFF1EC677)),
  _Bank('Navy Federal CU', '🏦', Color(0xFF003087)),
  _Bank('USAA', '🏦', Color(0xFF003087)),
  _Bank('Regions Bank', '🏦', Color(0xFF006747)),
  _Bank('PayPal', '💰', Color(0xFF003087)),
];

class LinkedAccountsPage extends StatefulWidget {
  const LinkedAccountsPage({super.key});

  @override
  State<LinkedAccountsPage> createState() => _LinkedAccountsPageState();
}

class _LinkedAccountsPageState extends State<LinkedAccountsPage> {
  int _triggerOpen = 0;

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final plaid = context.watch<PlaidProvider>();
    final items = plaid.items;
    final totalAccounts = items.fold<int>(0, (s, i) => s + i.accounts.length);

    return Column(
      children: [
        TopBar(title: context.t('linkedAccounts')),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (items.isNotEmpty)
                  GradientCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('totalBankBalance'),
                            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(formatCurrency(plaid.totalBankBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          '$totalAccounts ${context.t('accountsLinked')} · ${items.length} ${context.t('banks')}',
                          style: const TextStyle(color: Color(0xA6FFFFFF), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (plaid.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD0D0)),
                    ),
                    child: Text('⚠️ ${plaid.error}',
                        style: const TextStyle(color: AppColors.expense, fontSize: 13)),
                  ),
                if (items.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: Column(
                      children: [
                        const Text('🏦', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 10),
                        Text(context.t('noAccountsLinked'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.textPrimary)),
                        const SizedBox(height: 8),
                        Text(context.t('linkAccountDesc'),
                            textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                  _BankPicker(onSelect: (_) => setState(() => _triggerOpen++)),
                  const SizedBox(height: 12),
                  PlaidLinkButton(
                    label: '🏦 ${context.t('linkBankAccount')}',
                    autoOpen: _triggerOpen,
                    onSuccess: () {},
                  ),
                ],
                ...items.map((item) => _InstitutionGroup(item: item)),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  PlaidLinkButton(
                    outlined: true,
                    label: '+ ${context.t('addAnotherBank')}',
                    onSuccess: () {},
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.bgInput,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Text('🔒 ${context.t('plaidSecurityNote')}',
                      style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.6)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BankPicker extends StatefulWidget {
  final ValueChanged<_Bank> onSelect;
  const _BankPicker({required this.onSelect});

  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  final _search = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final q = _search.text.toLowerCase().trim();
    final filtered = q.isEmpty
        ? _supportedBanks
        : _supportedBanks.where((b) => b.name.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: p.bgInput,
            borderRadius: _open
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(color: p.border, width: 1.5),
          ),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 12), child: Text('🔍')),
              Expanded(
                child: TextField(
                  controller: _search,
                  onTap: () => setState(() => _open = true),
                  onChanged: (_) => setState(() => _open = true),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: context.t('searchBank'),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_open ? Icons.expand_less : Icons.expand_more, color: p.textMuted),
                onPressed: () => setState(() => _open = !_open),
              ),
            ],
          ),
        ),
        if (_open)
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: p.bgCard,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: p.border, width: 1.5),
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(context.t('noBankMatch'),
                        textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 14)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final bank = filtered[i];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _open = false;
                            _search.clear();
                          });
                          widget.onSelect(bank);
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: bank.color.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(bank.logo),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(bank.name,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
                              ),
                              Text('${context.t('connect')} →',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

class _InstitutionGroup extends StatefulWidget {
  final PlaidItem item;
  const _InstitutionGroup({required this.item});

  @override
  State<_InstitutionGroup> createState() => _InstitutionGroupState();
}

class _InstitutionGroupState extends State<_InstitutionGroup> {
  bool _syncing = false;
  int? _newCount;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final added = await context.read<PlaidProvider>().syncTransactions();
      if (!mounted) return;
      setState(() => _newCount = added.length);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _newCount = null);
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  (item.institutionName?.isNotEmpty ?? false) ? item.institutionName!.characters.first : '🏦',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.institutionName ?? 'Bank',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    if (item.lastRefreshed != null)
                      Text('${context.t('lastUpdated')}: ${DateFormat('h:mm a').format(item.lastRefreshed!)}',
                          style: TextStyle(color: p.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _syncing ? null : _sync,
                child: Text(_syncing
                    ? '⟳'
                    : _newCount != null
                        ? '+$_newCount new'
                        : context.t('sync')),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => context.read<PlaidProvider>().removeItem(item.itemId),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
                child: Text(context.t('unlink')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.accounts.map((a) => _AccountCard(account: a)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final PlaidAccount account;
  const _AccountCard({required this.account});

  String _icon() {
    if (account.type == 'depository') {
      if (account.subtype == 'savings') return '💎';
      return '🏦';
    }
    if (account.type == 'credit') return '💳';
    if (account.type == 'investment') return '📈';
    if (account.type == 'loan') return '🏠';
    return '💰';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final isCredit = account.isCredit;
    final balance = isCredit
        ? account.balances.current
        : (account.balances.available ?? account.balances.current);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.expense : AppColors.primary).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(_icon(), style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.mask != null ? '${account.name} ••${account.mask}' : account.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                Text('${account.institutionName ?? ''} · ${account.subtype ?? account.type}',
                    style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance == null ? '—' : formatCurrency(balance, currency: account.balances.isoCurrencyCode),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isCredit ? AppColors.expense : AppColors.income),
              ),
              Text(isCredit ? context.t('balance') : context.t('available'),
                  style: TextStyle(color: p.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

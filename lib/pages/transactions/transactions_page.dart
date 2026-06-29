import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/data_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/transaction_sheet.dart';
import '../../widgets/ui.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filter = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(BuildContext context, DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_sameDay(d, today)) return context.t('today');
    if (_sameDay(d, yesterday)) return context.t('yesterday');
    return DateFormat('EEE, MMM d').format(d);
  }

  Future<void> _confirmDelete(String id) async {
    final p = AppPaletteScope.of(context);
    await showAppSheet<void>(context, (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ctx.t('deleteTransactionTitle'),
              style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 8),
          Text(ctx.t('deleteTransactionBody'), style: TextStyle(color: p.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(ctx.t('cancel')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0F0),
                    foregroundColor: AppColors.danger,
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<DataProvider>().deleteTransaction(id);
                    Navigator.of(ctx).pop();
                  },
                  child: Text(ctx.t('delete')),
                ),
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
    final data = context.watch<DataProvider>();

    final filtered = data.transactions.where((tx) {
      if (_filter == 'income' && !tx.isIncome) return false;
      if (_filter == 'expense' && tx.isIncome) return false;
      final q = _search.text.toLowerCase();
      if (q.isNotEmpty && !tx.description.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    final grouped = <String, List<TransactionModel>>{};
    for (final tx in filtered) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Stack(
      children: [
        Column(
          children: [
            TopBar(title: context.t('transactions')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: context.t('search'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final f in const ['all', 'income', 'expense']) ...[
                          FilterPill(
                            label: context.t(
                                f == 'all' ? 'filterAll' : f == 'income' ? 'filterIncome' : 'filterExpense'),
                            active: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (sortedDays.isEmpty)
                      EmptyState(
                        icon: '💸',
                        message: context.t('noTransactions'),
                        action: PrimaryButton(
                          label: context.t('addFirst'),
                          onPressed: () => showAppSheet(context, (_) => const TransactionSheet()),
                        ),
                      )
                    else
                      ...sortedDays.map((day) => _dayGroup(context, DateTime.parse(day), grouped[day]!, p)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: AppFab(onPressed: () => showAppSheet(context, (_) => const TransactionSheet())),
        ),
      ],
    );
  }

  Widget _dayGroup(BuildContext context, DateTime day, List<TransactionModel> txs, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_dayLabel(context, day).toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textMuted, letterSpacing: 0.5)),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(txs.length, (i) {
                final tx = txs[i];
                final cat = Categories.of(tx.category) ?? Categories.fallback;
                return InkWell(
                  onTap: () => _confirmDelete(tx.id),
                  child: Container(
                    decoration: BoxDecoration(
                      border: i < txs.length - 1 ? Border(bottom: BorderSide(color: p.border)) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: tx.logoUrl != null && tx.logoUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(tx.logoUrl!, width: 28, height: 28, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Text(cat.icon)),
                                    )
                                  : Text(cat.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            if (tx.plaidId != null)
                              Positioned(
                                bottom: -3, right: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('🏦', style: TextStyle(fontSize: 8)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.description,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  StatusBadge(label: context.t(tx.type), income: tx.isIncome),
                                  if (tx.pending) ...[
                                    const SizedBox(width: 6),
                                    Text('· pending', style: TextStyle(color: p.textMuted, fontSize: 11)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tx.isIncome ? AppColors.income : AppColors.expense)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

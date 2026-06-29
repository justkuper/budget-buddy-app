import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/plaid_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/transaction_sheet.dart';
import '../../widgets/ui.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'goodMorning';
    if (h < 17) return 'goodAfternoon';
    return 'goodEvening';
  }

  String _formatDate(BuildContext context, DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(d, today)) return context.t('today');
    if (sameDay(d, yesterday)) return context.t('yesterday');
    return DateFormat('MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final data = context.watch<DataProvider>();
    final plaid = context.watch<PlaidProvider>();
    final user = context.watch<AuthProvider>().user;

    final savings = data.monthlyIncome - data.monthlyExpenses;
    final recent = [...data.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final recentTop = recent.take(5).toList();

    final pie = data.spendingByCategory.entries
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pieTop = pie.take(5).toList();

    return Stack(
      children: [
        Column(
      children: [
        const TopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${context.t(_greetingKey())}, ${user?.name.split(' ').first ?? 'there'} 👋',
                    style: TextStyle(fontSize: 16, color: p.textPrimary),
                  ),
                ),
                _balanceCard(context, savings, data),
                if (plaid.allAccounts.isNotEmpty)
                  _linkedStrip(context, plaid),
                if (pieTop.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _spendingCard(context, pieTop),
                ],
                const SizedBox(height: 20),
                _recentSection(context, recentTop),
              ],
            ),
          ),
        ),
      ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: AppFab(
            onPressed: () => showAppSheet(context, (_) => const TransactionSheet()),
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(BuildContext context, double savings, DataProvider data) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('savings'), style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 14)),
          const SizedBox(height: 4),
          Text(formatCurrency(savings, decimals: false),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat(context, '↑', context.t('monthlyIncome'), data.monthlyIncome)),
              Container(width: 1, height: 36, color: const Color(0x33FFFFFF)),
              Expanded(child: _stat(context, '↓', context.t('monthlyExpenses'), data.monthlyExpenses)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String arrow, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(arrow, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 11)),
                Text(formatCurrency(value, decimals: false),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedStrip(BuildContext context, PlaidProvider plaid) {
    final p = AppPaletteScope.of(context);
    return AppCard(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => context.go('/linked-accounts'),
      child: Row(
        children: [
          const Text('🏦', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('linkedAccounts'),
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary, fontSize: 14)),
                Text('${plaid.allAccounts.length} ${context.t('accountsLinked')}',
                    style: TextStyle(color: p.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(plaid.totalBankBalance),
                  style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w800)),
              Text(context.t('totalBankBalance'), style: TextStyle(color: p.textMuted, fontSize: 11)),
            ],
          ),
          Icon(Icons.chevron_right, color: p.textMuted),
        ],
      ),
    );
  }

  Widget _spendingCard(BuildContext context, List<MapEntry<String, double>> pieTop) {
    final p = AppPaletteScope.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('spendingOverview'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    sections: pieTop.map((e) {
                      final cat = Categories.of(e.key) ?? Categories.fallback;
                      return PieChartSectionData(
                        value: e.value,
                        color: cat.color,
                        radius: 24,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: pieTop.map((e) {
                    final cat = Categories.of(e.key) ?? Categories.fallback;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${cat.icon} ${context.t(e.key)}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: p.textPrimary)),
                          ),
                          Text(formatCurrency(e.value, decimals: false),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentSection(BuildContext context, List<TransactionModel> recentTop) {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t('recentTransactions'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary)),
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: Text('${context.t('viewAll')} →'),
            ),
          ],
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: recentTop.isEmpty
              ? EmptyState(icon: '💸', message: context.t('noTransactions'))
              : Column(
                  children: List.generate(recentTop.length, (i) {
                    final tx = recentTop[i];
                    final cat = Categories.of(tx.category) ?? Categories.fallback;
                    return Container(
                      decoration: BoxDecoration(
                        border: i < recentTop.length - 1
                            ? Border(bottom: BorderSide(color: p.border))
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _txIcon(cat, tx.logoUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.description,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
                                Text(_formatDate(context, tx.date),
                                    style: TextStyle(color: p.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tx.isIncome ? AppColors.income : AppColors.expense),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  static Widget _txIcon(TxCategory cat, String? logoUrl) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(logoUrl, width: 28, height: 28, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(cat.icon)),
            )
          : Text(cat.icon, style: const TextStyle(fontSize: 20)),
    );
  }
}

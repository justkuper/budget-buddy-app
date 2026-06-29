import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/data_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/ui.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _periods = ['thisMonth', 'lastMonth', 'last3Months', 'last6Months', 'thisYear'];
  String _period = 'thisMonth';

  ({DateTime start, DateTime end}) _range() {
    final now = DateTime.now();
    switch (_period) {
      case 'lastMonth':
        return (
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case 'last3Months':
        return (start: DateTime(now.year, now.month - 2, 1), end: now);
      case 'last6Months':
        return (start: DateTime(now.year, now.month - 5, 1), end: now);
      case 'thisYear':
        return (start: DateTime(now.year, 1, 1), end: now);
      default:
        return (start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final all = context.watch<DataProvider>().transactions;
    final range = _range();

    final filtered = all
        .where((tx) => !tx.date.isBefore(range.start) && !tx.date.isAfter(range.end))
        .toList();
    final income = filtered.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expenses = filtered.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final savings = income - expenses;

    final catMap = <String, double>{};
    for (final t in filtered.where((t) => !t.isIncome)) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }
    final catData = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = catData.isEmpty ? 1.0 : catData.first.value;

    final trend = _trend(all);
    final maxBar = trend.fold<double>(0, (m, e) => [m, e.income, e.expenses].reduce((a, b) => a > b ? a : b));

    return Column(
      children: [
        TopBar(title: context.t('reports')),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final period in _periods) ...[
                        FilterPill(
                          label: context.t(period),
                          active: _period == period,
                          onTap: () => setState(() => _period = period),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _summary(context, 'totalEarned', income, AppColors.income)),
                    const SizedBox(width: 10),
                    Expanded(child: _summary(context, 'totalSpent', expenses, AppColors.expense)),
                    const SizedBox(width: 10),
                    Expanded(child: _summary(context, 'netSavings', savings,
                        savings >= 0 ? AppColors.income : AppColors.expense)),
                  ],
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.t('sixMonthOverview'),
                          style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
                      const SizedBox(height: 16),
                      SizedBox(height: 180, child: _barChart(trend, maxBar, p)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(AppColors.income, context.t('income'), p),
                          const SizedBox(width: 16),
                          _legendDot(AppColors.expense, context.t('expense'), p),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (catData.isNotEmpty)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('byCategory'),
                            style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
                        const SizedBox(height: 16),
                        ...catData.map((e) {
                          final cat = Categories.of(e.key) ?? Categories.fallback;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${cat.icon} ${context.t(e.key)}',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
                                    Text(formatCurrency(e.value, decimals: false),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ProgressBar(fraction: e.value / maxCat, color: cat.color),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                if (filtered.isEmpty)
                  EmptyState(icon: '📊', message: context.t('noData')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<({String month, double income, double expenses})> _trend(List<TransactionModel> all) {
    final now = DateTime.now();
    final months = <({String month, double income, double expenses})>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final start = d;
      final end = DateTime(d.year, d.month + 1, 0, 23, 59, 59);
      final inc = all
          .where((t) => t.isIncome && !t.date.isBefore(start) && !t.date.isAfter(end))
          .fold<double>(0, (s, t) => s + t.amount);
      final exp = all
          .where((t) => !t.isIncome && !t.date.isBefore(start) && !t.date.isAfter(end))
          .fold<double>(0, (s, t) => s + t.amount);
      months.add((month: DateFormat('MMM').format(d), income: inc, expenses: exp));
    }
    return months;
  }

  Widget _barChart(List<({String month, double income, double expenses})> trend, double maxBar, AppPalette p) {
    return BarChart(
      BarChartData(
        maxY: maxBar == 0 ? 1 : maxBar * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: p.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(trend[i].month, style: TextStyle(fontSize: 11, color: p.textMuted)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(trend.length, (i) {
          return BarChartGroupData(x: i, barsSpace: 3, barRods: [
            BarChartRodData(toY: trend[i].income, color: AppColors.income, width: 10, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: trend[i].expenses, color: AppColors.expense, width: 10, borderRadius: BorderRadius.circular(4)),
          ]);
        }),
      ),
    );
  }

  Widget _summary(BuildContext context, String key, double value, Color color) {
    final p = AppPaletteScope.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Text(context.t(key).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(formatCurrency(value, decimals: false),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, AppPalette p) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
      ],
    );
  }
}

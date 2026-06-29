import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/data_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/ui.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  List<String> _availableCats(List<BudgetModel> budgets) {
    final existing = budgets.map((b) => b.category).toSet();
    return Categories.expense.where((c) => !existing.contains(c)).toList();
  }

  Future<void> _openAdd(BuildContext context, List<String> available) async {
    if (available.isEmpty) return;
    final data = context.read<DataProvider>();
    final p = AppPaletteScope.of(context);
    String selected = available.first;
    final limit = TextEditingController();

    await showAppSheet<void>(context, (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.t('addBudget'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 20),
            Text(ctx.t('category'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selected,
              items: available
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${Categories.of(c)!.icon} ${ctx.t(c)}'),
                      ))
                  .toList(),
              onChanged: (v) => setSheet(() => selected = v ?? selected),
            ),
            const SizedBox(height: 16),
            Text(ctx.t('budgetLimit'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
            ),
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
                  flex: 2,
                  child: PrimaryButton(
                    label: ctx.t('save'),
                    onPressed: () {
                      final value = double.tryParse(limit.text);
                      if (value == null) return;
                      data.addBudget(category: selected, limit: value);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final budgets = data.budgets;
    final spending = data.spendingByCategory;
    final available = _availableCats(budgets);

    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + (spending[b.category] ?? 0));
    final double overallFraction =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0).toDouble() : 0.0;

    return Stack(
      children: [
        Column(
          children: [
            TopBar(title: context.t('budgetGoals')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (budgets.isNotEmpty)
                      GradientCard(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('monthlyBudget'),
                                style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(formatCurrency(totalBudget, decimals: false),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              '${formatCurrency(totalSpent, decimals: false)} ${context.t('spent')} · ${formatCurrency((totalBudget - totalSpent).clamp(0, double.infinity), decimals: false)} ${context.t('remaining')}',
                              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: overallFraction,
                                minHeight: 8,
                                backgroundColor: const Color(0x33FFFFFF),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (budgets.isEmpty)
                      EmptyState(
                        icon: '🎯',
                        message: context.t('noBudgets'),
                        action: PrimaryButton(
                          label: context.t('setBudget'),
                          onPressed: () => _openAdd(context, available),
                        ),
                      )
                    else
                      ...budgets.map((b) => _BudgetCard(
                            budget: b,
                            spent: spending[b.category] ?? 0,
                            onDelete: () => data.deleteBudget(b.id),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (available.isNotEmpty)
          Positioned(
            right: 20,
            bottom: 24,
            child: AppFab(onPressed: () => _openAdd(context, available)),
          ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final double spent;
  final VoidCallback onDelete;
  const _BudgetCard({required this.budget, required this.spent, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final cat = Categories.of(budget.category) ?? Categories.fallback;
    final double fraction =
        budget.limit > 0 ? (spent / budget.limit).clamp(0.0, 1.0).toDouble() : 0.0;
    final remaining = budget.limit - spent;
    final over = spent > budget.limit;

    final gradient = over
        ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)])
        : fraction > 0.8
            ? const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFFA000)])
            : LinearGradient(colors: [cat.color, cat.color.withValues(alpha: 0.7)]);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t(budget.category),
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text('${formatCurrency(spent, decimals: false)} / ${formatCurrency(budget.limit, decimals: false)}',
                        style: TextStyle(color: p.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(
                  label: over ? context.t('overBudget') : context.t('onTrack'), income: !over),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: p.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(fraction: fraction, gradient: gradient),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(fraction * 100).round()}% ${context.t('spent')}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              Text(
                over
                    ? '${formatCurrency(remaining.abs(), decimals: false)} ${context.t('overBudget')}'
                    : '${formatCurrency(remaining, decimals: false)} ${context.t('remaining')}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: over ? AppColors.expense : AppColors.income),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

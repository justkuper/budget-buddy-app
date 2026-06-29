import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bill.dart';
import '../../models/category.dart';
import '../../providers/data_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/ui.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final data = context.read<DataProvider>();
    final p = AppPaletteScope.of(context);
    final name = TextEditingController();
    final amount = TextEditingController();
    DateTime dueDate = DateTime.now();
    String recurring = 'monthly';
    String category = 'housing';

    await showAppSheet<void>(context, (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.t('addBill'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 20),
            _label(ctx, ctx.t('description')),
            TextField(controller: name, decoration: const InputDecoration(hintText: 'Netflix, Rent...')),
            const SizedBox(height: 16),
            _label(ctx, ctx.t('amount')),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(ctx, ctx.t('dueDate')),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setSheet(() => dueDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(DateFormat('MMM d, yyyy').format(dueDate),
                              style: TextStyle(color: p.textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(ctx, ctx.t('recurring')),
                      DropdownButtonFormField<String>(
                        value: recurring,
                        items: [
                          DropdownMenuItem(value: 'weekly', child: Text(ctx.t('weekly'))),
                          DropdownMenuItem(value: 'monthly', child: Text(ctx.t('monthly'))),
                          DropdownMenuItem(value: 'yearly', child: Text(ctx.t('yearly'))),
                        ],
                        onChanged: (v) => setSheet(() => recurring = v ?? recurring),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label(ctx, ctx.t('category')),
            DropdownButtonFormField<String>(
              value: category,
              items: Categories.expense
                  .map((c) => DropdownMenuItem(value: c, child: Text('${Categories.of(c)!.icon} ${ctx.t(c)}')))
                  .toList(),
              onChanged: (v) => setSheet(() => category = v ?? category),
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
                      final value = double.tryParse(amount.text);
                      if (name.text.trim().isEmpty || value == null) return;
                      data.addBill(
                        name: name.text.trim(),
                        amount: value,
                        // Local noon avoids UTC day-shift (matches the React app).
                        dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day, 12),
                        recurring: recurring,
                        category: category,
                      );
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

  static Widget _label(BuildContext context, String text) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final data = context.watch<DataProvider>();
    final bills = [...data.bills]..sort((a, b) {
        if (a.paid != b.paid) return a.paid ? 1 : -1;
        return a.dueDate.compareTo(b.dueDate);
      });

    final totalUnpaid = data.bills.where((b) => !b.paid).fold<double>(0, (s, b) => s + b.amount);
    final overdueCount = data.bills.where((b) => !b.paid && b.daysUntil < 0).length;

    return Stack(
      children: [
        Column(
          children: [
            TopBar(title: context.t('upcomingBills')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (data.bills.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              child: Column(
                                children: [
                                  Text(context.t('unpaid'), style: TextStyle(color: p.textMuted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(formatCurrency(totalUnpaid),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.expense)),
                                ],
                              ),
                            ),
                          ),
                          if (overdueCount > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppCard(
                                borderColor: AppColors.expense,
                                child: Column(
                                  children: [
                                    Text(context.t('overdue'), style: TextStyle(color: p.textMuted, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('$overdueCount bills',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.expense)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (data.bills.isEmpty)
                      EmptyState(
                        icon: '📋',
                        message: context.t('noBills'),
                        action: PrimaryButton(
                          label: context.t('addFirstBill'),
                          onPressed: () => _openAdd(context),
                        ),
                      )
                    else
                      ...bills.map((b) => _BillCard(
                            bill: b,
                            onTogglePaid: () => data.toggleBillPaid(b.id),
                            onDelete: () => data.deleteBill(b.id),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: AppFab(onPressed: () => _openAdd(context)),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;
  const _BillCard({required this.bill, required this.onTogglePaid, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    final cat = Categories.of(bill.category) ?? Categories.fallback;
    final days = bill.daysUntil;
    final overdue = days < 0;
    final soon = days >= 0 && days <= 3;

    return Opacity(
      opacity: bill.paid ? 0.6 : 1,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(bill.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                          ),
                          const SizedBox(width: 8),
                          if (bill.paid) StatusBadge(label: context.t('paid'), income: true),
                          if (!bill.paid && overdue) StatusBadge(label: context.t('overdue'), income: false),
                          if (!bill.paid && soon && !overdue)
                            Text('⚠️ ${context.t('dueIn')} $days ${context.t('days')}',
                                style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bill.recurring.isNotEmpty ? '${context.t(bill.recurring)} · ' : ''}${DateFormat('MMM d').format(bill.dueDate)}',
                        style: TextStyle(color: p.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(formatCurrency(bill.amount),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: bill.paid
                            ? p.textMuted
                            : overdue
                                ? AppColors.expense
                                : p.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: bill.paid
                      ? OutlinedButton(
                          onPressed: onTogglePaid,
                          child: Text('↩ ${context.t('unpaid')}'),
                        )
                      : ElevatedButton(
                          onPressed: onTogglePaid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.income,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Text('✓ ${context.t('markPaid')}'),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF0F0),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                    ),
                    child: Text(context.t('delete')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

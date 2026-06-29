import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/data_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Add-transaction form, shown inside [showAppSheet]. Ported from
/// TransactionSheet.jsx.
class TransactionSheet extends StatefulWidget {
  final String defaultType;
  const TransactionSheet({super.key, this.defaultType = 'expense'});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  late String _type = widget.defaultType;
  late String _category = widget.defaultType == 'expense' ? 'food' : 'salary';
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _date = DateTime.now();

  List<String> get _cats => _type == 'expense' ? Categories.expense : Categories.income;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;
    final desc = _descController.text.trim().isEmpty ? context.t(_category) : _descController.text.trim();
    context.read<DataProvider>().addTransaction(
          type: _type,
          amount: amount,
          category: _category,
          description: desc,
          date: _date,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPaletteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.t('addTransaction'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _typeButton('expense', '↓ ${context.t('expense')}', AppColors.expense)),
            const SizedBox(width: 8),
            Expanded(child: _typeButton('income', '↑ ${context.t('income')}', AppColors.income)),
          ],
        ),
        const SizedBox(height: 20),
        _label(context.t('amount')),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
        ),
        const SizedBox(height: 16),
        _label(context.t('category')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cats.map((c) {
            final cat = Categories.of(c)!;
            final selected = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? cat.color.withValues(alpha: 0.13) : p.bgInput,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: selected ? cat.color : p.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.icon),
                    const SizedBox(width: 5),
                    Text(context.t(c),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color: p.textPrimary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _label(context.t('description')),
        TextField(
          controller: _descController,
          decoration: InputDecoration(hintText: context.t(_category)),
        ),
        const SizedBox(height: 16),
        _label(context.t('date')),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text(DateFormat('EEE, MMM d, yyyy').format(_date),
                style: TextStyle(color: p.textPrimary)),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: p.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.t('cancel'), style: TextStyle(color: p.textPrimary)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: PrimaryButton(label: context.t('save'), onPressed: _save)),
          ],
        ),
      ],
    );
  }

  Widget _typeButton(String type, String label, Color color) {
    final p = AppPaletteScope.of(context);
    final active = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _category = type == 'expense' ? 'food' : 'salary';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.13) : p.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : p.border, width: 2),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: active ? color : p.textSecondary)),
      ),
    );
  }

  Widget _label(String text) {
    final p = AppPaletteScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary)),
    );
  }
}

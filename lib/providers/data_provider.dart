import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/bill.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/prefs.dart';

/// Local-first store for transactions, budgets and bills, ported from
/// DataContext.jsx. Persists to `bb-data` with a schema version guard.
class DataProvider extends ChangeNotifier {
  static const _dataKey = 'bb-data';
  static const _versionKey = 'bb-data-version';
  static const _dataVersion = '2';

  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<BillModel> _bills = [];

  DataProvider() {
    _load();
  }

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  List<BillModel> get bills => List.unmodifiable(_bills);

  void _load() {
    final storedVersion = Prefs.instance.getString(_versionKey);
    if (storedVersion != _dataVersion) {
      Prefs.instance.remove(_dataKey);
      Prefs.instance.setString(_versionKey, _dataVersion);
      return;
    }
    final raw = Prefs.instance.getString(_dataKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _transactions = ((map['transactions'] as List?) ?? const [])
          .map((e) => TransactionModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _budgets = ((map['budgets'] as List?) ?? const [])
          .map((e) => BudgetModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _bills = ((map['bills'] as List?) ?? const [])
          .map((e) => BillModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Corrupt store — start empty.
    }
  }

  void _save() {
    Prefs.instance.setString(
      _dataKey,
      jsonEncode({
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'budgets': _budgets.map((b) => b.toJson()).toList(),
        'bills': _bills.map((b) => b.toJson()).toList(),
      }),
    );
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  // ── Transactions ───────────────────────────────────────────────────────────
  void addTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
  }) {
    _transactions.insert(
      0,
      TransactionModel(
        id: _uuid.v4(),
        type: type,
        amount: amount,
        category: category,
        description: description,
        date: date,
      ),
    );
    _commit();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _commit();
  }

  /// Upsert by id — adds new and replaces existing (handles Plaid modified).
  void importTransactions(List<TransactionModel> incoming) {
    final incomingIds = incoming.map((t) => t.id).toSet();
    final kept = _transactions.where((t) => !incomingIds.contains(t.id)).toList();
    _transactions = [...incoming, ...kept];
    _commit();
  }

  void removeTransactions(List<String> ids) {
    final set = ids.toSet();
    _transactions.removeWhere((t) => set.contains(t.id));
    _commit();
  }

  // ── Budgets ────────────────────────────────────────────────────────────────
  void addBudget({required String category, required double limit}) {
    _budgets = [..._budgets, BudgetModel(id: _uuid.v4(), category: category, limit: limit)];
    _commit();
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    _commit();
  }

  // ── Bills ──────────────────────────────────────────────────────────────────
  void addBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    required String recurring,
    required String category,
  }) {
    _bills = [
      ..._bills,
      BillModel(
        id: _uuid.v4(),
        name: name,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        category: category,
      ),
    ];
    _commit();
  }

  void deleteBill(String id) {
    _bills.removeWhere((b) => b.id == id);
    _commit();
  }

  void toggleBillPaid(String id) {
    _bills = _bills.map((b) => b.id == id ? b.copyWith(paid: !b.paid) : b).toList();
    _commit();
  }

  // ── Derived (this month) ───────────────────────────────────────────────────
  List<TransactionModel> get _thisMonth {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _transactions.where((t) => !t.date.isBefore(monthStart)).toList();
  }

  double get monthlyIncome =>
      _thisMonth.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get monthlyExpenses =>
      _thisMonth.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final t in _thisMonth.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}

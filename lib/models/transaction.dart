/// A single transaction. Mirrors the React app's transaction shape, including
/// the Plaid-derived fields (`plaidId`, `pending`, `logoUrl`).
class TransactionModel {
  final String id;
  final String? plaidId;
  final String description;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final DateTime date;
  final bool pending;
  final String? logoUrl;

  const TransactionModel({
    required this.id,
    this.plaidId,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.pending = false,
    this.logoUrl,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toJson() => {
        'id': id,
        if (plaidId != null) 'plaid_id': plaidId,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date.toIso8601String(),
        'pending': pending,
        if (logoUrl != null) 'logo_url': logoUrl,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      plaidId: json['plaid_id'] as String?,
      description: (json['description'] as String?) ?? 'Unknown',
      amount: (json['amount'] as num).toDouble(),
      type: (json['type'] as String?) ?? 'expense',
      category: (json['category'] as String?) ?? 'other',
      date: DateTime.parse(json['date'] as String),
      pending: (json['pending'] as bool?) ?? false,
      logoUrl: json['logo_url'] as String?,
    );
  }

  /// Maps a raw Plaid transaction (as returned by the backend) into our model,
  /// matching PlaidContext._mapTransactions.
  factory TransactionModel.fromPlaid(Map<String, dynamic> tx) {
    final id = (tx['transactionId'] ?? tx['id']) as String;
    final amount = (tx['amount'] as num).toDouble();
    final rawDate = tx['date'];
    return TransactionModel(
      id: id,
      plaidId: id,
      description: (tx['name'] ?? tx['description'] ?? 'Unknown') as String,
      amount: amount.abs(),
      type: amount > 0 ? 'expense' : 'income',
      category: (tx['category'] as String?) ?? 'other',
      date: rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now(),
      pending: (tx['pending'] as bool?) ?? false,
      logoUrl: (tx['logoUrl'] ?? tx['logo_url']) as String?,
    );
  }
}

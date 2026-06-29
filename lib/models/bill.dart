/// A recurring or one-off bill.
class BillModel {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String recurring; // 'weekly' | 'monthly' | 'yearly'
  final String category;
  final bool paid;

  const BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.recurring,
    required this.category,
    this.paid = false,
  });

  BillModel copyWith({bool? paid}) => BillModel(
        id: id,
        name: name,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        category: category,
        paid: paid ?? this.paid,
      );

  /// Whole days until the due date (ceil), matching the React `daysUntil`.
  int get daysUntil =>
      (dueDate.difference(DateTime.now()).inMilliseconds / 86400000).ceil();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'recurring': recurring,
        'category': category,
        'paid': paid,
      };

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        recurring: (json['recurring'] as String?) ?? 'monthly',
        category: (json['category'] as String?) ?? 'housing',
        paid: (json['paid'] as bool?) ?? false,
      );
}

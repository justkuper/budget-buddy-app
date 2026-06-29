/// A budget goal for a spending category.
class BudgetModel {
  final String id;
  final String category;
  final double limit;

  const BudgetModel({required this.id, required this.category, required this.limit});

  Map<String, dynamic> toJson() => {'id': id, 'category': category, 'limit': limit};

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        category: json['category'] as String,
        limit: (json['limit'] as num).toDouble(),
      );
}

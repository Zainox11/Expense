import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';

part 'budget_model.g.dart';

/// Hive data model for monthly budget entries.
@HiveType(typeId: 2)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final double spent;

  @HiveField(5)
  final int month;

  @HiveField(6)
  final int year;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.spent,
    required this.month,
    required this.year,
  });

  // ---------------------------------------------------------------------------
  // Entity mapping
  // ---------------------------------------------------------------------------

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      amount: entity.amount,
      spent: entity.spent,
      month: entity.month,
      year: entity.year,
    );
  }

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      spent: spent,
      month: month,
      year: year,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialization
  // ---------------------------------------------------------------------------

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'spent': spent,
      'month': month,
      'year': year,
    };
  }

  // ---------------------------------------------------------------------------
  // Copy helper
  // ---------------------------------------------------------------------------

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    double? spent,
    int? month,
    int? year,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

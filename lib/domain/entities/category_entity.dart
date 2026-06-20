import 'package:expense_tracker/domain/entities/transaction_entity.dart';

/// Core domain entity representing a spending/income category.
/// Categories have an icon (Material icon code point), color, and type.
class CategoryEntity {
  final String id;
  final String name;
  final int iconCode; // Material icon code point (e.g., Icons.restaurant.codePoint)
  final int colorValue; // Color stored as int (e.g., Color(0xFF00E676).value)
  final TransactionType type; // Whether this category is for income or expense
  final bool isDefault; // True for built-in categories, false for user-created

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  /// Whether this is an expense category
  bool get isExpenseCategory => type == TransactionType.expense;

  /// Whether this is an income category
  bool get isIncomeCategory => type == TransactionType.income;

  /// Creates a copy with the given fields replaced
  CategoryEntity copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    TransactionType? type,
    bool? isDefault,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconCode == other.iconCode &&
          colorValue == other.colorValue &&
          type == other.type &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, name, iconCode, colorValue, type, isDefault);

  @override
  String toString() {
    return 'CategoryEntity(id: $id, name: $name, type: $type, isDefault: $isDefault)';
  }
}

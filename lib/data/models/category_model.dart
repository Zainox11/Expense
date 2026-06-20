import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';

part 'category_model.g.dart';

/// Hive data model for expense / income categories.
@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final int colorValue;

  /// 0 = income, 1 = expense
  @HiveField(4)
  final int type;

  @HiveField(5)
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    required this.isDefault,
  });

  // ---------------------------------------------------------------------------
  // Entity mapping
  // ---------------------------------------------------------------------------

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      iconCode: entity.iconCode,
      colorValue: entity.colorValue,
      type: entity.type == TransactionType.income ? 0 : 1,
      isDefault: entity.isDefault,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
      type: type == 0 ? TransactionType.income : TransactionType.expense,
      isDefault: isDefault,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialization
  // ---------------------------------------------------------------------------

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['iconCode'] as int,
      colorValue: json['colorValue'] as int,
      type: json['type'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'type': type,
      'isDefault': isDefault,
    };
  }

  // ---------------------------------------------------------------------------
  // Copy helper
  // ---------------------------------------------------------------------------

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    int? type,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

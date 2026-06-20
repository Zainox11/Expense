import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

/// Hive data model for transactions.
///
/// Stores all temporal values as millisecondsSinceEpoch (int) and
/// enums as integer indices for compact, version-safe Hive storage.
@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  /// 0 = income, 1 = expense
  @HiveField(3)
  final int type;

  @HiveField(4)
  final String categoryId;

  @HiveField(5)
  final String note;

  /// Stored as millisecondsSinceEpoch
  @HiveField(6)
  final int date;

  /// Stored as millisecondsSinceEpoch
  @HiveField(7)
  final int createdAt;

  /// 0 = none, 1 = daily, 2 = weekly, 3 = monthly, 4 = yearly
  @HiveField(8)
  final int recurrence;

  @HiveField(9)
  final bool isSynced;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.recurrence,
    required this.isSynced,
  });

  // ---------------------------------------------------------------------------
  // Entity mapping
  // ---------------------------------------------------------------------------

  /// Creates a [TransactionModel] from a domain [TransactionEntity].
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      type: entity.type == TransactionType.income ? 0 : 1,
      categoryId: entity.categoryId,
      note: entity.note,
      date: entity.date.millisecondsSinceEpoch,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      recurrence: _recurrenceToInt(entity.recurrence),
      isSynced: entity.isSynced,
    );
  }

  /// Converts this model back to a domain [TransactionEntity].
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      amount: amount,
      type: type == 0 ? TransactionType.income : TransactionType.expense,
      categoryId: categoryId,
      note: note,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      recurrence: _intToRecurrence(recurrence),
      isSynced: isSynced,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialization (Firestore)
  // ---------------------------------------------------------------------------

  /// Creates a [TransactionModel] from a Firestore document map.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as int,
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      date: json['date'] as int,
      createdAt: json['createdAt'] as int,
      recurrence: json['recurrence'] as int? ?? 0,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  /// Converts this model to a JSON map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'note': note,
      'date': date,
      'createdAt': createdAt,
      'recurrence': recurrence,
      'isSynced': isSynced,
    };
  }

  // ---------------------------------------------------------------------------
  // Copy helper
  // ---------------------------------------------------------------------------

  /// Returns a copy of this model with selected fields replaced.
  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    int? type,
    String? categoryId,
    String? note,
    int? date,
    int? createdAt,
    int? recurrence,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      recurrence: recurrence ?? this.recurrence,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static int _recurrenceToInt(RecurrenceType r) {
    switch (r) {
      case RecurrenceType.none:
        return 0;
      case RecurrenceType.daily:
        return 1;
      case RecurrenceType.weekly:
        return 2;
      case RecurrenceType.monthly:
        return 3;
      case RecurrenceType.yearly:
        return 4;
    }
  }

  static RecurrenceType _intToRecurrence(int value) {
    switch (value) {
      case 1:
        return RecurrenceType.daily;
      case 2:
        return RecurrenceType.weekly;
      case 3:
        return RecurrenceType.monthly;
      case 4:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.none;
    }
  }
}

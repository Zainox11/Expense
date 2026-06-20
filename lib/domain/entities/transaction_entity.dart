/// Represents the type of financial transaction.
enum TransactionType {
  income,
  expense,
}

/// Represents how often a transaction recurs.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Core domain entity representing a financial transaction.
/// This is a pure Dart class with no framework dependencies.
class TransactionEntity {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final RecurrenceType recurrence;
  final bool isSynced;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    required this.date,
    required this.createdAt,
    this.recurrence = RecurrenceType.none,
    this.isSynced = false,
  });

  /// Whether this transaction is income
  bool get isIncome => type == TransactionType.income;

  /// Whether this transaction is an expense
  bool get isExpense => type == TransactionType.expense;

  /// Whether this transaction has a recurrence schedule
  bool get isRecurring => recurrence != RecurrenceType.none;

  /// Returns the signed amount (negative for expenses)
  double get signedAmount => isExpense ? -amount : amount;

  /// Creates a copy with the given fields replaced
  TransactionEntity copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    RecurrenceType? recurrence,
    bool? isSynced,
  }) {
    return TransactionEntity(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          amount == other.amount &&
          type == other.type &&
          categoryId == other.categoryId &&
          note == other.note &&
          date == other.date &&
          createdAt == other.createdAt &&
          recurrence == other.recurrence &&
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        amount,
        type,
        categoryId,
        note,
        date,
        createdAt,
        recurrence,
        isSynced,
      );

  @override
  String toString() {
    return 'TransactionEntity(id: $id, amount: $amount, type: $type, '
        'category: $categoryId, date: $date)';
  }
}

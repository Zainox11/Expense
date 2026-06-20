import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/data/datasources/local/hive_transaction_datasource.dart';
import 'package:expense_tracker/data/datasources/local/hive_category_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_transaction_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_category_datasource.dart';
import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';

/// Provider for local transaction datasource
final hiveTransactionDatasourceProvider = Provider<HiveTransactionDatasource>((ref) {
  return HiveTransactionDatasource(Hive.box<TransactionModel>('transactions'));
});

/// Provider for remote transaction datasource
final firebaseTransactionDatasourceProvider = Provider<FirebaseTransactionDatasource>((ref) {
  return FirebaseTransactionDatasource();
});



/// Provider for transaction repository
final transactionRepositoryProvider = Provider<TransactionRepositoryImpl>((ref) {
  return TransactionRepositoryImpl(
    localDatasource: ref.watch(hiveTransactionDatasourceProvider),
    remoteDatasource: ref.watch(firebaseTransactionDatasourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// Date filter state
class DateFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  DateFilter({
    required this.startDate,
    required this.endDate,
    this.label = 'This Month',
  });

  factory DateFilter.thisMonth() {
    final now = DateTime.now();
    return DateFilter(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      label: 'This Month',
    );
  }

  factory DateFilter.lastMonth() {
    final now = DateTime.now();
    return DateFilter(
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0, 23, 59, 59),
      label: 'Last Month',
    );
  }

  factory DateFilter.thisYear() {
    final now = DateTime.now();
    return DateFilter(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31, 23, 59, 59),
      label: 'This Year',
    );
  }

  factory DateFilter.custom(DateTime start, DateTime end) {
    return DateFilter(
      startDate: start,
      endDate: end,
      label: 'Custom',
    );
  }
}

/// Date filter provider
final dateFilterProvider = StateProvider<DateFilter>((ref) {
  return DateFilter.thisMonth();
});

/// Transaction type filter
final transactionTypeFilterProvider = StateProvider<TransactionType?>((ref) {
  return null; // null means show all
});

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Main transaction list provider
final transactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(transactionRepositoryProvider);
  final dateFilter = ref.watch(dateFilterProvider);

  return repo.getTransactions(
    user.id,
    startDate: dateFilter.startDate,
    endDate: dateFilter.endDate,
  );
});

/// Filtered transactions (by type and search)
final filteredTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final typeFilter = ref.watch(transactionTypeFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

  var filtered = transactions;

  // Filter by type
  if (typeFilter != null) {
    filtered = filtered.where((t) => t.type == typeFilter).toList();
  }

  // Filter by search
  if (searchQuery.isNotEmpty) {
    filtered = filtered.where((t) {
      final category = categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => CategoryEntity(
          id: '', name: 'Unknown', iconCode: 0, colorValue: 0,
          type: TransactionType.expense, isDefault: false,
        ),
      );
      return t.note.toLowerCase().contains(searchQuery) ||
          category.name.toLowerCase().contains(searchQuery) ||
          t.amount.toString().contains(searchQuery);
    }).toList();
  }

  // Sort by date descending
  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

/// Total income for current filter
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Total expense for current filter
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Current balance
final balanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

/// Transaction count by type
final transactionCountProvider = Provider<Map<TransactionType, int>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  return {
    TransactionType.income: transactions.where((t) => t.type == TransactionType.income).length,
    TransactionType.expense: transactions.where((t) => t.type == TransactionType.expense).length,
  };
});

/// Recent transactions (last 5)
final recentTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions.take(5).toList();
});

/// Transaction notifier for CRUD operations
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepositoryImpl _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> addTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTransaction(transaction);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTransaction(transaction);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTransaction(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

/// Provider for transaction actions
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repo);
});

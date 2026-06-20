import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/data/datasources/local/hive_budget_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_budget_datasource.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/core/network/connectivity_service.dart';

/// Provider for local budget datasource
final hiveBudgetDatasourceProvider = Provider<HiveBudgetDatasource>((ref) {
  return HiveBudgetDatasource(Hive.box<BudgetModel>('budgets'));
});

/// Provider for remote budget datasource
final firebaseBudgetDatasourceProvider = Provider<FirebaseBudgetDatasource>((ref) {
  return FirebaseBudgetDatasource();
});

/// Provider for budget repository
final budgetRepositoryProvider = Provider<BudgetRepositoryImpl>((ref) {
  return BudgetRepositoryImpl(
    localDatasource: ref.watch(hiveBudgetDatasourceProvider),
    remoteDatasource: ref.watch(firebaseBudgetDatasourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// Selected month/year for budget view
class BudgetPeriod {
  final int month;
  final int year;

  BudgetPeriod({required this.month, required this.year});

  factory BudgetPeriod.current() {
    final now = DateTime.now();
    return BudgetPeriod(month: now.month, year: now.year);
  }

  String get label {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month]} $year';
  }
}

/// Budget period provider
final budgetPeriodProvider = StateProvider<BudgetPeriod>((ref) {
  return BudgetPeriod.current();
});

/// Budgets for current period
final budgetsProvider = FutureProvider<List<BudgetEntity>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(budgetRepositoryProvider);
  final period = ref.watch(budgetPeriodProvider);

  return repo.getBudgetsByMonth(user.id, period.month, period.year);
});

/// Budgets with actual spending calculated from transactions
final budgetsWithSpendingProvider = FutureProvider<List<BudgetEntity>>((ref) async {
  final budgets = ref.watch(budgetsProvider).valueOrNull ?? [];
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

  if (budgets.isEmpty) return [];

  return budgets.map((budget) {
    // Calculate actual spending for this category in this period
    final spent = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.categoryId == budget.categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);

    return budget.copyWith(spent: spent);
  }).toList();
});

/// Total budget amount
final totalBudgetProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetsWithSpendingProvider).valueOrNull ?? [];
  return budgets.fold(0.0, (sum, b) => sum + b.amount);
});

/// Total budget spent
final totalBudgetSpentProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetsWithSpendingProvider).valueOrNull ?? [];
  return budgets.fold(0.0, (sum, b) => sum + b.spent);
});

/// Budget utilization percentage
final budgetUtilizationProvider = Provider<double>((ref) {
  final total = ref.watch(totalBudgetProvider);
  final spent = ref.watch(totalBudgetSpentProvider);
  if (total == 0) return 0;
  return (spent / total * 100).clamp(0, 200);
});

/// Budgets that are over limit
final overBudgetProvider = Provider<List<BudgetEntity>>((ref) {
  final budgets = ref.watch(budgetsWithSpendingProvider).valueOrNull ?? [];
  return budgets.where((b) => b.spent > b.amount).toList();
});

/// Budget notifier for CRUD operations
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final BudgetRepositoryImpl _repository;

  BudgetNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> setBudget(BudgetEntity budget) async {
    state = const AsyncValue.loading();
    try {
      await _repository.setBudget(budget);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBudget(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

/// Provider for budget actions
final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetNotifier(repo);
});

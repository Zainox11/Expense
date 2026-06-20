import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';

/// Monthly analytics data model
class MonthlyAnalytics {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryExpenses;
  final Map<String, double> categoryIncomes;
  final List<DailyData> dailyExpenses;
  final List<DailyData> dailyIncomes;

  MonthlyAnalytics({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryExpenses,
    required this.categoryIncomes,
    required this.dailyExpenses,
    required this.dailyIncomes,
  });
}

/// Daily aggregated data for line/bar charts
class DailyData {
  final DateTime date;
  final double amount;

  DailyData({required this.date, required this.amount});
}

/// Category analytics data
class CategoryAnalytics {
  final CategoryEntity category;
  final double amount;
  final double percentage;
  final int count;

  CategoryAnalytics({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

/// Monthly analytics provider
final monthlyAnalyticsProvider = Provider<MonthlyAnalytics>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final dateFilter = ref.watch(dateFilterProvider);
  final now = DateTime.now();

  final income = transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  final expense = transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  // Category-wise expenses
  final categoryExpenses = <String, double>{};
  final categoryIncomes = <String, double>{};

  for (final t in transactions) {
    if (t.type == TransactionType.expense) {
      categoryExpenses[t.categoryId] =
          (categoryExpenses[t.categoryId] ?? 0) + t.amount;
    } else {
      categoryIncomes[t.categoryId] =
          (categoryIncomes[t.categoryId] ?? 0) + t.amount;
    }
  }

  // Daily aggregation
  final dailyExpenseMap = <int, double>{};
  final dailyIncomeMap = <int, double>{};

  for (final t in transactions) {
    final day = t.date.day;
    if (t.type == TransactionType.expense) {
      dailyExpenseMap[day] = (dailyExpenseMap[day] ?? 0) + t.amount;
    } else {
      dailyIncomeMap[day] = (dailyIncomeMap[day] ?? 0) + t.amount;
    }
  }

  // Determine number of days in the period
  final daysInMonth = DateTime(
    dateFilter.startDate.year,
    dateFilter.startDate.month + 1,
    0,
  ).day;

  final dailyExpenses = List.generate(daysInMonth, (i) {
    return DailyData(
      date: DateTime(dateFilter.startDate.year, dateFilter.startDate.month, i + 1),
      amount: dailyExpenseMap[i + 1] ?? 0,
    );
  });

  final dailyIncomes = List.generate(daysInMonth, (i) {
    return DailyData(
      date: DateTime(dateFilter.startDate.year, dateFilter.startDate.month, i + 1),
      amount: dailyIncomeMap[i + 1] ?? 0,
    );
  });

  return MonthlyAnalytics(
    month: dateFilter.startDate.month,
    year: dateFilter.startDate.year,
    totalIncome: income,
    totalExpense: expense,
    balance: income - expense,
    categoryExpenses: categoryExpenses,
    categoryIncomes: categoryIncomes,
    dailyExpenses: dailyExpenses,
    dailyIncomes: dailyIncomes,
  );
});

/// Category expense analytics (for pie chart)
final categoryExpenseAnalyticsProvider = Provider<List<CategoryAnalytics>>((ref) {
  final analytics = ref.watch(monthlyAnalyticsProvider);
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

  if (analytics.totalExpense == 0) return [];

  final result = <CategoryAnalytics>[];
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

  for (final entry in analytics.categoryExpenses.entries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => CategoryEntity(
        id: entry.key, name: 'Unknown', iconCode: 0, colorValue: 0xFF78909C,
        type: TransactionType.expense, isDefault: false,
      ),
    );

    final count = transactions
        .where((t) => t.categoryId == entry.key && t.type == TransactionType.expense)
        .length;

    result.add(CategoryAnalytics(
      category: category,
      amount: entry.value,
      percentage: (entry.value / analytics.totalExpense * 100),
      count: count,
    ));
  }

  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
});

/// Category income analytics
final categoryIncomeAnalyticsProvider = Provider<List<CategoryAnalytics>>((ref) {
  final analytics = ref.watch(monthlyAnalyticsProvider);
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

  if (analytics.totalIncome == 0) return [];

  final result = <CategoryAnalytics>[];
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

  for (final entry in analytics.categoryIncomes.entries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => CategoryEntity(
        id: entry.key, name: 'Unknown', iconCode: 0, colorValue: 0xFF78909C,
        type: TransactionType.income, isDefault: false,
      ),
    );

    final count = transactions
        .where((t) => t.categoryId == entry.key && t.type == TransactionType.income)
        .length;

    result.add(CategoryAnalytics(
      category: category,
      amount: entry.value,
      percentage: (entry.value / analytics.totalIncome * 100),
      count: count,
    ));
  }

  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
});

/// Last 6 months expense trend for line chart
final expenseTrendProvider = FutureProvider<List<MonthlyTrend>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final trends = <MonthlyTrend>[];

  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final transactions = await repo.getTransactions(
      user.id,
      startDate: month,
      endDate: endOfMonth,
    );

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    trends.add(MonthlyTrend(
      month: month.month,
      year: month.year,
      income: income,
      expense: expense,
    ));
  }

  return trends;
});

/// Monthly trend data point
class MonthlyTrend {
  final int month;
  final int year;
  final double income;
  final double expense;

  MonthlyTrend({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
  });

  String get monthLabel {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}

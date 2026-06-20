import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/data/datasources/local/hive_category_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_category_datasource.dart';
import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';

/// Provider for local category datasource
final hiveCategoryDatasourceProvider = Provider<HiveCategoryDatasource>((ref) {
  return HiveCategoryDatasource(Hive.box<CategoryModel>('categories'));
});

/// Provider for remote category datasource
final firebaseCategoryDatasourceProvider = Provider<FirebaseCategoryDatasource>((ref) {
  return FirebaseCategoryDatasource();
});

/// Provider for category repository
final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(
    localDatasource: ref.watch(hiveCategoryDatasourceProvider),
    remoteDatasource: ref.watch(firebaseCategoryDatasourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// Default expense categories
List<CategoryEntity> get defaultExpenseCategories => [
      CategoryEntity(
        id: 'food',
        name: 'Food & Dining',
        iconCode: Icons.restaurant.codePoint,
        colorValue: 0xFFFF7043,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'transport',
        name: 'Transportation',
        iconCode: Icons.directions_car.codePoint,
        colorValue: 0xFF42A5F5,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'shopping',
        name: 'Shopping',
        iconCode: Icons.shopping_bag.codePoint,
        colorValue: 0xFFAB47BC,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'entertainment',
        name: 'Entertainment',
        iconCode: Icons.movie.codePoint,
        colorValue: 0xFFEC407A,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'health',
        name: 'Health & Fitness',
        iconCode: Icons.favorite.codePoint,
        colorValue: 0xFF66BB6A,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'bills',
        name: 'Bills & Utilities',
        iconCode: Icons.receipt_long.codePoint,
        colorValue: 0xFFFFA726,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'education',
        name: 'Education',
        iconCode: Icons.school.codePoint,
        colorValue: 0xFF26C6DA,
        type: TransactionType.expense,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'other_expense',
        name: 'Other',
        iconCode: Icons.more_horiz.codePoint,
        colorValue: 0xFF78909C,
        type: TransactionType.expense,
        isDefault: true,
      ),
    ];

/// Default income categories
List<CategoryEntity> get defaultIncomeCategories => [
      CategoryEntity(
        id: 'salary',
        name: 'Salary',
        iconCode: Icons.account_balance_wallet.codePoint,
        colorValue: 0xFF00E676,
        type: TransactionType.income,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'freelance',
        name: 'Freelance',
        iconCode: Icons.laptop_mac.codePoint,
        colorValue: 0xFF00BCD4,
        type: TransactionType.income,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'investment',
        name: 'Investment',
        iconCode: Icons.trending_up.codePoint,
        colorValue: 0xFFFFD740,
        type: TransactionType.income,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'gift',
        name: 'Gift',
        iconCode: Icons.card_giftcard.codePoint,
        colorValue: 0xFFE040FB,
        type: TransactionType.income,
        isDefault: true,
      ),
      CategoryEntity(
        id: 'other_income',
        name: 'Other',
        iconCode: Icons.more_horiz.codePoint,
        colorValue: 0xFF78909C,
        type: TransactionType.income,
        isDefault: true,
      ),
    ];

/// All categories provider
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [...defaultExpenseCategories, ...defaultIncomeCategories];

  final repo = ref.watch(categoryRepositoryProvider);
  final categories = await repo.getCategories();

  if (categories.isEmpty) {
    // Initialize with default categories
    final defaults = [...defaultExpenseCategories, ...defaultIncomeCategories];
    for (final cat in defaults) {
      await repo.addCategory(cat);
    }
    return defaults;
  }

  return categories;
});

/// Expense categories only
final expenseCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  return categories.where((c) => c.type == TransactionType.expense).toList();
});

/// Income categories only
final incomeCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  return categories.where((c) => c.type == TransactionType.income).toList();
});

/// Get a category by ID
final categoryByIdProvider = Provider.family<CategoryEntity?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

/// Category notifier for CRUD operations
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepositoryImpl _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> addCategory(String userId, CategoryEntity category) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addCategory(category);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> deleteCategory(String userId, String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

/// Provider for category actions
final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repo);
});

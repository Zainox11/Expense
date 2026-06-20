import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/user_model.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('expense_tracker_test');
    Hive.init(tempDir.path);
    
    // Register Adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BudgetModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(UserModelAdapter());
    
    // Open Boxes
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<CategoryModel>('categories');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<UserModel>('users');
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with Riverpod overrides.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );
    
    // Advance virtual time to allow the splash screen's delayed navigation to complete
    await tester.pump(const Duration(milliseconds: 3000));
    
    // Pump extra frames to process route transitions and build LoginScreen without waiting infinitely for shimmer
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}

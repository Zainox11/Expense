import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/app.dart';

// Import Hive Models & Adapters
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/user_model.dart';

// Services
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/recurring_transaction_service.dart';

// Providers
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local Hive Database
  await Hive.initFlutter();

  // Register Type Adapters
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(UserModelAdapter());

  // Open Hive Boxes
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<BudgetModel>('budgets');
  await Hive.openBox<UserModel>('users');

  // 2. Initialize Firebase (with safety catch for initial setup)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (offline mode): $e');
  }

  // 3. Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Run the app inside ProviderScope
  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );

  // 4. Calculate recurring transactions on launch (runs in background)
  _processLaunchRecurringTransactions();
}

Future<void> _processLaunchRecurringTransactions() async {
  // Let the UI build first
  await Future.delayed(const Duration(seconds: 2));

  final container = ProviderContainer();
  final currentUser = await container.read(authRepositoryProvider).getCurrentUser();

  if (currentUser != null) {
    final transactionRepo = container.read(transactionRepositoryProvider);

    // Fetch transactions from repository (async)
    final transactions = await transactionRepo.getTransactions(currentUser.id);

    final recurringService = RecurringTransactionService();

    // Process recurring transactions (sync)
    final newTransactions = recurringService.processRecurringTransactions(
      userId: currentUser.id,
      transactions: transactions,
    );

    if (newTransactions.isNotEmpty) {
      debugPrint('Generated ${newTransactions.length} new recurring transactions on launch.');
      // Batch save new transactions
      for (final tx in newTransactions) {
        await transactionRepo.addTransaction(tx);
      }

      // Send a general notification alert
      final notificationService = NotificationService();
      await notificationService.showNotification(
        id: 999,
        title: 'Recurring payments processed',
        body: 'We generated ${newTransactions.length} scheduled items.',
      );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/screens/splash/splash_screen.dart';
import 'package:expense_tracker/presentation/screens/auth/login_screen.dart';
import 'package:expense_tracker/presentation/screens/auth/register_screen.dart';
import 'package:expense_tracker/presentation/screens/home/home_screen.dart';
import 'package:expense_tracker/presentation/screens/transactions/transactions_screen.dart';
import 'package:expense_tracker/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:expense_tracker/presentation/screens/categories/categories_screen.dart';
import 'package:expense_tracker/presentation/screens/categories/add_category_screen.dart';
import 'package:expense_tracker/presentation/screens/budget/budget_screen.dart';
import 'package:expense_tracker/presentation/screens/budget/set_budget_screen.dart';
import 'package:expense_tracker/presentation/screens/analytics/analytics_screen.dart';
import 'package:expense_tracker/presentation/screens/export/export_screen.dart';
import 'package:expense_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:expense_tracker/presentation/screens/shell/app_shell.dart';

/// Route path constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static const editTransaction = '/transactions/edit';
  static const categories = '/categories';
  static const addCategory = '/categories/add';
  static const budget = '/budget';
  static const setBudget = '/budget/set';
  static const analytics = '/analytics';
  static const export = '/export';
  static const settings = '/settings';
}

/// Navigation key for accessing navigator state
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // If on splash, don't redirect (splash handles its own navigation)
      if (isOnSplash) return null;

      // If not logged in, redirect to login
      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;

      // If logged in but on auth page, redirect to home
      if (isLoggedIn && isOnAuth) return AppRoutes.home;

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),

      // Shell Route for bottom navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              state: state,
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.budget,
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              state: state,
              child: const BudgetScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              state: state,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.addTransaction,
        pageBuilder: (context, state) {
          final transaction = state.extra as TransactionEntity?;
          return _buildPageWithSlideUpTransition(
            state: state,
            child: AddTransactionScreen(editTransaction: transaction),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editTransaction,
        pageBuilder: (context, state) {
          final transaction = state.extra as TransactionEntity?;
          return _buildPageWithSlideUpTransition(
            state: state,
            child: AddTransactionScreen(editTransaction: transaction),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addCategory,
        pageBuilder: (context, state) => _buildPageWithSlideUpTransition(
          state: state,
          child: const AddCategoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.setBudget,
        pageBuilder: (context, state) {
          final budget = state.extra as BudgetEntity?;
          return _buildPageWithSlideUpTransition(
            state: state,
            child: SetBudgetScreen(editBudget: budget),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.categories,
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          state: state,
          child: const CategoriesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.export,
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          state: state,
          child: const ExportScreen(),
        ),
      ),
    ],
  );
});

/// Fade transition for tab switches
CustomTransitionPage _buildPageWithFadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Slide from right transition for push navigation
CustomTransitionPage _buildPageWithSlideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// Slide from bottom transition for modal-style screens
CustomTransitionPage _buildPageWithSlideUpTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

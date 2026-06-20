/// All string constants used throughout the Expense Tracker app.
/// Centralized here for easy localization in the future.
class AppStrings {
  AppStrings._();

  // ──────────────────────────────────────────────
  // App Info
  // ──────────────────────────────────────────────

  static const String appName = 'Expense Tracker';
  static const String appTagline = 'Track. Save. Grow.';
  static const String appVersion = '1.0.0';

  // ──────────────────────────────────────────────
  // Navigation Labels
  // ──────────────────────────────────────────────

  static const String home = 'Home';
  static const String transactions = 'Transactions';
  static const String analytics = 'Analytics';
  static const String budgets = 'Budgets';
  static const String settings = 'Settings';
  static const String profile = 'Profile';

  // ──────────────────────────────────────────────
  // Auth Labels
  // ──────────────────────────────────────────────

  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String displayName = 'Display Name';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';

  // ──────────────────────────────────────────────
  // Transaction Labels
  // ──────────────────────────────────────────────

  static const String addTransaction = 'Add Transaction';
  static const String editTransaction = 'Edit Transaction';
  static const String deleteTransaction = 'Delete Transaction';
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String amount = 'Amount';
  static const String category = 'Category';
  static const String note = 'Note';
  static const String date = 'Date';
  static const String recurrence = 'Recurrence';
  static const String none = 'None';
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String monthly = 'Monthly';
  static const String yearly = 'Yearly';
  static const String recentTransactions = 'Recent Transactions';
  static const String allTransactions = 'All Transactions';
  static const String noTransactions = 'No transactions yet';
  static const String noTransactionsHint = 'Tap + to add your first transaction';

  // ──────────────────────────────────────────────
  // Budget Labels
  // ──────────────────────────────────────────────

  static const String addBudget = 'Add Budget';
  static const String editBudget = 'Edit Budget';
  static const String deleteBudget = 'Delete Budget';
  static const String budgetLimit = 'Budget Limit';
  static const String spent = 'Spent';
  static const String remaining = 'Remaining';
  static const String overBudget = 'Over Budget!';
  static const String noBudgets = 'No budgets set';
  static const String noBudgetsHint = 'Set a budget to track your spending';

  // ──────────────────────────────────────────────
  // Analytics Labels
  // ──────────────────────────────────────────────

  static const String totalBalance = 'Total Balance';
  static const String totalIncome = 'Total Income';
  static const String totalExpense = 'Total Expense';
  static const String monthlyOverview = 'Monthly Overview';
  static const String weeklyOverview = 'Weekly Overview';
  static const String categoryBreakdown = 'Category Breakdown';
  static const String spendingTrends = 'Spending Trends';
  static const String incomeVsExpense = 'Income vs Expense';

  // ──────────────────────────────────────────────
  // Category Labels
  // ──────────────────────────────────────────────

  static const String addCategory = 'Add Category';
  static const String editCategory = 'Edit Category';
  static const String deleteCategory = 'Delete Category';
  static const String categoryName = 'Category Name';
  static const String selectIcon = 'Select Icon';
  static const String selectColor = 'Select Color';
  static const String defaultCategories = 'Default Categories';
  static const String customCategories = 'Custom Categories';

  // ──────────────────────────────────────────────
  // Settings Labels
  // ──────────────────────────────────────────────

  static const String currency = 'Currency';
  static const String theme = 'Theme';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String systemTheme = 'System Theme';
  static const String notifications = 'Notifications';
  static const String biometricLock = 'Biometric Lock';
  static const String exportData = 'Export Data';
  static const String importData = 'Import Data';
  static const String clearData = 'Clear All Data';
  static const String about = 'About';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';

  // ──────────────────────────────────────────────
  // Export Labels
  // ──────────────────────────────────────────────

  static const String exportPdf = 'Export as PDF';
  static const String exportExcel = 'Export as Excel';
  static const String exportCsv = 'Export as CSV';
  static const String shareReport = 'Share Report';

  // ──────────────────────────────────────────────
  // Action Labels
  // ──────────────────────────────────────────────

  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String seeAll = 'See All';
  static const String apply = 'Apply';
  static const String reset = 'Reset';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';

  // ──────────────────────────────────────────────
  // Error Messages
  // ──────────────────────────────────────────────

  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuth = 'Authentication failed. Please sign in again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorWeakPassword = 'Password must be at least 6 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorRequiredField = 'This field is required.';
  static const String errorInvalidAmount = 'Please enter a valid amount.';
  static const String errorMinAmount = 'Amount must be greater than zero.';
  static const String errorUserNotFound = 'No user found with this email.';
  static const String errorWrongPassword = 'Incorrect password. Please try again.';
  static const String errorEmailInUse = 'This email is already registered.';
  static const String errorCacheRead = 'Failed to read local data.';
  static const String errorCacheWrite = 'Failed to save data locally.';
  static const String errorLoadingData = 'Failed to load data.';

  // ──────────────────────────────────────────────
  // Success Messages
  // ──────────────────────────────────────────────

  static const String successTransactionAdded = 'Transaction added successfully.';
  static const String successTransactionUpdated = 'Transaction updated successfully.';
  static const String successTransactionDeleted = 'Transaction deleted successfully.';
  static const String successBudgetSaved = 'Budget saved successfully.';
  static const String successCategorySaved = 'Category saved successfully.';
  static const String successExport = 'Data exported successfully.';
  static const String successSignOut = 'Signed out successfully.';

  // ──────────────────────────────────────────────
  // Confirmation Dialogs
  // ──────────────────────────────────────────────

  static const String confirmDelete = 'Are you sure you want to delete this?';
  static const String confirmSignOut = 'Are you sure you want to sign out?';
  static const String confirmClearData = 'This will permanently delete all your local data. This action cannot be undone.';

  // ──────────────────────────────────────────────
  // Empty States
  // ──────────────────────────────────────────────

  static const String emptySearch = 'No results found.';
  static const String emptyFilter = 'No transactions match your filters.';

  // ──────────────────────────────────────────────
  // Time Periods
  // ──────────────────────────────────────────────

  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String thisYear = 'This Year';
  static const String custom = 'Custom';
  static const String allTime = 'All Time';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/presentation/widgets/common/loading_indicator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Greeting
                  _buildHeader(context, currentUser),
                  const SizedBox(height: 24),

                  // Balance Card
                  _buildBalanceCard(context, ref, currencySymbol),
                  const SizedBox(height: 24),

                  // Quick Actions Row
                  _buildQuickActions(context),
                  const SizedBox(height: 32),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.transactions),
                        child: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00D2FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recent Transactions List
                  _buildRecentTransactionsList(context, ref, transactionsAsync, currencySymbol),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            currentUser.when(
              data: (user) => Text(
                'Hello, ${user?.displayName.split(' ')[0] ?? 'User'}!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              error: (_, __) => Text(
                'Hello!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              loading: () => Container(
                width: 120,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your financial activities',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF8E92A4),
              ),
            ),
          ],
        ),
        
        // Notification bell / profile picture
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 24,
                ),
                onPressed: () {
                  // Notification logs / drawer
                },
              ),
            ),
            const SizedBox(width: 12),
            currentUser.when(
              data: (user) => CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7A5CFF),
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null
                    ? Text(
                        user?.displayName.isNotEmpty == true ? user.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 500.ms);
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, String symbol) {
    final balance = ref.watch(balanceProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF1E295D), Color(0xFF111736)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: const Color(0xFF00D2FF).withOpacity(0.2),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total Balance',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E92A4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance, symbol: symbol),
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Income summary
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8E92A4),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totalIncome, symbol: symbol),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Divider
              Container(
                height: 36,
                width: 1,
                color: const Color(0xFF2D3250),
              ),

              // Expense summary
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Color(0xFFFF5252),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8E92A4),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totalExpense, symbol: symbol),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'Add New',
          onTap: () => context.push(AppRoutes.addTransaction),
        ),
        _buildActionItem(
          context,
          icon: Icons.pie_chart_outline_rounded,
          label: 'Budgets',
          onTap: () => context.go(AppRoutes.budget),
        ),
        _buildActionItem(
          context,
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          onTap: () => context.go(AppRoutes.analytics),
        ),
        _buildActionItem(
          context,
          icon: Icons.file_upload_outlined,
          label: 'Export',
          onTap: () => context.push(AppRoutes.export),
        ),
      ],
    ).animate().fade(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F38) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00D2FF),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E92A4) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TransactionEntity>> transactionsAsync,
    String symbol,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 40,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions recorded yet.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8E92A4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Limit to 5
        final recents = transactions.take(5).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = recents[index];
            final isExpense = tx.type == TransactionType.expense;

            return categoriesAsync.when(
              data: (categories) {
                final category = categories.firstWhere(
                  (c) => c.id == tx.categoryId,
                  orElse: () => CategoryEntity(
                    id: '',
                    name: 'Unknown',
                    iconCode: Icons.help_outline.codePoint,
                    colorValue: 0xFF78909C,
                    type: tx.type,
                    isDefault: false,
                  ),
                );

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () {
                    // Navigate to edit screen with transaction
                    context.push(AppRoutes.editTransaction, extra: tx);
                  },
                  child: Row(
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(category.colorValue).withOpacity(0.15),
                        ),
                        child: Icon(
                          IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                          color: Color(category.colorValue),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Notes / Category details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note.isNotEmpty ? tx.note : category.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(tx.date),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8E92A4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Text(
                        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(tx.amount, symbol: symbol)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                );
              },
              error: (_, __) => const SizedBox(),
              loading: () => const SizedBox(),
            );
          },
        ).animate().fade(delay: 450.ms, duration: 500.ms);
      },
      error: (err, _) => Center(child: Text('Error: $err')),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: LoadingIndicator(),
        ),
      ),
    );
  }
}

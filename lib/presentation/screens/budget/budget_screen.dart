import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/presentation/providers/budget_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/presentation/widgets/common/empty_state.dart';
import 'package:expense_tracker/presentation/widgets/common/loading_indicator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);
    final period = ref.watch(budgetPeriodProvider);
    final totalBudget = ref.watch(totalBudgetProvider);
    final totalSpent = ref.watch(totalBudgetSpentProvider);
    final utilization = ref.watch(budgetUtilizationProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(budgetsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month/Year Selector
                  _buildPeriodHeader(context, ref, period),
                  const SizedBox(height: 20),

                  // Overall Budget Summary Progress
                  _buildOverallProgressCard(context, totalBudget, totalSpent, utilization, currencySymbol),
                  const SizedBox(height: 28),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Budgets',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.setBudget),
                        child: Text(
                          'Set Budget',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00D2FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Budget List
                  _buildBudgetList(context, ref, budgetsAsync, currencySymbol),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7A5CFF),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () => context.push(AppRoutes.setBudget),
      ).animate().scale(delay: 200.ms, duration: 300.ms),
    );
  }

  Widget _buildPeriodHeader(BuildContext context, WidgetRef ref, BudgetPeriod period) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            final prevMonth = period.month == 1 ? 12 : period.month - 1;
            final prevYear = period.month == 1 ? period.year - 1 : period.year;
            ref.read(budgetPeriodProvider.notifier).state =
                BudgetPeriod(month: prevMonth, year: prevYear);
            ref.invalidate(budgetsProvider);
          },
        ),
        const SizedBox(width: 8),
        Text(
          period.label,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            final nextMonth = period.month == 12 ? 1 : period.month + 1;
            final nextYear = period.month == 12 ? period.year + 1 : period.year;
            ref.read(budgetPeriodProvider.notifier).state =
                BudgetPeriod(month: nextMonth, year: nextYear);
            ref.invalidate(budgetsProvider);
          },
        ),
      ],
    );
  }

  Widget _buildOverallProgressCard(
    BuildContext context,
    double limit,
    double spent,
    double utilization,
    String symbol,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverBudget = spent > limit && limit > 0;
    
    Color progressColor = const Color(0xFF00E676); // Green
    if (utilization >= 100) {
      progressColor = const Color(0xFFFF5252); // Red
    } else if (utilization >= 80) {
      progressColor = const Color(0xFFFFAB40); // Orange/Amber
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1F38), Color(0xFF252A42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: limit > 0 ? (spent / limit).clamp(0, 1) : 0,
                  strokeWidth: 8,
                  backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Text(
                limit > 0 ? '${utilization.toStringAsFixed(0)}%' : '0%',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          
          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Limit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8E92A4),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(limit, symbol: symbol),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isOverBudget
                      ? 'Exceeded by ${CurrencyFormatter.format(spent - limit, symbol: symbol)}'
                      : '${CurrencyFormatter.format(limit - spent, symbol: symbol)} remaining',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOverBudget ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBudgetList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BudgetEntity>> budgetsAsync,
    String symbol,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No Budgets Set',
            subtitle: 'Plan your spending and save more money by setting monthly budgets.',
            actionText: 'Set a Budget',
            onAction: () => context.push(AppRoutes.setBudget),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final percent = budget.amount > 0 ? (budget.spent / budget.amount) : 0.0;
            final isOver = budget.spent > budget.amount;

            Color barColor = const Color(0xFF00E676);
            if (percent >= 1.0) {
              barColor = const Color(0xFFFF5252);
            } else if (percent >= 0.8) {
              barColor = const Color(0xFFFFAB40);
            }

            return Dismissible(
              key: Key(budget.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Remove Budget?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to remove this budget limits?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Remove', style: TextStyle(color: Color(0xFFFF5252))),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                ref.read(budgetNotifierProvider.notifier).deleteBudget(budget.id);
                ref.invalidate(budgetsProvider);
              },
              child: categoriesAsync.when(
                data: (categories) {
                  final category = categories.firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => CategoryEntity(
                      id: '',
                      name: 'Unknown',
                      iconCode: Icons.help_outline.codePoint,
                      colorValue: 0xFF78909C,
                      type: TransactionType.expense,
                      isDefault: false,
                    ),
                  );

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    onTap: () => context.push(AppRoutes.setBudget, extra: budget),
                    child: Column(
                      children: [
                        // Row 1: Icon, Category Name, Spent vs Budget
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(category.colorValue).withOpacity(0.15),
                              ),
                              child: Icon(
                                IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                                color: Color(category.colorValue),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: CurrencyFormatter.format(budget.spent, symbol: symbol),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isOver ? const Color(0xFFFF5252) : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${CurrencyFormatter.format(budget.amount, symbol: symbol)}',
                                        style: const TextStyle(color: Color(0xFF8E92A4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Linear Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 8,
                            child: LinearProgressIndicator(
                              value: percent.clamp(0, 1),
                              backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Row 3: Percent / Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(percent * 100).toStringAsFixed(0)}% used',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8E92A4),
                              ),
                            ),
                            Text(
                              isOver
                                  ? 'Over limit by ${CurrencyFormatter.format(budget.spent - budget.amount, symbol: symbol)}'
                                  : '${CurrencyFormatter.format(budget.amount - budget.spent, symbol: symbol)} remaining',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isOver ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                error: (_, __) => const SizedBox(),
                loading: () => const SizedBox(),
              ),
            );
          },
        ).animate().fade(delay: 150.ms, duration: 500.ms);
      },
      error: (err, _) => Center(child: Text('Error: $err')),
      loading: () => const Center(child: LoadingIndicator()),
    );
  }
}

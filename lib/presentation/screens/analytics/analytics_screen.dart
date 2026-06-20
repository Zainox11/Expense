import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/presentation/providers/analytics_provider.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/charts/expense_pie_chart.dart';
import 'package:expense_tracker/presentation/widgets/charts/monthly_bar_chart.dart';
import 'package:expense_tracker/presentation/widgets/charts/trend_line_chart.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/presentation/widgets/common/loading_indicator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _activePieTab = 0; // 0 for Expenses, 1 for Incomes

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analytics = ref.watch(monthlyAnalyticsProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    // Watch trends
    final trendsAsync = ref.watch(expenseTrendProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector
              _buildPeriodHeader(ref, dateFilter),
              const SizedBox(height: 20),

              // Summary Info Cards
              _buildSummarySection(analytics, currencySymbol),
              const SizedBox(height: 28),

              // Category Pie Chart section
              _buildPieChartSection(isDark, ref, currencySymbol),
              const SizedBox(height: 24),

              // Daily Bar Chart Section
              _buildBarChartSection(isDark, analytics),
              const SizedBox(height: 24),

              // Historic Line Chart Section
              _buildLineChartSection(isDark, trendsAsync),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodHeader(WidgetRef ref, DateFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            final now = filter.startDate;
            final prevMonthStart = DateTime(now.year, now.month - 1, 1);
            final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
            ref.read(dateFilterProvider.notifier).state =
                DateFilter.custom(prevMonthStart, prevMonthEnd);
            ref.invalidate(transactionsProvider);
          },
        ),
        const SizedBox(width: 8),
        Text(
          ref.read(dateFilterProvider).label == 'This Month'
              ? 'This Month'
              : ref.read(dateFilterProvider).label == 'Last Month'
                  ? 'Last Month'
                  : '${_getMonthName(filter.startDate.month)} ${filter.startDate.year}',
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
            final now = filter.startDate;
            final nextMonthStart = DateTime(now.year, now.month + 1, 1);
            final nextMonthEnd = DateTime(now.year, now.month + 2, 0, 23, 59, 59);
            ref.read(dateFilterProvider.notifier).state =
                DateFilter.custom(nextMonthStart, nextMonthEnd);
            ref.invalidate(transactionsProvider);
          },
        ),
      ],
    );
  }

  Widget _buildSummarySection(MonthlyAnalytics data, String symbol) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            title: 'Income',
            amount: data.totalIncome,
            color: const Color(0xFF00E676),
            icon: Icons.arrow_downward_rounded,
            symbol: symbol,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            title: 'Expenses',
            amount: data.totalExpense,
            color: const Color(0xFFFF5252),
            icon: Icons.arrow_upward_rounded,
            symbol: symbol,
          ),
        ),
      ],
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildMiniCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required String symbol,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF8E92A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(amount, symbol: symbol),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(bool isDark, WidgetRef ref, String symbol) {
    // Select correct slice data based on tab toggle
    final expenseBreakdown = ref.watch(categoryExpenseAnalyticsProvider);
    final incomeBreakdown = ref.watch(categoryIncomeAnalyticsProvider);
    final activeData = _activePieTab == 0 ? expenseBreakdown : incomeBreakdown;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Summary',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              
              // Custom mini toggle segment
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252A42) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildPieSelectorTab('Exp', 0, isDark),
                    _buildPieSelectorTab('Inc', 1, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          ExpensePieChart(data: activeData),
        ],
      ),
    ).animate().fade(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildPieSelectorTab(String label, int tabIndex, bool isDark) {
    final isActive = _activePieTab == tabIndex;
    final activeColor = tabIndex == 0 ? const Color(0xFFFF5252) : const Color(0xFF00E676);

    return GestureDetector(
      onTap: () {
        setState(() {
          _activePieTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.white
                : (isDark ? const Color(0xFF8E92A4) : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartSection(bool isDark, MonthlyAnalytics data) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Expenses',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          MonthlyBarChart(data: data.dailyExpenses),
        ],
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildLineChartSection(bool isDark, AsyncValue<List<MonthlyTrend>> trendsAsync) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Comparison History',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              _buildLegendIndicator('Income', const Color(0xFF00E676)),
              const SizedBox(width: 12),
              _buildLegendIndicator('Expense', const Color(0xFFFF5252)),
            ],
          ),
          const SizedBox(height: 24),
          trendsAsync.when(
            data: (trends) => TrendLineChart(trends: trends),
            error: (err, _) => Center(child: Text('Error: $err')),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 450.ms, duration: 400.ms);
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF8E92A4),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/presentation/widgets/common/empty_state.dart';
import 'package:expense_tracker/presentation/widgets/common/loading_indicator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync = ref.watch(transactionsProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => _showFilterBottomSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Type Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildSearchBar(context, ref, searchQuery),
                  const SizedBox(height: 14),
                  _buildTypeFilterRow(context, ref, typeFilter),
                ],
              ),
            ),

            // Date Range Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd').format(dateFilter.startDate)} - ${DateFormat('MMM dd, yyyy').format(dateFilter.endDate)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _selectCustomDateRange(context, ref),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Transactions list
            Expanded(
              child: transactionsAsync.when(
                data: (_) {
                  if (filteredTransactions.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Transactions Found',
                      subtitle: searchQuery.isNotEmpty
                          ? 'Try refining your search keyword or filters.'
                          : 'You haven\'t logged any transactions for this period.',
                      actionText: searchQuery.isEmpty ? 'Add Transaction' : null,
                      onAction: searchQuery.isEmpty
                          ? () => context.push(AppRoutes.addTransaction)
                          : null,
                    );
                  }

                  // Group transactions by date
                  final grouped = _groupTransactionsByDate(filteredTransactions);

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, dateIndex) {
                      final date = grouped.keys.elementAt(dateIndex);
                      final dayTransactions = grouped[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(
                              _getFriendlyDateHeader(date),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF8E92A4) : Colors.grey[700],
                              ),
                            ),
                          ),
                          
                          // Transactions for this day
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dayTransactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final tx = dayTransactions[index];
                              return _buildDismissibleTransactionTile(context, ref, tx, currencySymbol);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (err, _) => Center(child: Text('Error: $err')),
                loading: () => const Center(child: LoadingIndicator()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7A5CFF),
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => context.push(AppRoutes.addTransaction),
      ).animate().scale(delay: 200.ms, duration: 300.ms),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search note, category or amount...',
          hintStyle: GoogleFonts.inter(
            color: isDark ? const Color(0xFF8E92A4).withOpacity(0.6) : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00D2FF), size: 22),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8E92A4), size: 20),
                  onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTypeFilterRow(BuildContext context, WidgetRef ref, TransactionType? activeType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chip(String label, TransactionType? type) {
      final isSelected = activeType == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(transactionTypeFilterProvider.notifier).state = type,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF7A5CFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isSelected
                  ? (isDark ? const Color(0xFF1A1F38) : Colors.white)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? const Color(0xFF2D3250) : Colors.grey[200]!),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF8E92A4) : Colors.grey[700]),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('All', null),
        const SizedBox(width: 8),
        chip('Income', TransactionType.income),
        const SizedBox(width: 8),
        chip('Expense', TransactionType.expense),
      ],
    );
  }

  Widget _buildDismissibleTransactionTile(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
    String symbol,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Transaction?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: const Text('This will permanently delete this transaction records. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFFF5252))),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionNotifierProvider.notifier).deleteTransaction(tx.id);
        ref.invalidate(transactionsProvider);
      },
      child: categoriesAsync.when(
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

          final isExpense = tx.type == TransactionType.expense;

          return GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => context.push(AppRoutes.editTransaction, extra: tx),
            child: Row(
              children: [
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
                        category.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8E92A4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}${CurrencyFormatter.format(tx.amount, symbol: symbol)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      ),
                    ),
                    if (tx.recurrence != RecurrenceType.none) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.autorenew_rounded, size: 12, color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            tx.recurrence.name,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8E92A4)),
                          ),
                        ],
                      ),
                    ]
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
  }

  Map<DateTime, List<TransactionEntity>> _groupTransactionsByDate(List<TransactionEntity> list) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};
    for (final tx in list) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(tx);
    }
    return grouped;
  }

  String _getFriendlyDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter Range',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('This Month'),
                trailing: ref.read(dateFilterProvider).label == 'This Month' ? const Icon(Icons.check, color: Color(0xFF00D2FF)) : null,
                onTap: () {
                  ref.read(dateFilterProvider.notifier).state = DateFilter.thisMonth();
                  ref.invalidate(transactionsProvider);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Last Month'),
                trailing: ref.read(dateFilterProvider).label == 'Last Month' ? const Icon(Icons.check, color: Color(0xFF00D2FF)) : null,
                onTap: () {
                  ref.read(dateFilterProvider.notifier).state = DateFilter.lastMonth();
                  ref.invalidate(transactionsProvider);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('This Year'),
                trailing: ref.read(dateFilterProvider).label == 'This Year' ? const Icon(Icons.check, color: Color(0xFF00D2FF)) : null,
                onTap: () {
                  ref.read(dateFilterProvider.notifier).state = DateFilter.thisYear();
                  ref.invalidate(transactionsProvider);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Custom Range'),
                trailing: ref.read(dateFilterProvider).label == 'Custom' ? const Icon(Icons.check, color: Color(0xFF00D2FF)) : null,
                onTap: () {
                  Navigator.pop(context);
                  _selectCustomDateRange(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dateFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: current.startDate, end: current.endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF7A5CFF),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A1F38),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dateFilterProvider.notifier).state = DateFilter.custom(picked.start, picked.end);
      ref.invalidate(transactionsProvider);
    }
  }
}

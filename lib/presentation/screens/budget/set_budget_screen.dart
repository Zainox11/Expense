import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/presentation/providers/budget_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_button.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_text_field.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';

class SetBudgetScreen extends ConsumerStatefulWidget {
  final BudgetEntity? editBudget;

  const SetBudgetScreen({super.key, this.editBudget});

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late int _selectedMonth;
  late int _selectedYear;
  String? _selectedCategoryId;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _amountController = TextEditingController(
      text: widget.editBudget != null ? widget.editBudget!.amount.toString() : '',
    );
    _selectedMonth = widget.editBudget?.month ?? now.month;
    _selectedYear = widget.editBudget?.year ?? now.year;
    _selectedCategoryId = widget.editBudget?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount greater than zero.'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    final id = widget.editBudget?.id ?? const Uuid().v4();
    final spent = widget.editBudget?.spent ?? 0.0;

    final budget = BudgetEntity(
      id: id,
      userId: user.id,
      categoryId: _selectedCategoryId!,
      amount: amount,
      spent: spent,
      month: _selectedMonth,
      year: _selectedYear,
    );

    final success = await ref.read(budgetNotifierProvider.notifier).setBudget(budget);

    if (success && mounted) {
      ref.invalidate(budgetsProvider);
      ref.invalidate(budgetsWithSpendingProvider);
      context.pop();
    } else if (mounted) {
      final error = ref.read(budgetNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Error saving budget.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEdit = widget.editBudget != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Budget' : 'Set Budget',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Picker (Expense only)
                Text(
                  'Select Expense Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) {
                    final expenseCats =
                        categories.where((c) => c.type == TransactionType.expense).toList();

                    if (_selectedCategoryId == null && expenseCats.isNotEmpty) {
                      _selectedCategoryId = expenseCats.first.id;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252A42).withOpacity(0.5)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D3250).withOpacity(0.5)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                            });
                          },
                          items: expenseCats.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              child: Row(
                                children: [
                                  Icon(
                                    IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                                    color: Color(cat.colorValue),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  error: (_, __) => const Center(child: Text('Error loading categories')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 24),

                // Amount text input
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        ref.read(currencySymbolProvider),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00D2FF),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF8E92A4).withOpacity(0.3)
                                  : Colors.grey[300],
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Month / Year selector Row
                Row(
                  children: [
                    // Month dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Month',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252A42).withOpacity(0.5)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2D3250).withOpacity(0.5)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedMonth,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedMonth = val;
                                    });
                                  }
                                },
                                items: List.generate(12, (i) => i + 1).map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m,
                                    child: Text(
                                      _months[m - 1],
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Year dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Year',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252A42).withOpacity(0.5)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2D3250).withOpacity(0.5)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedYear,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedYear = val;
                                    });
                                  }
                                },
                                items: [
                                  DateTime.now().year - 1,
                                  DateTime.now().year,
                                  DateTime.now().year + 1,
                                ].map((y) {
                                  return DropdownMenuItem<int>(
                                    value: y,
                                    child: Text(
                                      y.toString(),
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Save button
                CustomButton(
                  text: isEdit ? 'Update Budget' : 'Set Budget Limit',
                  isLoading: ref.watch(budgetNotifierProvider).isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

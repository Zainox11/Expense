import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/budget_provider.dart';
import 'package:expense_tracker/presentation/providers/analytics_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_button.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_text_field.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionEntity? editTransaction;

  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late RecurrenceType _recurrence;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.editTransaction?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: widget.editTransaction != null ? widget.editTransaction!.amount.toString() : '',
    );
    _noteController = TextEditingController(
      text: widget.editTransaction?.note ?? '',
    );
    _selectedDate = widget.editTransaction?.date ?? DateTime.now();
    _recurrence = widget.editTransaction?.recurrence ?? RecurrenceType.none;
    _selectedCategoryId = widget.editTransaction?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() {
        _selectedDate = picked;
      });
    }
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

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    final id = widget.editTransaction?.id ?? const Uuid().v4();
    final createdAt = widget.editTransaction?.createdAt ?? DateTime.now();

    final tx = TransactionEntity(
      id: id,
      userId: user.id,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      note: _noteController.text.trim(),
      date: _selectedDate,
      createdAt: createdAt,
      recurrence: _recurrence,
      isSynced: false,
    );

    final success = widget.editTransaction == null
        ? await ref.read(transactionNotifierProvider.notifier).addTransaction(tx)
        : await ref.read(transactionNotifierProvider.notifier).updateTransaction(tx);

    if (success && mounted) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(budgetsWithSpendingProvider);
      ref.invalidate(monthlyAnalyticsProvider);
      ref.invalidate(expenseTrendProvider);
      context.pop();
    } else if (mounted) {
      final error = ref.read(transactionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Error saving transaction.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEdit = widget.editTransaction != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Transaction' : 'Add Transaction',
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
                // Transaction Type Selector (Income/Expense toggle)
                _buildTypeSelector(),
                const SizedBox(height: 24),

                // Amount Text Field (Big numeric input)
                _buildAmountField(),
                const SizedBox(height: 24),

                // Note Field
                CustomTextField(
                  controller: _noteController,
                  hintText: 'Enter a short note...',
                  label: 'Note (Optional)',
                  prefixIcon: Icons.notes_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Date & Recurrence Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            hintText: DateFormat('MMM dd, yyyy').format(_selectedDate),
                            label: 'Date',
                            prefixIcon: Icons.calendar_month_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRecurrenceDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Category Grid Selection Header
                Text(
                  'Select Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // Category grid
                categoriesAsync.when(
                  data: (categories) {
                    final filteredCategories =
                        categories.where((c) => c.type == _type).toList();
                        
                    // If selected category is not in the filtered category list, reset it
                    if (_selectedCategoryId != null &&
                        !filteredCategories.any((c) => c.id == _selectedCategoryId)) {
                      _selectedCategoryId = null;
                    }
                    
                    // Auto-select first category if none selected
                    if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
                      _selectedCategoryId = filteredCategories.first.id;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final cat = filteredCategories[index];
                        final isSelected = _selectedCategoryId == cat.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat.id;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(cat.colorValue).withOpacity(0.12)
                                  : (isDark
                                      ? const Color(0xFF1A1F38)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Color(cat.colorValue)
                                    : (isDark
                                        ? const Color(0xFF2D3250)
                                        : Colors.grey[200]!),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(cat.colorValue).withOpacity(0.15),
                                  ),
                                  child: Icon(
                                    IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                                    color: Color(cat.colorValue),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    cat.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  error: (_, __) => const Center(child: Text('Error loading categories')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),

                const SizedBox(height: 40),

                // Save button
                CustomButton(
                  text: isEdit ? 'Update Transaction' : 'Save Transaction',
                  isLoading: ref.watch(transactionNotifierProvider).isLoading,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F38) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _type = TransactionType.expense;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _type == TransactionType.expense
                      ? const Color(0xFFFF5252)
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expense',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _type == TransactionType.expense
                        ? Colors.white
                        : (isDark ? const Color(0xFF8E92A4) : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _type = TransactionType.income;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _type == TransactionType.income
                      ? const Color(0xFF00E676)
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _type == TransactionType.income
                        ? Colors.white
                        : (isDark ? const Color(0xFF8E92A4) : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            ref.read(currencySymbolProvider),
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _type == TransactionType.expense
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 36,
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
    );
  }

  Widget _buildRecurrenceDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recurrence',
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
            child: DropdownButton<RecurrenceType>(
              value: _recurrence,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _recurrence = val;
                  });
                }
              },
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem<RecurrenceType>(
                  value: type,
                  child: Text(
                    type == RecurrenceType.none ? 'One-time' : type.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

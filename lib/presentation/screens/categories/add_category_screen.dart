import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_button.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_text_field.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  int _selectedIconCode = Icons.category_rounded.codePoint;
  int _selectedColorValue = 0xFF7A5CFF; // Default purple

  // List of standard icons for expense/income tracking
  final List<IconData> _iconList = [
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.shopping_bag_rounded,
    Icons.movie_rounded,
    Icons.favorite_rounded,
    Icons.receipt_long_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.flight_rounded,
    Icons.local_hospital_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.celebration_rounded,
    Icons.card_giftcard_rounded,
    Icons.trending_up_rounded,
    Icons.laptop_mac_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.attach_money_rounded,
    Icons.savings_rounded,
    Icons.storefront_rounded,
    Icons.phone_android_rounded,
    Icons.electrical_services_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.build_rounded,
    Icons.clean_hands_rounded,
    Icons.coffee_rounded,
    Icons.fastfood_rounded,
  ];

  // Preset list of design colors
  final List<int> _colorList = [
    0xFF7A5CFF, // Purple
    0xFF00D2FF, // Cyan
    0xFF00E676, // Bright Green
    0xFFFF5252, // Coral Red
    0xFFFFAB40, // Amber Yellow
    0xFFEC407A, // Hot Pink
    0xFFAB47BC, // Lavender
    0xFF42A5F5, // Sky Blue
    0xFF26C6DA, // Teal
    0xFF26A69A, // Sea Green
    0xFFD4E157, // Lime Green
    0xFFFF7043, // Orange
    0xFF8D6E63, // Brown
    0xFF78909C, // Blue Grey
    0xFF000000, // Black (Dark theme)
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final id = const Uuid().v4();
    final category = CategoryEntity(
      id: id,
      name: _nameController.text.trim(),
      iconCode: _selectedIconCode,
      colorValue: _selectedColorValue,
      type: _type,
      isDefault: false,
    );

    final success = await ref
        .read(categoryNotifierProvider.notifier)
        .addCategory(user.id, category);

    if (success && mounted) {
      ref.invalidate(categoriesProvider);
      context.pop();
    } else if (mounted) {
      final error = ref.read(categoryNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Error creating category.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add Category',
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
                // Live Preview Card
                _buildLivePreview(isDark),
                const SizedBox(height: 24),

                // Category type selector
                _buildTypeSelector(),
                const SizedBox(height: 24),

                // Category Name input
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Enter category name...',
                  label: 'Category Name',
                  prefixIcon: Icons.label_outline_rounded,
                  textInputAction: TextInputAction.done,
                  onChanged: (val) {
                    setState(() {}); // Redraw preview
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    if (value.trim().length > 20) {
                      return 'Category name must be under 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Icon Picker Section
                Text(
                  'Select Icon',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildIconGrid(isDark),
                const SizedBox(height: 24),

                // Color Picker Section
                Text(
                  'Select Color',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildColorSelector(isDark),
                const SizedBox(height: 36),

                // Save button
                CustomButton(
                  text: 'Create Category',
                  isLoading: ref.watch(categoryNotifierProvider).isLoading,
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

  Widget _buildLivePreview(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Text(
              'Live Preview',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8E92A4),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(_selectedColorValue).withOpacity(0.15),
              ),
              child: Icon(
                IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                color: Color(_selectedColorValue),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : 'Category Name',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
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
                  'Expense Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
                  'Income Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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

  Widget _buildIconGrid(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _iconList.length,
        itemBuilder: (context, index) {
          final icon = _iconList[index];
          final isSelected = _selectedIconCode == icon.codePoint;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIconCode = icon.codePoint;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(_selectedColorValue).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Color(_selectedColorValue)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Color(_selectedColorValue)
                    : (isDark ? const Color(0xFF8E92A4) : Colors.grey[600]),
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector(bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colorList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final colorVal = _colorList[index];
          final isSelected = _selectedColorValue == colorVal;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColorValue = colorVal;
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(colorVal),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(colorVal).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

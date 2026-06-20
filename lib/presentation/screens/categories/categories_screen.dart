import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/presentation/widgets/common/loading_indicator.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be deleted.'),
          backgroundColor: Color(0xFFFFAB40),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Category?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${category.name}"? Transactions using this category will remain, but the category itself will be deleted.'),
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

    if (confirm == true && mounted) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final success = await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(user.id, category.id);

      if (success && mounted) {
        ref.invalidate(categoriesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${category.name}" deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D2FF),
          labelColor: const Color(0xFF00D2FF),
          unselectedLabelColor: const Color(0xFF8E92A4),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Incomes'),
          ],
        ),
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) {
            final expenses =
                categories.where((c) => c.type == TransactionType.expense).toList();
            final incomes =
                categories.where((c) => c.type == TransactionType.income).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryGrid(expenses, isDark),
                _buildCategoryGrid(incomes, isDark),
              ],
            );
          },
          error: (err, _) => Center(child: Text('Error: $err')),
          loading: () => const Center(child: LoadingIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7A5CFF),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () => context.push(AppRoutes.addCategory),
      ).animate().scale(delay: 200.ms, duration: 300.ms),
    );
  }

  Widget _buildCategoryGrid(List<CategoryEntity> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No categories configured yet.',
          style: GoogleFonts.inter(color: const Color(0xFF8E92A4)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];

        return GlassCard(
          padding: EdgeInsets.zero,
          onTap: () {
            // Can show transactions using this category or edit it if not default
            if (!cat.isDefault) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Long press to delete "${cat.name}".'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: InkWell(
            onLongPress: () => _deleteCategory(cat),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(cat.colorValue).withOpacity(0.15),
                  ),
                  child: Icon(
                    IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                    color: Color(cat.colorValue),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cat.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cat.isDefault) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Default',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF8E92A4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

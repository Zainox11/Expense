import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/routing/app_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.transactions)) return 1;
    if (location.startsWith(AppRoutes.budget)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.transactions);
        break;
      case 2:
        context.push(AppRoutes.addTransaction);
        break;
      case 3:
        context.go(AppRoutes.budget);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: Stack(
        children: [
          child,
          
          // Floating bottom navigation bar with frosted glass
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1F38).withOpacity(0.85)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2D3250).withOpacity(0.5)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context: context,
                        index: 0,
                        currentIndex: selectedIndex,
                        activeIcon: Icons.grid_view_rounded,
                        inactiveIcon: Icons.grid_view_outlined,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        context: context,
                        index: 1,
                        currentIndex: selectedIndex,
                        activeIcon: Icons.receipt_long_rounded,
                        inactiveIcon: Icons.receipt_long_outlined,
                        label: 'Activity',
                      ),
                      
                      // Giant elevated Add (+) action button
                      _buildMiddleAddButton(context),
                      
                      _buildNavItem(
                        context: context,
                        index: 3,
                        currentIndex: selectedIndex,
                        activeIcon: Icons.pie_chart_rounded,
                        inactiveIcon: Icons.pie_chart_outline_rounded,
                        label: 'Budget',
                      ),
                      _buildNavItem(
                        context: context,
                        index: 4,
                        currentIndex: selectedIndex,
                        activeIcon: Icons.settings_rounded,
                        inactiveIcon: Icons.settings_outlined,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected
                ? const Color(0xFF00D2FF)
                : (isDark ? const Color(0xFF8E92A4) : Colors.grey[500]),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF00D2FF)
                  : (isDark ? const Color(0xFF8E92A4) : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _onItemTapped(2, context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00D2FF), Color(0xFF7A5CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A5CFF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

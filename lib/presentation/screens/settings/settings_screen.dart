import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/budget_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/services/sync_service.dart';
import 'package:expense_tracker/core/network/connectivity_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('No logged in user found.');

      // Connectivity check
      final isOnline = await ref.read(connectivityServiceProvider).isConnected;
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Sync will resume when online.'),
              backgroundColor: Color(0xFFFFAB40),
            ),
          );
        }
        return;
      }

      // Initialize sync service and sync
      final syncService = SyncService(
        localTransactionDatasource: ref.read(hiveTransactionDatasourceProvider),
        remoteTransactionDatasource: ref.read(firebaseTransactionDatasourceProvider),
        localCategoryDatasource: ref.read(hiveCategoryDatasourceProvider),
        remoteCategoryDatasource: ref.read(firebaseCategoryDatasourceProvider),
        localBudgetDatasource: ref.read(hiveBudgetDatasourceProvider),
        remoteBudgetDatasource: ref.read(firebaseBudgetDatasourceProvider),
        connectivityService: ref.read(connectivityServiceProvider),
      );

      final result = await syncService.syncAll(user.id);
      
      if (mounted) {
        // Refresh local providers
        ref.invalidate(transactionsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(budgetsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync Complete! Pushed: ${result.pushedCount}, Pulled: ${result.pulledCount}, Conflicts: ${result.conflictCount}',
            ),
            backgroundColor: const Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    
    // Watch settings state providers
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentCurrency = ref.watch(currencySymbolProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Settings',
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
              // 1. User Profile summary Card
              currentUser.when(
                data: (user) => _buildProfileCard(user),
                error: (err, _) => const SizedBox(),
                loading: () => Container(height: 100, color: Colors.grey.withOpacity(0.1)),
              ),
              const SizedBox(height: 24),

              // 2. Preferences Card
              _buildSectionTitle('Preferences'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Theme toggles
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Theme',
                      value: currentThemeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                    const Divider(color: Color(0xFF2D3250), height: 1),
                    // Currency selectors
                    _buildCurrencySelector(currentCurrency),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Security & Systems Card
              _buildSectionTitle('Security & Devices'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Lock',
                      value: biometricEnabled,
                      onChanged: (val) {
                        ref.read(biometricEnabledProvider.notifier).state = val;
                      },
                    ),
                    const Divider(color: Color(0xFF2D3250), height: 1),
                    _buildSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Push Notifications',
                      value: notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationsEnabledProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Data & Sync settings
              _buildSectionTitle('Data Management'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.category_outlined,
                      title: 'Manage Categories',
                      onTap: () => context.push(AppRoutes.categories),
                    ),
                    const Divider(color: Color(0xFF2D3250), height: 1),
                    _buildActionTile(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Sync Cloud Storage',
                      subtitle: 'Backup or pull latest data',
                      trailing: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, color: Color(0xFF8E92A4), size: 20),
                      onTap: _isSyncing ? null : _syncNow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Red Log Out Button
              TextButton.icon(
                onPressed: _logout,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF5252).withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
                label: Text(
                  'Log Out Account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF5252),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'ExpenseTracker v1.0.0 — Flutter & Firebase',
                  style: GoogleFonts.inter(color: const Color(0xFF8E92A4), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8E92A4),
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF7A5CFF),
            backgroundImage: user?.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user?.photoUrl == null
                ? Text(
                    user?.displayName.isNotEmpty == true ? user.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Anonymous User',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Not logged in',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF8E92A4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SwitchListTile.adaptive(
        secondary: Icon(
          icon,
          color: const Color(0xFF00D2FF),
          size: 22,
        ),
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        value: value,
        activeColor: const Color(0xFF00D2FF),
        activeTrackColor: const Color(0xFF00D2FF).withOpacity(0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCurrencySelector(String currentCurrency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbols = ['\$', '€', '£', '¥', '₨', '₱'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Icon(
            Icons.currency_exchange_rounded,
            color: Color(0xFF00D2FF),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Default Currency',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252A42) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentCurrency,
                dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(currencySymbolProvider.notifier).state = val;
                  }
                },
                items: currencySymbols.map((symbol) {
                  return DropdownMenuItem<String>(
                    value: symbol,
                    child: Text(
                      symbol,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: const Color(0xFF00D2FF),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8E92A4),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
          ),
      onTap: onTap,
    );
  }
}

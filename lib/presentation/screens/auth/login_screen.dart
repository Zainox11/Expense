import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/core/routing/app_router.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_button.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_text_field.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _biometricService = BiometricService();
  bool _isBiometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isAvailable();
    if (mounted) {
      setState(() {
        _isBiometricsAvailable = available;
      });
      // Auto-trigger biometric auth if enabled in settings
      final isBioEnabled = ref.read(biometricEnabledProvider);
      if (isBioEnabled && available) {
        _authenticateBiometrically();
      }
    }
  }

  Future<void> _authenticateBiometrically() async {
    final success = await _biometricService.authenticate(
      localizedReason: 'Authenticate to access your Expense Tracker',
    );
    if (success && mounted) {
      // For actual biometrics, we would use token from secure storage,
      // here we login with stored credentials or bypass for simulation
      // Let's trigger a dummy successful auth or notify user
      final authRepo = ref.read(authRepositoryProvider);
      final currentUser = await authRepo.getCurrentUser();
      if (currentUser != null && mounted) {
        context.go(AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in with email/password first to link biometrics.'),
            backgroundColor: Color(0xFFFFAB40),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Login failed. Please check your credentials.'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Google Sign-In failed.'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // Decorative background gradient orbs
              Positioned(
                top: -size.height * 0.15,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D2FF).withOpacity(isDark ? 0.12 : 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.height * 0.15,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7A5CFF).withOpacity(isDark ? 0.12 : 0.08),
                  ),
                ),
              ),
              
              // Core content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D2FF), Color(0xFF7A5CFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Login to track your finances',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0),
                        
                        const SizedBox(height: 36),
                        
                        // Glass Card for inputs
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'Enter your email',
                                label: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _passwordController,
                                hintText: 'Enter your password',
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF8E92A4),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Simulated forgot password action
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset link sent to your email.'),
                                        backgroundColor: Color(0xFF00D2FF),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF00D2FF),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Log In',
                                      isLoading: authState.isLoading,
                                      onPressed: _submit,
                                    ),
                                  ),
                                  if (_isBiometricsAvailable) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF2D3250) : Colors.grey[300]!,
                                        ),
                                        color: isDark ? const Color(0xFF252A42).withOpacity(0.5) : Colors.white,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.fingerprint_rounded,
                                          color: Color(0xFF00D2FF),
                                          size: 28,
                                        ),
                                        onPressed: _authenticateBiometrically,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 150.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Google Login Option
                        Center(
                          child: Text(
                            'Or continue with',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF8E92A4),
                            ),
                          ),
                        ).animate().fade(delay: 300.ms, duration: 600.ms),
                        
                        const SizedBox(height: 16),
                        
                        CustomButton(
                          text: 'Sign In with Google',
                          isOutlined: true,
                          borderColor: isDark ? const Color(0xFF2D3250) : Colors.grey[300]!,
                          textColor: isDark ? Colors.white : Colors.black87,
                          icon: Icons.g_mobiledata_rounded,
                          onPressed: _loginWithGoogle,
                        ).animate().fade(delay: 450.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Footer register navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7A5CFF),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 600.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

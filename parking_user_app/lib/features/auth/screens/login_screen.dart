import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/widgets/modern_widgets.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/screens/register_screen.dart' as reg;
import 'package:parking_user_app/features/auth/screens/terms_of_service_screen.dart';
import 'package:parking_user_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _countryCode = '+256';
  bool _acceptTerms = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final l10n = AppLocalizations.of(context);
    if (phone.isEmpty) {
      _showError(l10n.errorOccurred);
      return;
    }

    if (password.isEmpty) {
      _showError(l10n.errorOccurred);
      return;
    }

    if (!_acceptTerms) {
      _showError(l10n.errorOccurred);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final fullPhone = '$_countryCode$phone';
    final success = await authProvider.login(fullPhone, password);

    if (success && mounted) {
      debugPrint('[LoginScreen] ✅ Login successful, navigating to HomeScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (!success && mounted) {
      debugPrint('[LoginScreen] ❌ Login failed: ${authProvider.errorMessage}');
      _showError(authProvider.errorMessage ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Stack(
        children: [
          // Modern Gradient Accent (top-right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom accent
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Header
                  Text(
                    l10n.welcome,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    l10n.loginToYourAccount,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Phone Input with Country Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.phone,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Consumer<SettingsProvider>(
                              builder: (context, settings, _) {
                                return CountryCodePicker(
                                  onChanged: (code) => setState(
                                    () => _countryCode = code.dialCode!,
                                  ),
                                  initialSelection:
                                      settings.isoCountryCode ?? 'UG',
                                  favorite: const ['UG', 'KE', 'TZ'],
                                  showCountryOnly: false,
                                  showOnlyCountryWhenClosed: false,
                                  alignLeft: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingM,
                                  ),
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            Container(
                              height: 28,
                              width: 1,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge,
                                decoration: InputDecoration(
                                  hintText: l10n.phone,
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Password Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.password,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.all(AppTheme.spacingM),
                            child: Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.passwordResetSoon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        l10n.forgotPassword,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Terms & Privacy Checkbox
                  ModernCard(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    hasShadow: false,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (val) =>
                                setState(() => _acceptTerms = val!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Text(
                                l10n.iAcceptThe,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsOfServiceScreen(),
                                  ),
                                ),
                                child: Text(
                                  l10n.terms,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '&',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyScreen(),
                                  ),
                                ),
                                child: Text(
                                  l10n.privacyPolicy,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ModernButton(
                        label: l10n.login,
                        onPressed: _handleLogin,
                        isLoading:
                            auth.status == AuthStatus.authenticating,
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const reg.RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.register,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

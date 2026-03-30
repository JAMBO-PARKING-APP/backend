import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/screens/register_screen.dart';
import 'package:parking_user_app/features/auth/screens/terms_of_service_screen.dart';
import 'package:parking_user_app/features/auth/screens/privacy_policy_screen.dart';

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
      _showError(l10n.errorOccurred); // Using generic error for now, or specific if added
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!success && mounted) {
      _showError(authProvider.errorMessage ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            color: AppTheme.backgroundColor,
          ),
          // City Skyline accent at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/skyline_splash.png',
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    l10n.welcome,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginToYourAccount,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Phone Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
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
                                    padding: EdgeInsets.zero,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: l10n.phone,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Input
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            // Global theme handles these
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.passwordResetSoon,
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.forgotPassword),
                    ),
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _acceptTerms = val!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              l10n.iAcceptThe,
                              style: const TextStyle(fontSize: 12),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(' & ', style: TextStyle(fontSize: 12)),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.status == AuthStatus.authenticating
                            ? null
                            : _handleLogin,
                        child: auth.status == AuthStatus.authenticating
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(l10n.login),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Text("${l10n.dontHaveAccount} "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.register,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

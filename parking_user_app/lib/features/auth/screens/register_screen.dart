import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/widgets/modern_widgets.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:parking_user_app/features/auth/screens/terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _countryCode = '+256';
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorOccurred)));
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurred)),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final fullPhone = '$_countryCode${_phoneController.text}';

    final success = await authProvider.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber: fullPhone,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.register),
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Stack(
        children: [
          // Decorative background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0),
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
                vertical: AppTheme.spacingL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      l10n.joinSpacePark,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Create your account to get started',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Name Row
                    Row(
                      children: [
                        Expanded(
                          child: ModernTextField(
                            controller: _firstNameController,
                            label: l10n.firstName,
                            hint: 'John',
                            prefixIcon: Icons.person_outline,
                            validator: (val) =>
                                val!.isEmpty ? l10n.errorOccurred : null,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingL),
                        Expanded(
                          child: ModernTextField(
                            controller: _lastNameController,
                            label: l10n.lastName,
                            hint: 'Doe',
                            validator: (val) =>
                                val!.isEmpty ? l10n.errorOccurred : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Email
                    ModernTextField(
                      controller: _emailController,
                      label: l10n.email,
                      hint: 'john@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val!.isEmpty || !val.contains('@')
                          ? l10n.errorOccurred
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Phone with Country Code
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.phone,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: AppTheme.borderColor,
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
                                        .titleMedium,
                                  );
                                },
                              ),
                              Container(
                                height: 28,
                                width: 1,
                                color: AppTheme.borderColor,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: l10n.phone,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? l10n.errorOccurred : null,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Password
                    ModernTextField(
                      controller: _passwordController,
                      label: l10n.password,
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      isPassword: _obscurePassword,
                      validator: (val) =>
                          val!.length < 6 ? l10n.passwordTooShort : null,
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Confirm Password
                    ModernTextField(
                      controller: _confirmPasswordController,
                      label: l10n.confirmPassword,
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      isPassword: _obscureConfirmPassword,
                      validator: (val) {
                        if (val!.isEmpty) return l10n.confirmYourPasswordPrompt;
                        if (val != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Terms & Privacy
                    ModernCard(
                      backgroundColor: AppTheme.surfaceLight,
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      hasShadow: false,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              activeColor: AppTheme.primaryColor,
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
                                      color: AppTheme.primaryColor,
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
                                    'Privacy Policy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: AppTheme.primaryColor,
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

                    // Register Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ModernButton(
                          label: l10n.register.toUpperCase(),
                          onPressed: _handleRegister,
                          isLoading:
                              auth.status == AuthStatus.authenticating,
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${l10n.alreadyHaveAccount} ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              l10n.login,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: AppTheme.primaryColor,
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
          ),
        ],
      ),
    );
  }
}

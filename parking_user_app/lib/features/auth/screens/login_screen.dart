import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/auth/screens/register_screen.dart';
import 'package:parking_officer_app/features/legal/screens/legal_document_screen.dart';
import 'package:parking_officer_app/core/user_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _obscurePassword = true;
  String _countryCode = '+254';
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _countryCode = '+256';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_acceptedTerms) {
      _showError('Please accept the Terms and Conditions to continue.');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(_phoneController.text.replaceAll(' ', ''))) {
      _showError('Please enter a valid phone number (9 digits)');
      return;
    }

    final fullPhone = '$_countryCode${_phoneController.text}';

    final success = await context.read<AuthProvider>().login(
      fullPhone,
      _passwordController.text,
    );

    if (!success && mounted) {
      _showError(context.read<AuthProvider>().errorMessage ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.admin_panel_settings,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    UserStrings.t(context, 'appTitle'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UserStrings.t(context, 'driverLogin'),
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CountryCodePicker(
                      onChanged: (code) =>
                          setState(() => _countryCode = code.dialCode!),
                      initialSelection: 'KE',
                      favorite: const ['KE', 'UG', 'TZ', 'NG'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'phoneNumber'),
                      prefixIcon: const Icon(Icons.phone),
                      prefixText: '$_countryCode ',
                      hintText: '7XX XXX XXX',
                      errorText:
                          !_phoneFocusNode.hasFocus &&
                              _phoneController.text.isNotEmpty &&
                              !RegExp(
                                r'^[0-9]{9}$',
                              ).hasMatch(_phoneController.text)
                          ? 'Enter 9 digits'
                          : null,
                      // Using global input theme

                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'password'),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      // Using global input theme

                    ),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: auth.status == AuthStatus.authenticating
                        ? null
                        : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: auth.status == AuthStatus.authenticating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            UserStrings.t(context, 'loginButton'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    title: Text(UserStrings.t(context, 'agreeToTerms')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _legalLink(
                        context,
                        label: UserStrings.t(context, 'terms'),
                        type: LegalDocumentType.termsAndConditions,
                      ),
                      _legalLink(
                        context,
                        label: UserStrings.t(context, 'privacyPolicy'),
                        type: LegalDocumentType.privacyPolicy,
                      ),
                      _legalLink(
                        context,
                        label: UserStrings.t(context, 'termsOfService'),
                        type: LegalDocumentType.termsOfService,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(UserStrings.t(context, 'dontHaveAccountSignUp')),
                  ),

                  const SizedBox(height: 12),

                  if (auth.status == AuthStatus.authenticating)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              UserStrings.t(context, 'connectingToServer'),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _legalLink(
  BuildContext context, {
  required String label,
  required LegalDocumentType type,
}) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LegalDocumentScreen(type: type),
        ),
      );
    },
    child: Text(
      label,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

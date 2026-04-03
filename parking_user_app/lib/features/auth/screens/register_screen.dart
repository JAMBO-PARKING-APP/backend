import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/user_strings.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/features/legal/screens/legal_document_screen.dart';
import 'package:parking_officer_app/core/ui/space_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _phoneFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _countryCode = '+254';
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _countryCode = '+256';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
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

  Future<void> _register() async {
    if (!_acceptedTerms) {
      _showError('Please accept the Terms and Conditions to continue.');
      return;
    }

    final phone = _phoneController.text.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showError('Enter a valid phone number (9 digits).');
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty) {
      _showError('Please fill all fields.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != passwordConfirm) {
      _showError('Passwords do not match.');
      return;
    }

    final fullPhone = '$_countryCode$phone';

    final success = await context.read<AuthProvider>().register(
          phoneNumber: fullPhone,
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          passwordConfirm: passwordConfirm,
        );

    if (!success && mounted) {
      _showError(context.read<AuthProvider>().errorMessage ?? 'Registration failed');
    }

    // When AuthWrapper sees authenticated state, it will switch to dashboard.
    // Still, pop this screen if it is left open by Navigator.
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(UserStrings.t(context, 'createAccountTitle'))),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return SpacePageBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
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
                    UserStrings.t(context, 'driverSignup'),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'firstName'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'lastName'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
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
                                  !RegExp(r'^[0-9]{9}$')
                                      .hasMatch(_phoneController.text)
                              ? 'Enter 9 digits'
                              : null,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'email'),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'password'),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordConfirmController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: UserStrings.t(context, 'confirmPassword'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                      border: const OutlineInputBorder(),
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

                  const SizedBox(height: 8),
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

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.status == AuthStatus.authenticating
                        ? null
                        : _register,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            UserStrings.t(context, 'signupButton'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
}


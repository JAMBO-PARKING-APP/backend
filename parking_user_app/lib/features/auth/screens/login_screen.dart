import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/providers/country_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _countryCode = '+256';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountryProvider>().loadCountries();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primaryColor, AppTheme.primarySoft],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Image.asset('assets/images/logo.png', height: 80)),
                        const SizedBox(height: 18),
                        Text('Modern parking, without the friction', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to manage sessions, reservations, wallet payments, rewards, and notifications.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Consumer<CountryProvider>(
                          builder: (context, countryProv, _) {
                            if (countryProv.countries.isEmpty) {
                              return const SizedBox(
                                height: 50,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            // Ensure _countryCode is valid
                            if (!countryProv.countries.any((c) => c.code == _countryCode)) {
                              _countryCode = countryProv.countries.first.code;
                            }
                            return DropdownButtonFormField<String>(
                              value: _countryCode,
                              decoration: const InputDecoration(labelText: 'Country code'),
                              items: countryProv.countries.map((c) {
                                return DropdownMenuItem(
                                  value: c.code,
                                  child: Text('${c.flag ?? ''} ${c.name} (${c.code})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _countryCode = value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: '7XXXXXXXX',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 9) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: auth.status == AuthStatus.authenticating ? null : _submit,
                            child: auth.status == AuthStatus.authenticating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if ((auth.errorMessage ?? '').isNotEmpty)
                          Text(auth.errorMessage!, style: const TextStyle(color: AppTheme.errorColor)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('New here?'),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text('Create account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedCountry = context.read<CountryProvider>().countries.firstWhere(
        (c) => c.code == _countryCode,
        orElse: () => context.read<CountryProvider>().countries.first,
    );
    final phone = '${selectedCountry.phoneCode}${_phoneController.text.trim()}';
    final success = await context.read<AuthProvider>().login(
          phone,
          _passwordController.text,
        );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().errorMessage ?? 'Login failed')),
      );
    }
  }
}


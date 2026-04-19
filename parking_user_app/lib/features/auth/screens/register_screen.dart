import 'package:flutter/material.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/providers/country_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _countryCode = '+256';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountryProvider>().loadCountries();
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Consumer<CountryProvider>(
                  builder: (context, countryProv, _) {
                    if (countryProv.countries.isEmpty) {
                      return const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => value == null || value.trim().length < 9 ? 'Valid phone required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) => value != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.status == AuthStatus.authenticating ? null : _submit,
                    child: const Text('Create account'),
                  ),
                ),
              ],
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
    
    final success = await context.read<AuthProvider>().register(
          phoneNumber: '${selectedCountry.phoneCode}${_phone.text.trim()}',
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirm: _confirm.text,
        );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().errorMessage ?? 'Registration failed')),
      );
    }
  }
}

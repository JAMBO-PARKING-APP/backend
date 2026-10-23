import 'package:flutter/material.dart';
import 'package:parking_user_app/features/common/models/country_model.dart';
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
  String _countryCode = 'UG';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCountries();
    });
  }

  Future<void> _loadCountries() async {
    final countryProvider = context.read<CountryProvider>();
    await countryProvider.loadCountries();
    if (!mounted) return;

    final countries = _countriesWithDialCodes(countryProvider.countries);
    if (countries.isNotEmpty &&
        !countries.any((country) => country.code == _countryCode)) {
      setState(() {
        _countryCode = countries.any((country) => country.code == 'UG')
            ? 'UG'
            : countries.first.code;
      });
    }
  }

  List<Country> _countriesWithDialCodes(List<Country> countries) => countries
      .where((country) => country.phoneCode.trim().isNotEmpty)
      .toList();

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
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Consumer<CountryProvider>(
                  builder: (context, countryProv, _) {
                    if (countryProv.isLoading &&
                        countryProv.countries.isEmpty) {
                      return const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final countries = _countriesWithDialCodes(
                      countryProv.countries,
                    );
                    if (countries.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            countryProv.errorMessage ??
                                'No countries with phone codes are available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          TextButton(
                            onPressed: countryProv.isLoading
                                ? null
                                : _loadCountries,
                            child: const Text('Retry loading countries'),
                          ),
                        ],
                      );
                    }
                    final selectedCode =
                        countries.any((country) => country.code == _countryCode)
                        ? _countryCode
                        : countries.first.code;
                    return DropdownButtonFormField<String>(
                      initialValue: selectedCode,
                      decoration: const InputDecoration(labelText: 'Country'),
                      items: countries.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.flag} ${c.name} (${c.phoneCode})'),
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
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'Local number without country code',
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    return digits.length < 6
                        ? 'Enter a valid phone number'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty && !email.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Minimum 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) =>
                      value != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.status == AuthStatus.authenticating
                        ? null
                        : _submit,
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

    final countries = _countriesWithDialCodes(
      context.read<CountryProvider>().countries,
    );
    if (countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load a country before creating an account.'),
        ),
      );
      return;
    }
    final selectedCountry = countries.firstWhere(
      (country) => country.code == _countryCode,
      orElse: () => countries.first,
    );
    final enteredPhone = _phone.text.trim();
    final phoneDigits = enteredPhone.replaceAll(RegExp(r'\D'), '');
    final phoneNumber = enteredPhone.startsWith('+')
        ? '+$phoneDigits'
        : '${selectedCountry.phoneCode}'
              '${selectedCountry.code == 'UG' && phoneDigits.startsWith('0') ? phoneDigits.substring(1) : phoneDigits}';

    final success = await context.read<AuthProvider>().register(
      phoneNumber: phoneNumber,
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
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Registration failed',
          ),
        ),
      );
    }
  }
}

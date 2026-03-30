import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
// Removed GlassContainer import

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  const OtpVerificationScreen({
    super.key, 
    required this.phoneNumber,
    this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _handleVerify() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      widget.phoneNumber,
      _otpController.text,
      email: widget.email,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Verification failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
          // Solid background

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Verification',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a verification code to '),
                        TextSpan(
                          text: widget.email ?? widget.phoneNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.email != null)
                          const TextSpan(text: '\n(Check your inbox)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        TextField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              letterSpacing: 8,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.dividerColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            letterSpacing: 12,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return ElevatedButton(
                              onPressed:
                                  auth.status == AuthStatus.authenticating
                                  ? null
                                  : _handleVerify,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: auth.status == AuthStatus.authenticating
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'VERIFY & CONTINUE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await auth.resendOtp(
                              widget.phoneNumber,
                              email: widget.email,
                            );
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'OTP resent successfully!'
                                        : (auth.errorMessage ??
                                              'Failed to resend OTP'),
                                  ),
                                  backgroundColor: success
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Resend New Code',
                            style: TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String token;

  const VerifyEmailScreen({super.key, required this.token});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    if (widget.token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No verification token provided.';
      });
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.get(ApiConstants.verifyEmail, params: {'token': widget.token});
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Verification failed. The link may have expired.';
      });
    }
  }

  Future<void> _resendVerificationEmail(String email) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        ApiConstants.resendVerification,
        data: {'email': email},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent. Check your inbox.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not resend email. Please try again later.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showResendDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Resend Verification Email',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send a new verification link.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
            ),
          ),
          TextButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              Navigator.of(ctx).pop();
              if (email.isNotEmpty) _resendVerificationEmail(email);
            },
            child: const Text(
              'Send',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Campus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      TextSpan(
                        text: 'Core',
                        style: TextStyle(
                          color: AppColors.coreBlue,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LEARN  •  CONNECT  •  ACHIEVE',
                  style: TextStyle(
                    color: AppColors.textOnDarkSub,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 40),

                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _loading
                      ? _buildLoading()
                      : _success
                          ? _buildSuccess()
                          : _buildFailure(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 20),
        Text(
          'Verifying your email…',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Email Verified!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your email has been verified. You can now log in.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Go to Login',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailure() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel, color: AppColors.error, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verification Failed',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _error ?? 'Verification failed. The link may have expired.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showResendDialog,
            icon: const Icon(Icons.email_outlined),
            label: const Text(
              'Resend Verification Email',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text(
            'Back to Login',
            style: TextStyle(
              color: AppColors.primary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

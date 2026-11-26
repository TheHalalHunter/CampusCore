import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check your connection.';
          break;
        default:
          msg = e.message ?? 'Something went wrong. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? _SuccessView(email: _emailCtrl.text.trim())
            : _FormView(
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                loading: _loading,
                onSend: _send,
              ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_outlined,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 24),
          const Text('Forgot your password?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Valid email required' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : onSend,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 24),
        const Text('Check your inbox',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check your spam folder if you don\'t see it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/token_storage.dart';

// ── Departments provider ──────────────────────────────────────────────────────
final departmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final api  = ref.read(apiClientProvider);
    final resp = await api.get(ApiConstants.departments);
    final data = resp.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
  } catch (_) {}
  return [
    {'id': 'fisheries-lautech', 'name': 'Fisheries & Aquaculture — LAUTECH'},
  ];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _showSignUp = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 0,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────────────
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
                    child: Text('C',
                        style: TextStyle(
                          color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                        )),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'Campus',
                      style: TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
                    ),
                    TextSpan(
                      text: 'Core',
                      style: TextStyle(color: AppColors.coreBlue, fontSize: 26,
                          fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LEARN  •  CONNECT  •  ACHIEVE',
                  style: TextStyle(
                    color: AppColors.textOnDarkSub, fontSize: 10,
                    letterSpacing: 2, fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 32),

                // ── Card ──────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30, offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Toggle tabs ─────────────────────────────────
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            _TabButton(
                              label: 'Sign In',
                              selected: !_showSignUp,
                              onTap: () => setState(() => _showSignUp = false),
                              isLeft: true,
                            ),
                            _TabButton(
                              label: 'Sign Up',
                              selected: _showSignUp,
                              onTap: () => setState(() => _showSignUp = true),
                              isLeft: false,
                            ),
                          ],
                        ),
                      ),

                      // ── Form ────────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _showSignUp
                            ? _SignUpForm(
                                key: const ValueKey('signup'),
                                onSuccess: () => context.go('/'),
                                onSwitchToSignIn: () =>
                                    setState(() => _showSignUp = false),
                              )
                            : _SignInForm(
                                key: const ValueKey('signin'),
                                onSuccess: () => context.go('/'),
                                onSwitchToSignUp: () =>
                                    setState(() => _showSignUp = true),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLeft;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft:  isLeft  ? const Radius.circular(20) : Radius.zero,
              topRight: !isLeft ? const Radius.circular(20) : Radius.zero,
            ),
            border: selected
                ? Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2.5),
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textHint,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sign In Form ──────────────────────────────────────────────────────────────
class _SignInForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSwitchToSignUp;

  const _SignInForm({
    required this.onSuccess,
    required this.onSwitchToSignUp,
    super.key,
  });

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showResetDialog(prefillEmail: email);
      return;
    }
    await _sendReset(email);
  }

  Future<void> _sendReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Check your email',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          content: Text(
            'A password reset link has been sent to $email. Check your inbox.',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'user-not-found'
          ? 'No account found with that email.'
          : 'Could not send reset email. Please try again.';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Error',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.primary, fontFamily: 'Nunito')),
            ),
          ],
        ),
      );
    }
  }

  void _showResetDialog({String prefillEmail = ''}) {
    final ctrl = TextEditingController(text: prefillEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address and we\'ll send you a reset link.',
                style: TextStyle(fontFamily: 'Nunito')),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
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
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textHint, fontFamily: 'Nunito')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (ctrl.text.trim().isNotEmpty) _sendReset(ctrl.text.trim());
            },
            child: const Text('Send Reset Link',
                style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref.read(authProvider.notifier).signIn(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (error == null && mounted) widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final isLoading = auth.isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitSignIn(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 6) return 'Password too short';
                return null;
              },
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : _forgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 10),
              _ErrorBox(message: auth.error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitSignIn,
                child: isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),

            // ── Divider ───────────────────────────────────────────────
            Row(children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontFamily: 'Nunito')),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ]),
            const SizedBox(height: 12),

            // ── Google sign-in ────────────────────────────────────────
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () async {
                  final error = await ref.read(authProvider.notifier).signInWithGoogle();
                  if (error == null && context.mounted) widget.onSuccess();
                },
                icon: _GoogleIcon(),
                label: const Text('Continue with Google',
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ",
                    style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13, fontFamily: 'Nunito')),
                GestureDetector(
                  onTap: widget.onSwitchToSignUp,
                  child: const Text('Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13, fontFamily: 'Nunito',
                        decoration: TextDecoration.underline,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign Up Form ──────────────────────────────────────────────────────────────
class _SignUpForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSwitchToSignIn;

  const _SignUpForm({
    required this.onSuccess,
    required this.onSwitchToSignIn,
    super.key,
  });

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  bool    _obscure     = true;
  bool    _obscureConf = true;
  bool    _loading     = false;
  String? _error;
  String? _selectedDeptId;
  String  _selectedLevel = '100L';

  final _levels = ['100L', '200L', '300L', '400L', '500L'];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null) {
      setState(() => _error = 'Please select your department.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      // 1. Create Firebase account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final firebaseToken = await credential.user?.getIdToken();
      if (firebaseToken == null) throw Exception('Firebase token error');

      // 2. Exchange with backend (auto-creates user in DB)
      final api  = ref.read(apiClientProvider);
      final resp = await api.post(ApiConstants.login, data: {
        'idToken':       firebaseToken,
        'fullName':      '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'departmentId':  _selectedDeptId,
        'academicLevel': _selectedLevel,
      });

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        await credential.user?.delete(); // rollback Firebase account
        setState(() {
          _loading = false;
          _error   = body['message']?.toString() ?? 'Registration failed.';
        });
        return;
      }

      final tokenData    = body['data'] as Map<String, dynamic>;
      final accessToken  = tokenData['accessToken']?.toString()  ?? '';
      final refreshToken = tokenData['refreshToken']?.toString();
      final userData     = tokenData['user'] as Map<String, dynamic>? ?? {};

      await TokenStorage.saveTokens(
          accessToken: accessToken, refreshToken: refreshToken);
      final user = AppUser.fromJson(userData);
      await TokenStorage.saveUser(jsonEncode(user.toJson()));
      ref.read(authProvider.notifier).setUserDirectly(user);

      if (mounted) widget.onSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() { _loading = false; _error = _firebaseMsg(e.code); });
    } catch (e) {
      setState(() { _loading = false; _error = 'Registration failed. Please try again.'; });
    }
  }

  String _firebaseMsg(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'weak-password':
        return 'Password too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final depts = ref.watch(departmentsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'First Name *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Last Name *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Department dropdown
            depts.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => DropdownButtonFormField<String>(
                value: _selectedDeptId,
                decoration: const InputDecoration(
                  labelText: 'Department *',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                hint: const Text('Select department',
                    style: TextStyle(fontFamily: 'Nunito')),
                items: list
                    .map((d) => DropdownMenuItem(
                          value: d['id']?.toString(),
                          child: Text(
                            d['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontFamily: 'Nunito'),
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() { _selectedDeptId = v; _error = null; }),
                validator: (v) =>
                    v == null ? 'Select your department' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Academic level
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Academic Level *',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: _levels
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l,
                            style: const TextStyle(fontFamily: 'Nunito')),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLevel = v!),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConf,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConf
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConf = !_obscureConf),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              _ErrorBox(message: _error!),
            ],

            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 12),

            // ── Divider ───────────────────────────────────────────────
            Row(children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontFamily: 'Nunito')),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ]),
            const SizedBox(height: 12),

            // ── Google sign-up ────────────────────────────────────────
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () async {
                  final error = await ref.read(authProvider.notifier).signInWithGoogle();
                  if (error == null && context.mounted) widget.onSuccess();
                },
                icon: _GoogleIcon(),
                label: const Text('Continue with Google',
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13, fontFamily: 'Nunito')),
                GestureDetector(
                  onTap: widget.onSwitchToSignIn,
                  child: const Text('Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13, fontFamily: 'Nunito',
                        decoration: TextDecoration.underline,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google icon ───────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: const Center(
        child: Text('G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            )),
      ),
    );
  }
}

// ── Error box ─────────────────────────────────────────────────────────────────
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    // Show friendlier message for service unavailable
    final display = message.contains('503') || message.contains('temporarily unavailable')
        ? 'Our auth service is starting up. Please wait 30 seconds and try again.'
        : message;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(display,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }
}

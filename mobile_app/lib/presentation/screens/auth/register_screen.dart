import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/university_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _selectedLevel;
  String? _selectedUniversityId;
  String? _selectedDepartmentId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Create Firebase account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // 2. Update display name in Firebase
      await credential.user?.updateDisplayName(_nameCtrl.text.trim());

      // 3. Exchange Firebase token for platform JWT
      final dept = _selectedDepartmentId;
      await ref.read(authProvider.notifier).registerWithFirebase(
            firebaseUser: credential.user!,
            fullName: _nameCtrl.text.trim(),
            departmentId: dept,
            academicLevel: _selectedLevel,
          );

      // 4. Navigate to verify-email screen (email verification required before login)
      if (mounted) {
        context.go('${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e.code)),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join CampusCore',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Create your free student account',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // Full name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v == null || v.length < 8
                    ? 'At least 8 characters required'
                    : null,
              ),
              const SizedBox(height: 16),

              // University dropdown
              ref.watch(universitiesProvider).when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (unis) => DropdownButtonFormField<String>(
                  key: ValueKey(_selectedUniversityId),
                  initialValue: _selectedUniversityId,
                  decoration: const InputDecoration(
                    labelText: 'University',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  hint: const Text('Select university'),
                  items: unis
                      .map((u) => DropdownMenuItem(
                            value: u['id']?.toString(),
                            child: Text(
                              u['name']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedUniversityId = v;
                    _selectedDepartmentId = null;
                  }),
                  validator: (v) =>
                      v == null ? 'Please select your university' : null,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'More universities coming soon. Contact us to add your university.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              // Department dropdown — only shown after university selected
              if (_selectedUniversityId != null) ...[
                ref.watch(departmentsByUniversityProvider(_selectedUniversityId)).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (depts) => DropdownButtonFormField<String>(
                    key: ValueKey(_selectedDepartmentId),
                    initialValue: _selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    hint: const Text('Select department'),
                    items: depts
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDepartmentId = v),
                    validator: (v) =>
                        v == null ? 'Please select your department' : null,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Academic level
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Academic Level',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: ['100L', '200L', '300L', '400L', '500L']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLevel = v),
                validator: (v) => v == null ? 'Please select your level' : null,
              ),
              const SizedBox(height: 28),

              // Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/user_provider.dart';

class IntegrityPolicyScreen extends ConsumerStatefulWidget {
  const IntegrityPolicyScreen({super.key});

  @override
  ConsumerState<IntegrityPolicyScreen> createState() =>
      _IntegrityPolicyScreenState();
}

class _IntegrityPolicyScreenState extends ConsumerState<IntegrityPolicyScreen> {
  bool _scrolledToBottom = false;
  bool _isAccepting = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (!_scrolledToBottom &&
          _scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent - 40) {
        setState(() => _scrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(ApiConstants.acceptPolicy);
      // Refresh user so acceptedIntegrityPolicy flips to true
      ref.invalidate(currentUserProvider);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Academic Integrity Policy'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Policy text — scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_user,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'CampusCore Academic Integrity Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please read the full policy before accepting.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Section(
                    title: '1. Purpose',
                    body:
                        'CampusCore is an academic platform built to support learning, collaboration, and academic excellence among Nigerian university students. This policy outlines the standards of conduct expected of every user to maintain the integrity of the platform and the academic community.',
                  ),
                  const _Section(
                    title: '2. Honesty and Original Work',
                    body:
                        'You must only upload academic materials that you have the right to share. Do not upload copyrighted materials without permission. When sharing resources, credit the original author where applicable. All content you contribute should be accurate and helpful to fellow students.',
                  ),
                  const _Section(
                    title: '3. Prohibited Conduct',
                    body:
                        'The following are strictly prohibited on CampusCore:\n\n'
                        '• Using the AI assistant to answer live exam questions.\n'
                        '• Uploading or distributing leaked examination papers.\n'
                        '• Impersonating lecturers, moderators, or other students.\n'
                        '• Posting misleading, false, or harmful academic information.\n'
                        '• Harassment, bullying, or discriminatory behaviour of any kind.\n'
                        '• Sharing personal data of other users without their consent.',
                  ),
                  const _Section(
                    title: '4. AI Study Assistant',
                    body:
                        'The AI assistant is designed to help you learn and understand academic concepts. It must not be used to obtain answers to ongoing assessments, tests, or examinations. CampusCore employs automated detection for such requests. Violations will result in immediate suspension of AI access and may lead to account termination.',
                  ),
                  const _Section(
                    title: '5. Resource Sharing',
                    body:
                        'Resources uploaded to CampusCore are for educational purposes only. By uploading, you grant CampusCore a non-exclusive licence to display and distribute the content within the platform. All uploads are reviewed by moderators before being made available to ensure quality and appropriateness.',
                  ),
                  const _Section(
                    title: '6. Reporting Violations',
                    body:
                        'If you encounter content or behaviour that violates this policy, use the in-app report feature. Reports are reviewed by moderators within 48 hours. Good-faith reports are confidential and reporters are protected from retaliation.',
                  ),
                  const _Section(
                    title: '7. Consequences of Violations',
                    body: 'Violations of this policy may result in:\n\n'
                        '• Content removal without notice.\n'
                        '• Temporary or permanent suspension of account features.\n'
                        '• Permanent account termination for serious breaches.\n\n'
                        'CampusCore reserves the right to take any of these actions at its discretion.',
                  ),
                  const _Section(
                    title: '8. Acceptance',
                    body:
                        'By accepting this policy, you confirm that you have read, understood, and agree to abide by these terms. Your use of CampusCore is contingent on ongoing compliance with this policy.',
                  ),
                  const SizedBox(height: 8),
                  // Scroll indicator
                  if (!_scrolledToBottom)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 14, color: AppColors.textHint),
                            SizedBox(width: 4),
                            Text('Scroll to read the full policy',
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Accept footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                  top: const BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_scrolledToBottom)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: const Text(
                      'Read the full policy to enable the accept button.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                    ),
                  ),
                ElevatedButton(
                  onPressed:
                      (_scrolledToBottom && !_isAccepting) ? _accept : null,
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('I Accept the Academic Integrity Policy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'\d'));
  bool get _hasSpecial =>
      password.contains(RegExp(r'[@$!%*?&_#\-]'));

  int get _metCount {
    int count = 0;
    if (_hasMinLength) count++;
    if (_hasUppercase) count++;
    if (_hasLowercase) count++;
    if (_hasNumber) count++;
    if (_hasSpecial) count++;
    return count;
  }

  String get _strengthLabel {
    final c = _metCount;
    if (c <= 1) return 'Weak';
    if (c <= 3) return 'Fair';
    if (c == 4) return 'Strong';
    return 'Very Strong';
  }

  Color get _strengthColor {
    final c = _metCount;
    if (c <= 1) return Colors.red;
    if (c <= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final met = _metCount;
    final color = _strengthColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final filled = i < met;
            Color barColor;
            if (!filled) {
              barColor = AppColors.border;
            } else if (met <= 1) {
              barColor = Colors.red;
            } else if (met <= 3) {
              barColor = Colors.orange;
            } else {
              barColor = Colors.green;
            }
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _strengthLabel,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _CheckRow(label: 'At least 8 characters', met: _hasMinLength),
        _CheckRow(label: 'Contains uppercase letter', met: _hasUppercase),
        _CheckRow(label: 'Contains lowercase letter', met: _hasLowercase),
        _CheckRow(label: 'Contains a number', met: _hasNumber),
        _CheckRow(
            label: r'Contains a special character (@$!%*?&_#-)',
            met: _hasSpecial),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool met;

  const _CheckRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: met ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

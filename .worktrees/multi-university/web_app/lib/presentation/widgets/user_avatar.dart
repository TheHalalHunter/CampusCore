import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Reusable avatar widget — shows profile image if available, else initials.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final double fontSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryLight;
    final url = avatarUrl?.isNotEmpty == true ? avatarUrl : null;

    if (url != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initials.isEmpty ? '?' : initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

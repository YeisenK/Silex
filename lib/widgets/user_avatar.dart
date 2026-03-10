import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String avatarPath;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceColor,
      child: ClipOval(
        child: Image.asset(
          avatarPath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String avatarPath;
  final String name;
  final double radius;
  final String? avatarBase64;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.radius = 20,
    this.avatarBase64,
  });

  @override
  Widget build(BuildContext context) {
    // priority: base64 from server > local asset > initials
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.surfaceColor,
        backgroundImage: MemoryImage(base64Decode(avatarBase64!)),
      );
    }

    if (avatarPath.isNotEmpty) {
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
              return _buildInitials();
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceColor,
      child: _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Text(
      initial,
      style: TextStyle(
        color: AppTheme.accentColor,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
        fontFamily: 'BarlowCondensed',
      ),
    );
  }
}

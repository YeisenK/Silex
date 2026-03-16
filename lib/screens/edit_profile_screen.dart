import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final String? currentName;
  final String? currentAvatarBase64;

  const EditProfileScreen({
    super.key,
    this.currentName,
    this.currentAvatarBase64,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  String? _avatarBase64;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName ?? '');
    _avatarBase64 = widget.currentAvatarBase64;
    _nameController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final result = await ProfileService.pickAndUploadAvatar();
      if (result != null) {
        setState(() {
          _avatarBase64 = result;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await ProfileService.updateDisplayName(name);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accentColor,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar ──
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppTheme.backgroundSecondary,
                    backgroundImage: _avatarBase64 != null
                        ? MemoryImage(base64Decode(_avatarBase64!))
                        : null,
                    child: _avatarBase64 == null
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: AppTheme.textSecondary,
                              fontFamily: 'BarlowCondensed',
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundPrimary,
                          width: 2,
                        ),
                      ),
                      child: _isPickingImage
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Tap to change photo',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 32),

            // ── Name field ──
            TextField(
              controller: _nameController,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Display name',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundSecondary,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppTheme.textSecondary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.accentColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'This name will be visible to people you message who don\'t have you in their contacts.',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _avatarUrl;
  File? _selectedImage;
  String _color = '#4A6741';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? {};
    final metadataName = (metadata['display_name'] as String?) ??
        (metadata['full_name'] as String?) ??
        (metadata['name'] as String?);
    final metadataUsername = (metadata['username'] as String?) ??
        (metadata['preferred_username'] as String?);
    final metadataAvatar = (metadata['avatar_url'] as String?) ??
        (metadata['picture'] as String?);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profileName = response['display_name'] as String?;
      final profileUsername = response['username'] as String?;
      final emailPrefix =
          user.email != null ? user.email!.split('@').first : '';

      setState(() {
        _displayNameController.text = (profileName != null &&
                profileName != emailPrefix)
            ? profileName
            : (metadataName ?? profileName ?? '');
        _usernameController.text = (profileUsername != null &&
                profileUsername != emailPrefix)
            ? profileUsername
            : (metadataUsername ?? profileUsername ?? '');
        _avatarUrl =
            (response['avatar_url'] as String?) ?? metadataAvatar;
        _isPublic =
            (response['calendar_visibility'] as String?) == 'public';
        _color = (response['color'] as String?) ?? '#4A6741';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      setState(() => _error = 'Could not select image: $e');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.appColors;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXLarge),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                Text(
                  'Change photo',
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.spacing20),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: AppSpacing.spacing16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _uploadAvatar(String userId) async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return _avatarUrl;

    final extension = selectedImage.path.split('.').last.toLowerCase();
    final ext = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    await Supabase.instance.client.storage.from('avatars').upload(
          fileName,
          selectedImage,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(fileName);
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (displayName.isEmpty || username.isEmpty) {
      setState(() {
        _error = 'Display name and username are required';
        _isSaving = false;
      });
      return;
    }

    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .neq('id', user.id)
        .maybeSingle();
    if (existing != null) {
      setState(() {
        _error = 'Username @$username is already taken. Try another one.';
        _isSaving = false;
      });
      return;
    }

    try {
      final avatarUrl = await _uploadAvatar(user.id);

      final newProfile = {
        'id': user.id,
        'display_name': displayName,
        'username': username,
        'avatar_url': avatarUrl,
        'calendar_visibility': _isPublic ? 'public' : 'private',
        'color': _color,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profiles')
          .update(newProfile)
          .eq('id', user.id);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
            'username': username,
            'avatar_url': avatarUrl,
          },
        ),
      );

      if (mounted) Navigator.of(context).pop(newProfile);
    } catch (e) {
      setState(() {
        _error = 'Could not save profile: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing24),
                  Text('Edit Profile', style: context.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.spacing24),

                  // Avatar picker
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: colors.accentSoft,
                            backgroundImage: _avatarImage,
                            child: _avatarChild,
                          ),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.accent,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing24),

                  TextField(
                    controller: _displayNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'How others see you',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),

                  TextField(
                    controller: _usernameController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Unique handle',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing20),

                  // Calendar visibility toggle
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing16),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPublic
                              ? Icons.public
                              : Icons.lock_outline,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calendar visibility',
                                style: context.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isPublic
                                    ? 'Public: friends can see your calendar'
                                    : 'Private: only you see your calendar',
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) =>
                              setState(() => _isPublic = value),
                          activeThumbColor: colors.accent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.spacing20),

                  // Task color picker
                  Text(
                    'My task color',
                    style: context.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.spacing8),
                  Wrap(
                    spacing: AppSpacing.spacing12,
                    runSpacing: AppSpacing.spacing12,
                    children: _colorPalette.map((hex) {
                      final selected = hex == _color;
                      return GestureDetector(
                        onTap: () => setState(() => _color = hex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? colors.textPrimary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.spacing16),
                    Text(
                      _error!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.urgent,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.spacing24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                ],
              ),
            ),
    );
  }

  ImageProvider? get _avatarImage {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  Widget? get _avatarChild {
    if (_selectedImage != null ||
        (_avatarUrl != null && _avatarUrl!.isNotEmpty)) {
      return null;
    }
    final initial = _displayNameController.text.isNotEmpty
        ? _displayNameController.text[0].toUpperCase()
        : '?';
    return Text(
      initial,
      style: context.textTheme.displaySmall?.copyWith(
        color: context.appColors.accent,
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  static const _colorPalette = [
    '#4A6741',
    '#5A7C51',
    '#6B8C7A',
    '#6B8FA3',
    '#7A7A8C',
    '#8C7B6B',
    '#9B7A5B',
    '#A36B6B',
    '#8E6B9B',
    '#6B5B8C',
  ];
}

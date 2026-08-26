import 'package:flutter/material.dart';
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
  final _avatarUrlController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _displayNameController.text =
            (response['display_name'] as String?) ?? '';
        _usernameController.text =
            (response['username'] as String?) ?? '';
        _avatarUrlController.text =
            (response['avatar_url'] as String?) ?? '';
        _isPublic =
            (response['calendar_visibility'] as String?) == 'public';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final avatarUrl = _avatarUrlController.text.trim().isEmpty
        ? null
        : _avatarUrlController.text.trim();

    if (displayName.isEmpty || username.isEmpty) {
      setState(() {
        _error = 'Display name and username are required';
        _isSaving = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': displayName,
        'username': username,
        'avatar_url': avatarUrl,
        'calendar_visibility': _isPublic ? 'public' : 'private',
        'updated_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
            'username': username,
            'avatar_url': avatarUrl,
          },
        ),
      );

      if (mounted) Navigator.of(context).pop(true);
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
                  const SizedBox(height: AppSpacing.spacing20),

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
                  const SizedBox(height: AppSpacing.spacing16),

                  TextField(
                    controller: _avatarUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Avatar URL',
                      hintText: 'Optional image URL',
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
}

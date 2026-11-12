import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_avatar.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../domain/entities/profile.dart';
import '../cubit/profile_cubit.dart';

/// Name, username and photo. Saving goes through [ProfileCubit]; the sheet
/// closes when a save lands and shows the reason when it doesn't.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({required this.controller, super.key});

  final ScrollController controller;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final Profile _profile = context.read<ProfileCubit>().state.profile!;
  late final _name = TextEditingController(text: _profile.displayName);
  late final _username = TextEditingController(text: _profile.username);
  String? _photoPath;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _photoPath = picked.path);
    } on Exception {
      // Permission denied or no camera: keep the current photo.
    }
  }

  Future<void> _choosePhoto() async {
    final l10n = context.l10n;
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.changePhoto),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: Text(l10n.chooseFromGallery),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: Text(l10n.takePhoto),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  void _save() => context.read<ProfileCubit>().save(
    ProfileDraft(
      displayName: _name.text,
      username: _username.text,
      avatarPath: _photoPath,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => a.saveCount != b.saveCount,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) {
        final error = switch (state.saveError) {
          ProfileSaveError.nameMissing => l10n.nameRequired,
          ProfileSaveError.usernameInvalid => l10n.usernameInvalid,
          ProfileSaveError.usernameTaken => l10n.usernameTaken,
          ProfileSaveError.failed => l10n.profileSaveFailed,
          null => null,
        };
        final photo = _photoPath;

        return ListView(
          controller: widget.controller,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.spacing8,
            AppSpacing.screenMargin,
            AppSpacing.spacing32 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(l10n.editProfile, style: context.typography.title1),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Center(
              child: Semantics(
                button: true,
                label: l10n.changePhoto,
                child: GestureDetector(
                  onTap: _choosePhoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (photo != null)
                        ClipOval(
                          child: Image.file(
                            File(photo),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        KairoAvatar(
                          name: _profile.displayName,
                          imageUrl: _profile.avatarUrl,
                          size: 96,
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: colors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 3),
                          ),
                          child: Icon(
                            CupertinoIcons.camera_fill,
                            size: 15,
                            color: colors.onInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            _Field(
              controller: _name,
              label: l10n.displayName,
              hint: l10n.displayNameHint,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _Field(
              controller: _username,
              label: l10n.username,
              hint: l10n.usernameHint,
              prefix: '@',
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.spacing12),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: context.typography.footnote.copyWith(
                    color: colors.destructive,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing24),
            KairoButton(
              label: l10n.saveChanges,
              expand: true,
              loading: state.saving,
              onPressed: _save,
            ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefix,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: context.typography.footnote.copyWith(
              color: colors.labelSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          autocorrect: false,
          textCapitalization: capitalization,
          style: context.typography.body,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: colors.fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

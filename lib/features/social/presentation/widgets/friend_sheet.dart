import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../calendar/presentation/widgets/calendar_colors.dart';
import '../../domain/entities/friend.dart';
import '../bloc/social_bloc.dart';
import 'person_avatar.dart';

/// A friend: their color in my calendar (the five tones), a task together,
/// and removing them (with a confirmation).
class FriendSheet extends StatelessWidget {
  const FriendSheet({
    required this.friendId,
    required this.controller,
    required this.onCreateTask,
    super.key,
  });

  final String friendId;
  final ScrollController controller;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final friend = state.friends.where((f) => f.id == friendId).firstOrNull;
        if (friend == null) return const SizedBox.shrink();
        final current = toneFor(friend.id, friend.color);
        final username = friend.username;

        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.spacing16,
            AppSpacing.screenMargin,
            AppSpacing.spacing32,
          ),
          children: [
            Center(
              child: PersonAvatar(
                id: friend.id,
                name: friend.name,
                imageUrl: friend.avatarUrl,
                color: friend.color,
                size: 88,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            Text(
              friend.name,
              textAlign: TextAlign.center,
              style: context.typography.title1,
            ),
            if (username != null && username.isNotEmpty)
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: context.typography.subheadline.copyWith(
                  color: colors.labelSecondary,
                ),
              ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              l10n.friendColor,
              style: context.typography.footnote.copyWith(
                color: colors.labelSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final tone in CalendarTone.all)
                  _ToneSwatch(
                    tone: tone,
                    selected: tone == current,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      context.read<SocialBloc>().add(
                        FriendColorChanged(friend, _hex(tone.dot)),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing24),
            KairoButton(
              label: l10n.createTaskTogether,
              icon: CupertinoIcons.plus,
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                onCreateTask();
              },
            ),
            const SizedBox(height: AppSpacing.spacing8),
            KairoButton(
              label: l10n.removeFriend,
              variant: KairoButtonVariant.plain,
              destructive: true,
              expand: true,
              onPressed: () => _confirmRemove(context, friend),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, Friend friend) async {
    final l10n = context.l10n;
    final bloc = context.read<SocialBloc>();
    final navigator = Navigator.of(context);
    final remove = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.removeFriendQuestion(friend.name)),
        content: Text(l10n.removeFriendHint),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeFriend),
          ),
        ],
      ),
    );
    if (remove ?? false) {
      bloc.add(FriendRemoved(friend));
      navigator.pop();
    }
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _ToneSwatch extends StatelessWidget {
  const _ToneSwatch({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final CalendarTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: tone.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 52,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.dot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.label : Colors.transparent,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: selected
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 20,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../domain/entities/person.dart';
import '../bloc/social_bloc.dart';
import 'person_avatar.dart';

/// Search by username and send requests. The query is debounced in
/// [SocialBloc]; each result shows how the person relates to me.
class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({required this.controller, super.key});

  final ScrollController controller;

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  late final _field = TextEditingController(
    text: context.read<SocialBloc>().state.query,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final results = state.results;
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
              child: Text(l10n.addFriend, style: context.typography.title1),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            TextField(
              controller: _field,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              style: context.typography.body,
              onChanged: (q) =>
                  context.read<SocialBloc>().add(SocialSearchChanged(q)),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: colors.labelSecondary,
                ),
                suffixIcon: state.searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CupertinoActivityIndicator(),
                      )
                    : null,
                filled: true,
                fillColor: colors.fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            if (state.query.isEmpty)
              EmptyState(
                icon: CupertinoIcons.person_2,
                title: l10n.searchPrompt,
              )
            else if (!state.searching && results.isEmpty)
              EmptyState(icon: CupertinoIcons.search, title: l10n.noPeopleFound)
            else if (results.isNotEmpty)
              KairoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < results.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 72,
                          color: colors.separator,
                        ),
                      _ResultRow(person: results[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bloc = context.read<SocialBloc>();
    final username = person.username;

    final trailing = switch (person.relation) {
      Relation.friend => _Status(
        icon: CupertinoIcons.checkmark_alt,
        label: l10n.friends,
      ),
      Relation.requested => _Status(
        icon: CupertinoIcons.hourglass,
        label: l10n.pending,
      ),
      Relation.incoming => KairoButton(
        label: l10n.acceptRequest,
        variant: KairoButtonVariant.tinted,
        onPressed: () {
          final request = bloc.state.requests
              .where((r) => r.from.id == person.id)
              .firstOrNull;
          if (request != null) {
            bloc.add(FriendRequestAnswered(request, accept: true));
          }
        },
      ),
      Relation.none => IconButton(
        tooltip: l10n.sendFriendRequest,
        onPressed: () => bloc.add(FriendRequestSent(person)),
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        style: IconButton.styleFrom(backgroundColor: colors.tintSoft),
        icon: Icon(CupertinoIcons.person_add, color: colors.tint, size: 20),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          PersonAvatar(
            id: person.id,
            name: person.name,
            imageUrl: person.avatarUrl,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: context.typography.headline),
                if (username != null && username.isNotEmpty)
                  Text(
                    '@$username',
                    style: context.typography.footnote.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          trailing,
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.labelSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.typography.subheadline.copyWith(
            color: colors.labelSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

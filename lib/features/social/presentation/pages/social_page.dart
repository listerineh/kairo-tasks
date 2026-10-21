import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_card.dart';
import '../../../../core/widgets/kairo_entrance.dart';
import '../../../../core/widgets/kairo_sheet.dart';
import '../../../../core/widgets/kairo_tab_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/widgets/task_feedback.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../domain/entities/friend.dart';
import '../../domain/shared_tasks.dart';
import '../bloc/social_bloc.dart';
import '../widgets/add_friend_sheet.dart';
import '../widgets/friend_sheet.dart';
import '../widgets/friends_strip.dart';
import '../widgets/request_card.dart';
import '../widgets/shared_task_card.dart';

/// Juntos (docs/redesign-plan.md §2.3): requests, friends, and the tasks you
/// share, with a nudge and a focus session for each.
class SocialPage extends StatelessWidget {
  const SocialPage({super.key, this.bloc});

  /// Tests pass their own; the app builds one from DI.
  final SocialBloc? bloc;

  @override
  Widget build(BuildContext context) {
    final injected = bloc;
    return injected != null
        ? BlocProvider.value(value: injected, child: const SocialView())
        : BlocProvider(
            create: (_) => getIt<SocialBloc>()..add(const SocialStarted()),
            child: const SocialView(),
          );
  }
}

class SocialView extends StatelessWidget {
  const SocialView({super.key, this.now});

  /// Fixed in goldens; otherwise the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return TaskFeedbackListener(
      child: BlocListener<SocialBloc, SocialState>(
        listenWhen: (a, b) => a.noticeCount != b.noticeCount,
        listener: _showNotice,
        child: Scaffold(
          backgroundColor: context.appColors.background,
          body: SafeArea(
            bottom: false,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: context.appColors.label),
              child: BlocBuilder<SocialBloc, SocialState>(
                builder: (context, social) => switch (social.status) {
                  SocialStatus.loading => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  SocialStatus.failure => _loadError(context),
                  SocialStatus.ready => BlocBuilder<TasksBloc, TasksState>(
                    buildWhen: (a, b) => a.tasks != b.tasks,
                    builder: (context, tasks) =>
                        _content(context, social, sharedTasks(tasks.tasks)),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    SocialState state,
    List<TaskEntity> shared,
  ) {
    final l10n = context.l10n;
    final bloc = context.read<SocialBloc>();
    final time = now ?? DateTime.now();
    final bottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      KairoTabBar.contentPadding(context),
    );

    final sections = <Widget>[
      _Header(
        count: state.friends.length,
        onAdd: () => _openAddFriend(context),
      ),
      for (final r in state.requests)
        RequestCard(
          key: ValueKey('request-${r.id}'),
          request: r,
          onAccept: () {
            unawaited(HapticFeedback.lightImpact());
            bloc.add(FriendRequestAnswered(r, accept: true));
          },
          onDecline: () => bloc.add(FriendRequestAnswered(r, accept: false)),
        ),
      if (state.friends.isEmpty)
        KairoCard(
          child: EmptyState(
            icon: CupertinoIcons.person_2,
            title: l10n.noFriendsTitle,
            message: l10n.friendsNone,
            action: KairoButton(
              label: l10n.addFriend,
              icon: CupertinoIcons.person_add,
              variant: KairoButtonVariant.tinted,
              onPressed: () => _openAddFriend(context),
            ),
          ),
        )
      else
        FriendsStrip(
          friends: state.friends,
          onOpen: (f) => _openFriend(context, f),
        ),
      if (state.friends.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spacing4,
            AppSpacing.spacing8,
            AppSpacing.spacing4,
            0,
          ),
          child: Semantics(
            header: true,
            child: Text(l10n.doingTogether, style: context.typography.title2),
          ),
        ),
        if (shared.isEmpty)
          KairoCard(
            child: EmptyState(
              icon: CupertinoIcons.hand_raised,
              title: l10n.doingTogetherEmpty,
              message: l10n.doingTogetherEmptyHint,
            ),
          )
        else
          for (final t in shared)
            SharedTaskCard(
              key: ValueKey('shared-${t.id}'),
              task: t,
              now: time,
              nudged: state.nudged.contains(t.id),
              onNudge: () {
                unawaited(HapticFeedback.selectionClick());
                bloc.add(NudgeSent(t));
              },
              onFocus: () => context.push('/focus', extra: t),
              onOpen: () => showTaskDetail(context, t),
            ),
      ],
    ];

    return RefreshIndicator.adaptive(
      onRefresh: () {
        final done = Completer<void>();
        bloc.add(SocialRefreshed(done));
        return done.future;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.spacing12,
          AppSpacing.screenMargin,
          bottom,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppSpacing.spacing12),
        itemBuilder: (context, i) =>
            KairoEntrance(index: i.clamp(0, 5), child: sections[i]),
      ),
    );
  }

  Widget _loadError(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          title: l10n.socialLoadError,
          action: KairoButton(
            label: l10n.tryAgain,
            variant: KairoButtonVariant.tinted,
            onPressed: () =>
                context.read<SocialBloc>().add(const SocialStarted()),
          ),
        ),
      ),
    );
  }

  static void _showNotice(BuildContext context, SocialState state) {
    final l10n = context.l10n;
    final text = switch (state.notice) {
      SocialNotice.requestSent => l10n.friendRequestSent,
      SocialNotice.requestAccepted => l10n.friendRequestAccepted,
      SocialNotice.requestDeclined => l10n.requestDeclined,
      SocialNotice.friendRemoved => l10n.friendRemoved,
      SocialNotice.nudged => l10n.nudgeSent,
      SocialNotice.nudgedRecently => l10n.nudgedRecently,
      SocialNotice.failed => l10n.socialActionFailed,
      null => null,
    };
    if (text == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  /// Sheets live on the root navigator, above this page's provider.
  static void _openAddFriend(BuildContext context) {
    final bloc = context.read<SocialBloc>();
    unawaited(
      showKairoSheet<void>(
        context: context,
        detents: const [KairoSheetDetent.large],
        builder: (context, controller) => BlocProvider.value(
          value: bloc,
          child: AddFriendSheet(controller: controller),
        ),
      ).whenComplete(() => bloc.add(const SocialSearchChanged(''))),
    );
  }

  static void _openFriend(BuildContext context, Friend friend) {
    final bloc = context.read<SocialBloc>();
    final pageContext = context;
    unawaited(
      showKairoSheet<void>(
        context: context,
        detents: const [KairoSheetDetent.medium, KairoSheetDetent.large],
        builder: (context, controller) => BlocProvider.value(
          value: bloc,
          child: FriendSheet(
            friendId: friend.id,
            controller: controller,
            onCreateTask: () => unawaited(
              showTaskForm(pageContext, initialFriendId: friend.id),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.togetherPeople(count),
                  style: context.typography.subheadline.copyWith(
                    color: colors.labelSecondary,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.navTogether,
                    style: context.typography.largeTitle,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.addFriend,
            excludeSemantics: true,
            child: Pressable(
              onPressed: onAdd,
              child: Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: ShapeDecoration(
                  color: colors.surface,
                  shape: CircleBorder(
                    side: BorderSide(color: colors.separator),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.person_add,
                  size: 20,
                  color: colors.label,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

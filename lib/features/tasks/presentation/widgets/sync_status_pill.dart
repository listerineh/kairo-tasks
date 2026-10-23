import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/task_sync_status.dart';
import '../../domain/usecases/watch_sync_status.dart';

/// A quiet pill that only appears when tasks can't reach the server
/// ("Sin conexión · tus cambios se guardan aquí") or while waiting changes
/// are being sent. Takes no room otherwise.
class SyncStatusPill extends StatefulWidget {
  const SyncStatusPill({super.key, this.status});

  /// Tests and goldens pass a fixed status; the app watches the repository.
  final Stream<TaskSyncStatus>? status;

  @override
  State<SyncStatusPill> createState() => _SyncStatusPillState();
}

class _SyncStatusPillState extends State<SyncStatusPill> {
  StreamSubscription<TaskSyncStatus>? _sub;
  TaskSyncStatus _status = const TaskSyncStatus();

  @override
  void initState() {
    super.initState();
    final stream =
        widget.status ??
        (getIt.isRegistered<WatchSyncStatus>()
            ? getIt<WatchSyncStatus>()()
            : null);
    _sub = stream?.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final motion = context.motion;
    final offline = !_status.online;
    final visible = offline || _status.pending > 0;
    final label = offline
        ? l10n.syncOffline
        : l10n.syncPending(_status.pending);

    return AnimatedSize(
      duration: motion.duration(KairoSpring.smooth),
      curve: motion.curve(KairoSpring.smooth),
      alignment: Alignment.topLeft,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: offline ? colors.fill : colors.tintSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (offline)
                        Icon(
                          CupertinoIcons.wifi_slash,
                          size: 15,
                          color: colors.labelSecondary,
                        )
                      else
                        CupertinoActivityIndicator(
                          radius: 6,
                          color: colors.tint,
                        ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: context.typography.footnote.copyWith(
                            color: offline
                                ? colors.labelSecondary
                                : colors.tint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

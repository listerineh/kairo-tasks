import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../tasks/presentation/widgets/create_task_sheet.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  Set<String> _sentRequestIds = {};
  Set<String> _friendIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSocialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(_searchController.text.trim());
    });
  }

  Future<void> _loadSocialData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final [friendshipsRaw, pendingRaw] = await Future.wait([
        Supabase.instance.client
            .from('friendships')
            .select(
                'id, status, requester_id, addressee_id, requester_color, addressee_color, created_at')
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .eq('status', 'accepted'),
        Supabase.instance.client
            .from('friendships')
            .select('id, status, requester_id, addressee_id, created_at')
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .eq('status', 'pending'),
      ]);

      final friendships =
          (friendshipsRaw as List).cast<Map<String, dynamic>>();
      final allPending = (pendingRaw as List).cast<Map<String, dynamic>>();
      final receivedPending = allPending
          .where((p) => p['addressee_id'] == userId)
          .toList();
      final sentPending = allPending
          .where((p) => p['requester_id'] == userId)
          .toList();

      final profileIds = <String>{};
      for (final f in friendships) {
        final otherId = f['requester_id'] == userId
            ? f['addressee_id']
            : f['requester_id'];
        profileIds.add(otherId as String);
      }
      for (final p in receivedPending) {
        profileIds.add(p['requester_id'] as String);
      }
      for (final p in sentPending) {
        profileIds.add(p['addressee_id'] as String);
      }

      final profileMap = <String, Map<String, dynamic>>{};
      if (profileIds.isNotEmpty) {
        final profilesData = await Supabase.instance.client
            .from('profiles')
            .select('id, username, display_name, avatar_url')
            .filter('id', 'in', profileIds.toList());
        for (final p in (profilesData as List).cast<Map<String, dynamic>>()) {
          profileMap[p['id'] as String] = p;
        }
      }

      setState(() {
        _friendIds = friendships.map((f) {
          return f['requester_id'] == userId
              ? f['addressee_id'] as String
              : f['requester_id'] as String;
        }).toSet();
        _sentRequestIds = sentPending
            .map((p) => p['addressee_id'] as String)
            .toSet();
        _friends = friendships.map((f) {
          final isRequester = f['requester_id'] == userId;
          final otherId = isRequester
              ? f['addressee_id'] as String
              : f['requester_id'] as String;
          final color = isRequester
              ? (f['requester_color'] as String? ?? '#6B8FA3')
              : (f['addressee_color'] as String? ?? '#6B8FA3');
          return {
            ...f,
            'profile': profileMap[otherId] ?? <String, dynamic>{},
            'color': color,
            'is_requester': isRequester,
            'friendship_id': f['id'] as String,
          };
        }).toList();
        _pendingRequests = receivedPending.map((p) {
          final requesterId = p['requester_id'] as String;
          return {
            ...p,
            'requester_profile': profileMap[requesterId] ?? <String, dynamic>{},
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Could not load social data: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final results = await Supabase.instance.client
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .ilike('username', '%$query%')
          .neq('id', currentUser.id)
          .limit(20);

      setState(() {
        _searchResults = results.map((profile) {
          final id = profile['id'] as String;
          return {
            ...profile,
            'is_friend': _friendIds.contains(id),
            'is_request_sent': _sentRequestIds.contains(id),
          };
        }).toList();
      });
    } catch (e) {
      setState(() => _searchResults = []);
    }
  }

  Future<void> _sendRequest(String addresseeId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final l10n = context.l10n;
    try {
      await Supabase.instance.client.from('friendships').insert({
        'requester_id': userId,
        'addressee_id': addresseeId,
        'status': 'pending',
      });
      _showSuccess(l10n.friendRequestSent);
      _sentRequestIds.add(addresseeId);
      await _searchUsers(_searchController.text.trim());
      await _loadSocialData();
    } catch (e) {
      _showError('Could not send request');
    }
  }

  Future<void> _respondRequest(String requestId, String status) async {
    final l10n = context.l10n;
    try {
      await Supabase.instance.client
          .from('friendships')
          .update({'status': status})
          .eq('id', requestId);

      _showSuccess(
        status == 'accepted' ? l10n.friendRequestAccepted : l10n.requestDeclined,
      );
      await _loadSocialData();
      await _searchUsers(_searchController.text.trim());
    } catch (e) {
      _showError('Could not respond to request');
    }
  }

  Future<void> _removeFriend(String friendshipId) async {
    final l10n = context.l10n;
    try {
      await Supabase.instance.client
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
      _showSuccess(l10n.friendRemoved);
      await _loadSocialData();
      await _searchUsers(_searchController.text.trim());
    } catch (e) {
      _showError('Could not remove friend');
    }
  }

  Future<void> _updateFriendColor(
    String friendshipId,
    String color, {
    required bool isRequester,
  }) async {
    try {
      await Supabase.instance.client
          .from('friendships')
          .update({
            if (isRequester) 'requester_color': color,
            if (!isRequester) 'addressee_color': color,
          })
          .eq('id', friendshipId);
      _showSuccess('Color saved');
      await _loadSocialData();
    } catch (e) {
      _showError('Could not save color');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openFriendDetail(Map<String, dynamic> friend) async {
    final other = friend['profile'] as Map<String, dynamic>?;
    if (other == null) return;

    final friendId = other['id'] as String?;
    final displayName =
        other['display_name'] as String? ??
        other['username'] as String? ??
        context.l10n.friend;
    final username = other['username'] as String? ?? '';
    final avatarUrl = other['avatar_url'] as String?;
    final color = friend['color'] as String? ?? '#6B8FA3';
    final friendshipId = friend['friendship_id'] as String? ?? '';
    final isRequester = friend['is_requester'] as bool? ?? false;

    final shouldRemove = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FriendDetailSheet(
        displayName: displayName,
        username: username,
        color: color,
        avatarUrl: avatarUrl,
        onColor: (newColor) => _updateFriendColor(
          friendshipId,
          newColor,
          isRequester: isRequester,
        ),
        onCreateTask: () => _showCreateTaskWithFriend(friendId),
      ),
    );

    if (shouldRemove ?? false) {
      await _removeFriend(friendshipId);
    }
  }

  void _showCreateTaskWithFriend(String? friendId) {
    if (friendId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateTaskSheet(initialSharedWith: friendId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(context.l10n.social),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accent,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.accent,
          indicatorWeight: 3,
          tabs: [
            _Tab(
              icon: Icons.search,
              label: context.l10n.search,
              count: _searchResults.length,
            ),
            _Tab(
              icon: Icons.people,
              label: context.l10n.friends,
              count: _friends.length,
            ),
            _Tab(
              icon: Icons.mail,
              label: context.l10n.requests,
              count: _pendingRequests.length,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SearchTab(
                  controller: _searchController,
                  results: _searchResults,
                  onAdd: _sendRequest,
                ),
                _FriendsTab(
                  friends: _friends,
                  colors: colors,
                  onOpen: _openFriendDetail,
                ),
                _RequestsTab(
                  requests: _pendingRequests,
                  onAccept: _respondRequest,
                  onDecline: _respondRequest,
                  colors: colors,
                ),
              ],
            ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.urgent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.controller,
    required this.results,
    required this.onAdd,
  });

  final TextEditingController controller;
  final List<Map<String, dynamic>> results;
  final void Function(String) onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.spacing16),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.spacing16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            results.isEmpty ? context.l10n.searchEmpty : context.l10n.searchResults,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Expanded(
            child: results.isEmpty
                ? _EmptySearchState(colors: colors)
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final user = results[index];
                      final isFriend = (user['is_friend'] as bool?) ?? false;
                      final isRequestSent =
                          (user['is_request_sent'] as bool?) ?? false;

                      return _UserListTile(
                        profile: user,
                        trailing: isFriend
                            ? _StatusChip(
                                icon: Icons.check,
                                label: context.l10n.friends,
                                color: colors.accent,
                              )
                            : isRequestSent
                                ? _StatusChip(
                                    icon: Icons.hourglass_empty,
                                    label: context.l10n.pending,
                                    color: colors.textMuted,
                                  )
                                : _IconActionButton(
                                    icon: Icons.person_add,
                                    tooltip: context.l10n.sendFriendRequest,
                                    onPressed: () => onAdd(user['id'] as String),
                                  ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({
    required this.friends,
    required this.colors,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> friends;
  final AppColorScheme colors;
  final void Function(Map<String, dynamic> friend) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      child: friends.isEmpty
          ? _EmptyState(
              icon: Icons.people_outline,
              title: context.l10n.noFriendsTitle,
              subtitle: context.l10n.noFriendsSubtitle,
              colors: colors,
            )
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];

                return _UserListTile(
                  profile: (friend['profile'] as Map<String, dynamic>?) ?? {},
                  onTap: () => onOpen(friend),
                );
              },
            ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.requests,
    required this.onAccept,
    required this.onDecline,
    required this.colors,
  });

  final List<Map<String, dynamic>> requests;
  final void Function(String, String) onAccept;
  final void Function(String, String) onDecline;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      child: requests.isEmpty
          ? _EmptyState(
              icon: Icons.mail_outline,
              title: context.l10n.noPendingRequestsTitle,
              subtitle: context.l10n.noPendingRequestsSubtitle,
              colors: colors,
            )
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final requester =
                    request['requester_profile'] as Map<String, dynamic>?;

                return _UserListTile(
                  profile: requester ?? {},
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconActionButton(
                        icon: Icons.check,
                        backgroundColor: colors.accent,
                        iconColor: Colors.white,
                        onPressed: () => onAccept(
                          request['id'] as String,
                          'accepted',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing8),
                      _IconActionButton(
                        icon: Icons.close,
                        backgroundColor: colors.urgent.withValues(alpha: 0.1),
                        iconColor: colors.urgent,
                        onPressed: () => onDecline(
                          request['id'] as String,
                          'rejected',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({
    required this.profile,
    this.trailing,
    this.onTap,
  });

  final Map<String, dynamic> profile;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final displayName = profile['display_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final avatarUrl = profile['avatar_url'] as String?;

    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _UserAvatar(url: avatarUrl, displayName: displayName),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.url, this.displayName});

  final String? url;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CircleAvatar(
      radius: 28,
      backgroundColor: colors.accentSoft,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? Text(
              (displayName ?? '?')[0].toUpperCase(),
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.accent,
              ),
            )
          : null,
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final button = Material(
      color: backgroundColor ?? colors.accentSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor ?? colors.accent,
            size: 20,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

class _FriendDetailSheet extends StatelessWidget {
  const _FriendDetailSheet({
    required this.displayName,
    required this.username,
    required this.color,
    required this.onColor,
    required this.onCreateTask,
    this.avatarUrl,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;
  final String color;
  final void Function(String) onColor;
  final VoidCallback onCreateTask;

  static const _palette = [
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              CircleAvatar(
                radius: 48,
                backgroundColor: colors.accentSoft,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: context.textTheme.displaySmall?.copyWith(
                          color: colors.accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Text(
                displayName,
                style: context.textTheme.titleLarge,
              ),
              Text(
                '@$username',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Text(
                context.l10n.friendColor,
                style: context.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.spacing12),
              Wrap(
                spacing: AppSpacing.spacing12,
                runSpacing: AppSpacing.spacing12,
                alignment: WrapAlignment.center,
                children: _palette.map((hex) {
                  final selected = hex == color;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onColor(hex);
                    },
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
              const SizedBox(height: AppSpacing.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCreateTask();
                  },
                  icon: const Icon(Icons.add_task),
                  label: Text(context.l10n.createTaskTogether),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.delete),
                  label: Text(context.l10n.removeFriend),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.urgent,
                    side: BorderSide(color: colors.urgent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
            ],
          ),
        ),
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.colors});

  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: colors.textMuted),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            context.l10n.searchPrompt,
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colors.textMuted),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            title,
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

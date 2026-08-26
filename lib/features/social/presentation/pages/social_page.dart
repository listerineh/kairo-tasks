import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

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

      final [friends, pending] = await Future.wait([
        Supabase.instance.client
            .from('friendships')
            .select('''
              id,
              status,
              requester_id,
              addressee_id,
              created_at,
              requester:profiles!requester_id(username, display_name, avatar_url),
              addressee:profiles!addressee_id(username, display_name, avatar_url)
            ''')
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .eq('status', 'accepted'),
        Supabase.instance.client
            .from('friendships')
            .select('''
              id,
              status,
              requester_id,
              addressee_id,
              created_at,
              requester:profiles!requester_id(username, display_name, avatar_url)
            ''')
            .eq('addressee_id', userId)
            .eq('status', 'pending'),
      ]);

      setState(() {
        _friends = friends;
        _pendingRequests = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

      final friendsIds = _friends.map((f) {
        return f['requester_id'] == currentUser.id
            ? f['addressee_id']
            : f['requester_id'];
      }).toSet();

      setState(() {
        _searchResults = results.map((profile) {
          return {...profile, 'is_friend': friendsIds.contains(profile['id'])};
        }).toList();
      });
    } catch (e) {
      setState(() => _searchResults = []);
    }
  }

  Future<void> _sendRequest(String addresseeId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('friendships').insert({
        'requester_id': userId,
        'addressee_id': addresseeId,
        'status': 'pending',
      });
      _showSuccess('Friend request sent');
      await _searchUsers(_searchController.text.trim());
      await _loadSocialData();
    } catch (e) {
      _showError('Could not send request');
    }
  }

  Future<void> _respondRequest(String requestId, String status) async {
    try {
      await Supabase.instance.client
          .from('friendships')
          .update({'status': status})
          .eq('id', requestId);

      _showSuccess(
        status == 'accepted' ? 'Friend request accepted' : 'Request declined',
      );
      await _loadSocialData();
      await _searchUsers(_searchController.text.trim());
    } catch (e) {
      _showError('Could not respond to request');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            floating: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 48),
              title: Text(
                'Social',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.accent,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.accent,
              indicatorWeight: 3,
              tabs: [
                _Tab(
                  icon: Icons.search,
                  label: 'Search',
                  count: _searchResults.length,
                ),
                _Tab(
                  icon: Icons.people,
                  label: 'Friends',
                  count: _friends.length,
                ),
                _Tab(
                  icon: Icons.mail,
                  label: 'Requests',
                  count: _pendingRequests.length,
                ),
              ],
            ),
          ),
        ],
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
                  ),
                  _RequestsTab(
                    requests: _pendingRequests,
                    onAccept: _respondRequest,
                    onDecline: _respondRequest,
                    colors: colors,
                  ),
                ],
              ),
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
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
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
                hintText: 'Find someone by username...',
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.spacing16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            results.isEmpty ? 'Start typing to find people' : 'Search results',
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

                      return _UserListTile(
                        profile: user,
                        trailing: isFriend
                            ? _StatusChip(
                                icon: Icons.check,
                                label: 'Friends',
                                color: colors.accent,
                              )
                            : _IconActionButton(
                                icon: Icons.person_add,
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
  });

  final List<Map<String, dynamic>> friends;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      child: friends.isEmpty
          ? _EmptyState(
              icon: Icons.people_outline,
              title: 'No friends yet',
              subtitle: 'Search by username and connect with others',
              colors: colors,
            )
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final other = friend['requester_id'] == currentUserId
                    ? friend['addressee'] as Map<String, dynamic>?
                    : friend['requester'] as Map<String, dynamic>?;

                return _UserListTile(
                  profile: other ?? {},
                  trailing: _IconActionButton(
                    icon: Icons.calendar_today_outlined,
                    onPressed: () {
                      // TODO: open friend's public calendar
                    },
                  ),
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
              title: 'No pending requests',
              subtitle: 'When someone adds you, it will show here',
              colors: colors,
            )
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final requester =
                    request['requester'] as Map<String, dynamic>?;

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
  });

  final Map<String, dynamic> profile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final displayName = profile['display_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final avatarUrl = profile['avatar_url'] as String?;

    return Container(
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
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
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
            'Type a username to discover people',
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

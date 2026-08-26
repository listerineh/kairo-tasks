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

class _SocialPageState extends State<SocialPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadSocialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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
      if (userId == null) return;

      final friends = await Supabase.instance.client
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
          .eq('status', 'accepted');

      final pending = await Supabase.instance.client
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
          .eq('status', 'pending');

      setState(() {
        _friends = friends;
        _pendingRequests = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load social data';
        _isLoading = false;
      });
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

      final friendsIds = _friends.map((f) => f['requester_id'] == currentUser.id
          ? f['addressee_id']
          : f['requester_id']).toSet();

      final withStatus = results.map((profile) {
        final isFriend = friendsIds.contains(profile['id']);
        return {...profile, 'is_friend': isFriend};
      }).toList();

      setState(() => _searchResults = withStatus);
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
      appBar: AppBar(
        title: const Text('Social'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.spacing16),
                  ),
                ),
              ),
            ),

            // Search results
            if (_searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                ),
                child: Text(
                  'Search results',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Expanded(
              child: _buildBody(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppColorScheme colors) {
    if (_searchResults.isNotEmpty) {
      return _SearchResultsList(
        results: _searchResults,
        onAdd: _sendRequest,
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      children: [
        _SectionTitle('Pending requests (${_pendingRequests.length})'),
        if (_pendingRequests.isEmpty)
          _EmptyState('No pending friend requests', colors),
        ..._pendingRequests.map(
          (r) => _RequestCard(
            request: r,
            onAccept: () => _respondRequest(r['id'] as String, 'accepted'),
            onDecline: () => _respondRequest(r['id'] as String, 'rejected'),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing24),
        _SectionTitle('Friends (${_friends.length})'),
        if (_friends.isEmpty)
          _EmptyState('No friends yet', colors),
        ..._friends.map(
          (f) => _FriendCard(friend: f),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: Text(
        text,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.text, this.colors);

  final String text;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
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
      radius: 24,
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

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.onAdd,
  });

  final List<Map<String, dynamic>> results;
  final void Function(String) onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        final isFriend = (user['is_friend'] as bool?) ?? false;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _UserAvatar(
            url: user['avatar_url'] as String?,
            displayName: user['display_name'] as String?,
          ),
          title: Text(user['display_name'] as String? ?? ''),
          subtitle: Text('@${user['username']}'),
          trailing: isFriend
              ? Icon(Icons.check_circle, color: colors.accent)
              : IconButton(
                  icon: Icon(Icons.person_add, color: colors.accent),
                  onPressed: () => onAdd(user['id'] as String),
                ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final requester = request['requester'] as Map<String, dynamic>?;

    return Card(
      color: colors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            _UserAvatar(
              url: requester?['avatar_url'] as String?,
              displayName: requester?['display_name'] as String?,
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requester?['display_name'] as String? ?? '',
                    style: context.textTheme.bodyLarge,
                  ),
                  Text(
                    '@${requester?['username']}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.check, color: colors.accent),
              onPressed: onAccept,
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.urgent),
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final Map<String, dynamic> friend;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isRequester = friend['requester_id'] == currentUserId;
    final other = isRequester
        ? friend['addressee'] as Map<String, dynamic>?
        : friend['requester'] as Map<String, dynamic>?;

    return Card(
      color: colors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
        ),
        leading: _UserAvatar(
          url: other?['avatar_url'] as String?,
          displayName: other?['display_name'] as String?,
        ),
        title: Text(other?['display_name'] as String? ?? ''),
        subtitle: Text('@${other?['username']}'),
      ),
    );
  }
}

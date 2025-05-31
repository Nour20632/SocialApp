import 'package:flutter/material.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/screens/posts/user_posts_screen.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/widgets/usage_timer_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecondHomeScreen extends StatefulWidget {
  const SecondHomeScreen({super.key});

  @override
  State<SecondHomeScreen> createState() => _SecondHomeScreenState();
}

class _SecondHomeScreenState extends State<SecondHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final UserService _userService;
  late final PostService _postService;
  late final String _currentUserId;
  List<UserWithLastPost> _allUsers = [];
  List<UserWithLastPost> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _userService = UserService(client);
    _postService = PostService(client);
    _currentUserId = client.auth.currentUser?.id ?? '';
    _searchController.addListener(_onSearchChanged);
    _fetchFollowers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Defensive: Ensure _userService and _currentUserId are valid
      final userId =
          (_currentUserId.isNotEmpty)
              ? _currentUserId
              : Supabase.instance.client.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        _allUsers = [];
        _filteredUsers = [];
        _hasError = true;
        setState(() => _isLoading = false);
        return;
      }
      List<UserModel> users = await _userService.getFollowing(userId);
      List<UserWithLastPost> usersWithPosts = [];
      for (final user in users) {
        // Defensive: user.id may be null
        if (user.id.isEmpty) continue;
        final lastPost = await _postService.getLastUserPost(user.id);
        usersWithPosts.add(
          UserWithLastPost(
            user: user,
            lastPostDate: lastPost?.createdAt,
            hasNewPost: false,
          ),
        );
      }
      usersWithPosts.sort((a, b) {
        final aDate = a.lastPostDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastPostDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      _allUsers = usersWithPosts;
      _applySearch(_searchQuery);
    } catch (e) {
      _allUsers = [];
      _filteredUsers = [];
      _hasError = true;
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    _applySearch(_searchController.text.trim());
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers =
            _allUsers
                .where(
                  (u) =>
                      u.user.displayName.toLowerCase().contains(lowerQuery) ||
                      u.user.username.toLowerCase().contains(lowerQuery),
                )
                .toList();
      }
    });
  }

  Future<void> _refresh() async {
    await _fetchFollowers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppTheme.seenTheme(context, isArabic: l10n.isArabic);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Theme(
      data: theme,
      child: Directionality(
        textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.appName, style: textTheme.titleLarge),
            centerTitle: true,
            backgroundColor: colorScheme.background,
            elevation: 1,
          ),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        l10n.appName,
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                      semanticLabel: l10n.notifications,
                    ),
                    title: Text(l10n.notifications),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.dashboard_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  // ... يمكنك إضافة عناصر أخرى هنا ...
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: UsageTimerWidget(compact: true)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : (isTablet ? 32 : 12),
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Search bar
                      _buildSearchBar(
                        context,
                        l10n,
                        colorScheme,
                        textTheme,
                        isRtl,
                      ),
                      const SizedBox(height: 12),
                      // Content
                      Expanded(
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _hasError
                                ? _buildErrorState(l10n, colorScheme)
                                : _filteredUsers.isEmpty
                                ? _buildEmptyState(l10n, colorScheme, textTheme)
                                : RefreshIndicator(
                                  onRefresh: _refresh,
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    itemCount: _filteredUsers.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers[index];
                                      return _UserCard(
                                        user: user.user,
                                        lastPostDate: user.lastPostDate,
                                        hasNewPost: user.hasNewPost,
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => UserPostsScreen(
                                                    userId: user.user.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        colorScheme: colorScheme,
                                        textTheme: textTheme,
                                        l10n: l10n,
                                        isRtl: isRtl,
                                      );
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.message_sharp),
                label: l10n.messages,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.book_outlined),
                label: l10n.knowledge,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: l10n.profile,
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home - scroll to top
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                  break;
                case 1:
                  Navigator.pushNamed(context, '/conversations');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/knowledge');
                  break;
                case 3:
                  Navigator.pushNamed(context, '/profile');
                  break;
              }
            },
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
            showUnselectedLabels: true,
            showSelectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isRtl,
  ) {
    return Semantics(
      label: l10n.translate('search'),
      textField: true,
      child: TextField(
        controller: _searchController,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: l10n.translate('search followers'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
        style: textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('noFollowers'),
            style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('noFollowersDescription'),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            l10n.translate('errorLoadingFollowers'),
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.translate('retry')),
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }
}

class UserWithLastPost {
  final UserModel user;
  final DateTime? lastPostDate;
  final bool hasNewPost;
  UserWithLastPost({
    required this.user,
    this.lastPostDate,
    this.hasNewPost = false,
  });
}

/// User card widget with theme, localization, and accessibility
class _UserCard extends StatelessWidget {
  final UserModel user;
  final DateTime? lastPostDate;
  final bool hasNewPost;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final bool isRtl;

  const _UserCard({
    required this.user,
    required this.lastPostDate,
    required this.hasNewPost,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${user.displayName}, ${l10n.translate('lastPost')}: ${_formatDateTime(lastPostDate, l10n)}',
      button: true,
      child: Card(
        elevation: hasNewPost ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Profile image
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary.withOpacity(0.08),
                  backgroundImage:
                      user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                  child:
                      user.profileImageUrl == null
                          ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isRtl
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 4.0,
                              ),
                              child: Icon(
                                Icons.verified,
                                color: colorScheme.secondary,
                                size: 18,
                                semanticLabel: l10n.translate('verified'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastPostDate != null
                            ? '${l10n.translate('lastPost')}: ${_formatDateTime(lastPostDate, l10n)}'
                            : l10n.translate('noPostsYet'),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasNewPost)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.fiber_new,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                // Action: View profile/posts
                IconButton(
                  icon: Icon(
                    isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  tooltip: l10n.translate('viewProfile'),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.translate('noPostsYet');
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) {
      return '${diff.inMinutes} ${l10n.translate('minutesAgo')}';
    }
    if (diff.inDays < 1) return '${diff.inHours} ${l10n.translate('hoursAgo')}';
    return '${diff.inDays} ${l10n.translate('daysAgo')}';
  }
}

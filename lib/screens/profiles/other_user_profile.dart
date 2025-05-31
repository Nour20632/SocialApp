import 'package:flutter/material.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/screens/posts/user_posts_screen.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final UserService userService;
  final PostService postService;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.userService,
    required this.postService,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFollowing = false;
  bool _isPending = false;
  bool _isDeclined = false;

  final Map<String, int> _stats = {'posts': 0, 'followers': 0, 'following': 0};

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkFollowStatus();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final user = await widget.userService.getUserById(widget.userId, context);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == widget.userId) return;
    try {
      final status = await widget.userService.getFollowStatus(
        currentUserId,
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _isFollowing = status['isFollowing'] ?? false;
        _isPending = status['isPending'] ?? false;
        _isDeclined = status['isDeclined'] ?? false;
      });
    } catch (_) {}
  }

  Future<void> _handleFollowUnfollow() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    setState(() => _isLoading = true);
    try {
      if (_isFollowing || _isPending) {
        await widget.userService.unfollowUser(currentUserId, widget.userId);
      } else {
        await widget.userService.followUser(currentUserId, widget.userId);
      }
      await _checkFollowStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('errorFollowAction'),
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await widget.userService.getUserById(
        widget.userId,
        context,
      );

      setState(() {
        _user = userData;
        _stats['posts'] = userData.postCount;
        _stats['followers'] = userData.followerCount;
        _stats['following'] = userData.followingCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load user data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            title: Text(l10n.profile, style: textTheme.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: l10n.translate('moreOptions'),
                onPressed: () {
                  // Future: show more options (block/report)
                },
              ),
            ],
          ),
          body: SafeArea(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError || _user == null
                    ? _buildErrorState(l10n, colorScheme)
                    : _buildProfile(
                      context,
                      l10n,
                      theme,
                      colorScheme,
                      textTheme,
                      isTablet,
                      isDesktop,
                      isRtl,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isTablet,
    bool isDesktop,
    bool isRtl,
  ) {
    final user = _user!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = currentUserId == user.id;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUser();
        await _checkFollowStatus();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : (isTablet ? 32 : 12),
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image and name
            Center(
              child: Column(
                children: [
                  Semantics(
                    label: l10n.translate('profileImage'),
                    child: CircleAvatar(
                      radius: 54,
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
                                style: textTheme.displayLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.displayName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (user.isVerified)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.verified,
                            color: colorScheme.secondary,
                            size: 20,
                            semanticLabel: l10n.translate('verified'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        user.bio!,
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  l10n.translate('posts'),
                  _stats['posts']!,
                  colorScheme,
                  textTheme,
                ),
                _buildStatCard(
                  l10n.translate('followers'),
                  _stats['followers']!,
                  colorScheme,
                  textTheme,
                ),
                _buildStatCard(
                  l10n.translate('following'),
                  _stats['following']!,
                  colorScheme,
                  textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Account type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  user.accountType == 'PRIVATE' ? Icons.lock : Icons.public,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  user.accountType == 'PRIVATE'
                      ? l10n.translate('privateAccount')
                      : l10n.translate('publicAccount'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action buttons
            if (!isOwnProfile)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFollowButton(l10n, colorScheme, textTheme),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.message_outlined),
                    label: Text(l10n.translate('message')),
                    onPressed: () {
                      // Future: open chat
                    },
                  ),
                ],
              ),
            const SizedBox(height: 32),
            // User posts
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.5, // 50% of screen height
              child: UserPostsScreen(userId: widget.userId),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    String label;
    IconData icon;
    Color? buttonColor;
    VoidCallback? onPressed;

    if (_isFollowing) {
      label = l10n.translate('unfollow');
      icon = Icons.check_circle;
      buttonColor = colorScheme.secondary;
      onPressed = _handleFollowUnfollow;
    } else if (_isPending) {
      label = l10n.translate('pending');
      icon = Icons.hourglass_top;
      buttonColor = colorScheme.primary.withOpacity(0.5);
      onPressed = _handleFollowUnfollow;
    } else if (_isDeclined) {
      label = l10n.translate('declined');
      icon = Icons.cancel;
      buttonColor = colorScheme.error;
      onPressed = _handleFollowUnfollow;
    } else {
      label = l10n.translate('follow');
      icon = Icons.person_add_alt_1;
      buttonColor = colorScheme.primary;
      onPressed = _handleFollowUnfollow;
    }

    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      onPressed: _isLoading ? null : onPressed,
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
            l10n.translate('errorLoadingProfile'),
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
            onPressed: () async {
              await _loadUser();
              await _checkFollowStatus();
            },
          ),
        ],
      ),
    );
  }
}

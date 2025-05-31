import 'package:flutter/material.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/screens/profiles/other_user_profile.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  final UserService userService;
  final PostService postService;

  const NotificationScreen({
    super.key,
    required this.userService,
    required this.postService,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
    _markNotificationsAsRead();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final userId = widget.userService.currentUserId;
      if (userId == null) return [];

      final supabase = widget.userService.supabaseClient;
      final data = await supabase
          .from('notifications')
          .select('''
            *,
            actor:actor_id(id, username, display_name, profile_image_url),
            follow:follow_id(*),
            post:post_id(*),
            comment:comment_id(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final userId = widget.userService.currentUserId;
      if (userId == null) return;

      final supabase = widget.userService.supabaseClient;
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      // Don't rethrow here as it's not critical for the UI
    }
  }

  Future<void> _handleFollowRequest(String followId, bool accept) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (accept) {
        await widget.userService.respondToFollowRequest(followId, 'accepted');
      } else {
        await widget.userService.respondToFollowRequest(followId, 'declined');
      }

      if (mounted) {
        setState(() {
          _notificationsFuture = _fetchNotifications();
        });
      }
    } catch (e) {
      debugPrint('Error handling follow request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('errorOccurred'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    if (mounted) {
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
      // Also mark as read when refreshing
      await _markNotificationsAsRead();
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

    return Theme(
      data: theme,
      child: Directionality(
        textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor:
              colorScheme.surface, // Changed from background to surface
          appBar: AppBar(
            title: Text(
              l10n.translate('notifications'),
              style: textTheme.titleLarge,
            ),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent, // Prevents color tinting
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.translate('refresh'),
                onPressed: _refreshNotifications,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : (isTablet ? 32 : 12),
                vertical: 8,
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(l10n, colorScheme);
                  }

                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return _buildEmptyState(l10n, colorScheme, textTheme);
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final actorData = notification['actor'];
                        UserModel? actor;

                        if (actorData != null) {
                          try {
                            actor = UserModel.fromJson(
                              Map<String, dynamic>.from(actorData),
                            );
                          } catch (e) {
                            debugPrint('Error parsing actor data: $e');
                          }
                        }

                        return _NotificationCard(
                          notification: notification,
                          actor: actor,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          l10n: l10n,
                          isLoading: _isLoading,
                          onFollowAction: _handleFollowRequest,
                          onProfileTap: _navigateToProfile,
                          onNotificationTap: _handleNotificationTap,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('noNotifications'),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('noNotificationsDescription'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.translate('errorLoadingNotifications'),
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('retry')),
              onPressed: _refreshNotifications,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(String userId) {
    if (userId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => OtherUserProfileScreen(
              userId: userId,
              userService: widget.userService,
              postService: widget.postService,
            ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final postId = notification['post_id'] as String?;
    final actorId = notification['actor_id'] as String?;

    if (type == null) return;

    switch (type) {
      case 'LIKE':
      case 'COMMENT':
        if (postId != null && postId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/comments',
            arguments: {'postId': postId},
          );
        }
        break;
      case 'NEW_FOLLOWER':
      case 'FOLLOW_ACCEPTED':
        if (actorId != null && actorId.isNotEmpty) {
          _navigateToProfile(actorId);
        }
        break;
      case 'MENTION':
        if (postId != null && postId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/comments',
            arguments: {'postId': postId},
          );
        }
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final UserModel? actor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final bool isLoading;
  final void Function(String followId, bool accept) onFollowAction;
  final void Function(String userId) onProfileTap;
  final void Function(Map<String, dynamic> notification) onNotificationTap;

  const _NotificationCard({
    required this.notification,
    required this.actor,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
    required this.isLoading,
    required this.onFollowAction,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final isRead = notification['read'] as bool? ?? false;
    final followId = notification['follow_id'] as String?;
    final createdAtStr = notification['created_at'] as String?;

    if (createdAtStr == null) {
      return const SizedBox.shrink(); // Skip invalid notifications
    }

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) {
      return const SizedBox.shrink(); // Skip invalid dates
    }

    final (icon, iconColor) = _getNotificationIcon(type);

    return Card(
      elevation: isRead ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      color:
          isRead
              ? colorScheme.surface
              : colorScheme.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: GestureDetector(
          onTap: actor != null ? () => onProfileTap(actor!.id) : null,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.1),
            backgroundImage:
                actor?.profileImageUrl != null &&
                        actor!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(actor!.profileImageUrl!)
                    : null,
            child:
                actor?.profileImageUrl == null ||
                        actor!.profileImageUrl!.isEmpty
                    ? Icon(icon, color: iconColor, size: 20)
                    : null,
          ),
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _getActorDisplayName(),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' ${_getNotificationText(type, l10n)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            timeago.format(createdAt, locale: l10n.isArabic ? 'ar' : 'en'),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        trailing: _buildTrailing(type, followId),
        onTap: () => onNotificationTap(notification),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _getActorDisplayName() {
    if (actor == null) return l10n.translate('user');
    return actor!.displayName.isNotEmpty == true
        ? actor!.displayName
        : actor!.username;
  }

  Widget? _buildTrailing(String type, String? followId) {
    if (type == 'FOLLOW_REQUEST' && followId != null && followId.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.green,
            tooltip: l10n.translate('accept'),
            onPressed: isLoading ? null : () => onFollowAction(followId, true),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            color: Colors.red,
            tooltip: l10n.translate('decline'),
            onPressed: isLoading ? null : () => onFollowAction(followId, false),
          ),
        ],
      );
    }

    if (!notification['read'] as bool? ?? false) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    return null;
  }

  (IconData, Color) _getNotificationIcon(String type) {
    switch (type) {
      case 'LIKE':
        return (Icons.favorite_outline, Colors.red);
      case 'COMMENT':
        return (Icons.comment_outlined, colorScheme.primary);
      case 'FOLLOW_REQUEST':
        return (Icons.person_add_alt_1_outlined, colorScheme.secondary);
      case 'NEW_FOLLOWER':
        return (Icons.person_add_outlined, colorScheme.secondary);
      case 'FOLLOW_ACCEPTED':
        return (Icons.person_outline, Colors.green);
      case 'MENTION':
        return (Icons.alternate_email, colorScheme.primary);
      default:
        return (Icons.notifications_outlined, colorScheme.primary);
    }
  }

  String _getNotificationText(String type, AppLocalizations l10n) {
    switch (type) {
      case 'FOLLOW_REQUEST':
        return l10n.translate('followRequest');
      case 'NEW_FOLLOWER':
        return l10n.translate('started FollowingYou');
      case 'FOLLOW_ACCEPTED':
        return l10n.translate('accepted Your Follow');
      case 'LIKE':
        return l10n.translate('liked Your Post');
      case 'COMMENT':
        return l10n.translate('commented On Your Post');
      case 'MENTION':
        return l10n.translate('mentioned You');
      default:
        return l10n.translate('sent You A Notification');
    }
  }
}

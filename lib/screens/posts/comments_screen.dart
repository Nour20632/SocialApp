import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/comment_model.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/screens/profiles/other_user_profile.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  late PostService _postService;
  PostModel? _post;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _postService = PostService(supabase);
    _currentUser = supabase.auth.currentUser;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        _post = await _postService.getPost(
          widget.postId,
          currentUserId: user.id,
        );
        _comments = await _postService.getComments(widget.postId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('failedToLoadPosts'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    setState(() => _isSubmitting = true);
    try {
      final comment = await _postService.addComment(
        postId: widget.postId,
        userId: currentUser.id,
        content: _commentController.text.trim(),
      );
      setState(() {
        _comments.add(comment);
        _commentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('generalError')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppTheme.seenTheme(context, isArabic: l10n.isArabic);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Theme(
      data: theme,
      child: Directionality(
        textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            title: Text(
              l10n.translate('comment'),
              style: textTheme.titleLarge,
              semanticsLabel: l10n.translate('comment'),
            ),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 1,
          ),
          body: SafeArea(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        if (_post != null)
                          _PostCard(
                            post: _post!,
                            l10n: l10n,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            isTablet: isTablet,
                          ),
                        Expanded(
                          child:
                              _comments.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 48,
                                            color: colorScheme.primary
                                                .withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l10n.translate('noCommentsYet') ??
                                                'No comments yet.',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7),
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    itemCount: _comments.length,
                                    separatorBuilder:
                                        (_, __) => Divider(
                                          height: 1,
                                          color: colorScheme.surfaceVariant,
                                        ),
                                    itemBuilder: (context, index) {
                                      final comment = _comments[index];
                                      return _CommentTile(
                                        comment: comment,
                                        currentUser: _currentUser,
                                        l10n: l10n,
                                        colorScheme: colorScheme,
                                        textTheme: textTheme,
                                        onUserTap: () {
                                          if (comment.user?.id ==
                                              _currentUser?.id) {
                                            Navigator.pushNamed(
                                              context,
                                              '/profile',
                                            );
                                          } else if (comment.user != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => OtherUserProfileScreen(
                                                      userId: comment.user!.id,
                                                      userService: UserService(
                                                        supabase,
                                                      ),
                                                      postService: PostService(
                                                        supabase,
                                                      ),
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        isRtl: isRtl,
                                      );
                                    },
                                  ),
                        ),
                        _CommentInputBar(
                          controller: _commentController,
                          isSubmitting: _isSubmitting,
                          onSubmit: _submitComment,
                          l10n: l10n,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          isRtl: isRtl,
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// --- Post Card Widget ---
class _PostCard extends StatelessWidget {
  final PostModel post;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isTablet;

  const _PostCard({
    required this.post,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 12,
        vertical: 12,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: l10n.translate('profile'),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary,
                backgroundImage:
                    post.author?.profileImageUrl != null
                        ? NetworkImage(post.author!.profileImageUrl!)
                        : null,
                child:
                    post.author?.profileImageUrl == null
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.author?.displayName ?? l10n.translate('unknown'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(post.content, style: textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(post.createdAt, l10n),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations l10n) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}${l10n.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${l10n.hoursAgo}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${l10n.minutesAgo}';
    } else {
      return l10n.justNow;
    }
  }
}

// --- Comment Tile Widget ---
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final User? currentUser;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onUserTap;
  final bool isRtl;

  const _CommentTile({
    required this.comment,
    required this.currentUser,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    required this.onUserTap,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Semantics(
        label: l10n.translate('profile'),
        child: CircleAvatar(
          backgroundColor: colorScheme.primary,
          backgroundImage:
              comment.user?.profileImageUrl != null
                  ? NetworkImage(comment.user!.profileImageUrl!)
                  : null,
          child:
              comment.user?.profileImageUrl == null
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
        ),
      ),
      title: GestureDetector(
        onTap: onUserTap,
        child: Text(
          comment.user?.displayName ?? l10n.translate('unknown'),
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(comment.createdAt, l10n),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      isThreeLine: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 12,
      horizontalTitleGap: 12,
      dense: false,
    );
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations l10n) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}${l10n.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${l10n.hoursAgo}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${l10n.minutesAgo}';
    } else {
      return l10n.justNow;
    }
  }
}

// --- Comment Input Bar Widget ---
class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isRtl;

  const _CommentInputBar({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.translate('addComment') ?? 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                style: textTheme.bodyMedium,
                minLines: 1,
                maxLines: 4,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
            const SizedBox(width: 8),
            isSubmitting
                ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : IconButton(
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  tooltip: l10n.translate('send'),
                  onPressed: onSubmit,
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/utils/app_localizations.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onDelete,
    this.onEdit,
  });

  String _getTimeAgo(BuildContext context, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    final l10n = AppLocalizations.of(context);

    if (difference.inMinutes < 1) {
      return l10n.translate('justNow');
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} ${l10n.translate('minutesAgo')}';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} ${l10n.translate('hoursAgo')}';
    }
    return '${difference.inDays} ${l10n.translate('daysAgo')}';
  }

  void _navigateToProfile(BuildContext context) {
    // التحقق مما إذا كان المستخدم هو نفسه صاحب المنشور
    final bool isCurrentUser = post.authorId == currentUserId;

    if (isCurrentUser) {
      // إذا كان المستخدم الحالي، انتقل إلى صفحة الملف الشخصي الخاصة به
      Navigator.of(context).pushNamed('/profile');
    } else {
      // إذا كان مستخدم آخر، انتقل إلى صفحة الملف الشخصي الخاصة به
      Navigator.of(
        context,
      ).pushNamed('/other_profile', arguments: post.authorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isPostOwner = post.authorId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post header - Instagram style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Username (clickable)
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToProfile(context),
                  child: Text(
                    post.author!.displayName,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Time and options menu
              Row(
                children: [
                  Text(
                    _getTimeAgo(context, post.createdAt),
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // More options menu
                  if (isPostOwner)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.edit ?? 'Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.delete ?? 'Delete'),
                                ],
                              ),
                            ),
                          ],
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.more_horiz,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: () {
                        // خيارات للمستخدمين غير المالكين
                      },
                    ),
                ],
              ),
            ],
          ),
        ),

        // Post media - عرض الوسائط أولاً (مثل Instagram)
        if (post.media != null && post.media!.isNotEmpty)
          _buildMediaContent(context, theme),

        // Post content
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(post.content, style: theme.textTheme.bodyMedium),
          ),

        // Post stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Like count
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount ?? 0}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 15),
              // Comment count
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount ?? 0}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action buttons
        Row(
          children: [
            // Like button
            Expanded(
              child: TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  post.userHasLiked == true
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  color:
                      post.userHasLiked == true
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                label: Text(
                  l10n.like,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color:
                        post.userHasLiked == true
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
            ),
            // Comment button
            Expanded(
              child: TextButton.icon(
                onPressed: onComment,
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                label: Text(
                  l10n.comment,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
            ),
            // Share button
            Expanded(
              child: TextButton.icon(
                onPressed: onShare,
                icon: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                label: Text(
                  l10n.share,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Divider - خط فاصل رفيع بين المنشورات
        Divider(
          height: 1,
          thickness: 0.5,
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ],
    );
  }

  // دالة لبناء محتوى الوسائط المتعددة
  Widget _buildMediaContent(BuildContext context, ThemeData theme) {
    // الوسائط فارغة
    if (post.media == null || post.media!.isEmpty) {
      return const SizedBox.shrink();
    }

    // طباعة معلومات تصحيح
    debugPrint('عرض وسائط المنشور. العدد: ${post.media!.length}');

    // صورة واحدة
    if (post.media!.length == 1) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 400),
        width: double.infinity,
        child: Image.network(
          post.media![0].url,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame != null ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('خطأ في تحميل الصورة: $error');
            return Container(
              height: 200,
              color: theme.colorScheme.error.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: theme.colorScheme.error,
                ),
              ),
            );
          },
        ),
      );
    }

    // وسائط متعددة (2-4 صور)
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      width: double.infinity,
      child: _buildMediaGrid(theme),
    );
  }

  // دالة لإنشاء شبكة الصور
  Widget _buildMediaGrid(ThemeData theme) {
    final int mediaCount = post.media!.length;
    final int displayCount = mediaCount > 4 ? 4 : mediaCount;

    // تخطيط الشبكة استنادًا إلى عدد الصور
    if (mediaCount == 2) {
      // صورتان جنبًا إلى جنب
      return Row(
        children: [
          Expanded(child: _buildMediaItem(0, theme)),
          const SizedBox(width: 2),
          Expanded(child: _buildMediaItem(1, theme)),
        ],
      );
    } else if (mediaCount == 3) {
      // 3 صور: واحدة كبيرة على اليمين، واثنتان أصغر على اليسار
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildMediaItem(0, theme)),
                const SizedBox(height: 2),
                Expanded(child: _buildMediaItem(1, theme)),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(flex: 1, child: _buildMediaItem(2, theme)),
        ],
      );
    } else {
      // 4 صور أو أكثر: شبكة من 2×2
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: displayCount,
        itemBuilder: (context, index) {
          // إذا كان هناك أكثر من 4 صور وهذه هي الصورة الرابعة
          if (index == 3 && mediaCount > 4) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaItem(index, theme, fitCover: true),
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${mediaCount - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildMediaItem(index, theme, fitCover: true);
        },
      );
    }
  }

  // دالة مساعدة لبناء عنصر وسائط فردي
  Widget _buildMediaItem(int index, ThemeData theme, {bool fitCover = false}) {
    if (index >= post.media!.length) {
      return Container(color: theme.colorScheme.surface);
    }

    return Image.network(
      post.media![index].url,
      fit: fitCover ? BoxFit.cover : BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame != null ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('خطأ في تحميل الصورة: $error');
        return Container(
          color: theme.colorScheme.error.withOpacity(0.1),
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.error,
            ),
          ),
        );
      },
    );
  }
}

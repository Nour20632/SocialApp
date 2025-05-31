import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/achievement_model.dart';

class AchievementCard extends StatelessWidget {
  final AchievementModel? achievement;
  final bool isCreateCard;
  final Function()? onTap;
  final String? title;
  final ThemeData theme;

  const AchievementCard({
    super.key,
    this.achievement,
    this.isCreateCard = false,
    this.onTap,
    this.title,
    required this.theme,
  }) : assert(isCreateCard == true || achievement != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color:
              isCreateCard
                  ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            isCreateCard ? _buildCreateCard() : _buildAchievementCard(context),
      ),
    );
  }

  Widget _buildCreateCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title ?? 'Share Achievement',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background
          if (achievement!.imageUrl != null)
            GestureDetector(
              onTap: () {
                if (achievement!.imageUrl != null) {
                  showDialog(
                    context: context,
                    builder:
                        (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: InteractiveViewer(
                            child: Image.network(achievement!.imageUrl!),
                          ),
                        ),
                  );
                }
              },
              child: CachedNetworkImage(
                imageUrl: achievement!.imageUrl!,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) =>
                        Container(color: theme.colorScheme.surfaceVariant),
                errorWidget:
                    (context, url, error) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: _getTypeColor(achievement!.type).withOpacity(0.3),
              ),
            ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon and celebrations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          achievement!.type,
                        ).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AchievementModel.getTypeIcon(achievement!.type),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (achievement!.celebrationCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.celebration_outlined,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${achievement!.celebrationCount}',
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // User info
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                        image:
                            achievement!.user.profileImageUrl != null
                                ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    achievement!.user.profileImageUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          achievement!.user.profileImageUrl == null
                              ? Center(
                                child: Text(
                                  achievement!.user.displayName[0]
                                      .toUpperCase(),
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        achievement!.user.displayName,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Achievement title
                Text(
                  achievement!.title,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (achievement!.expiryDate != null && !achievement!.isExpired)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatRemainingTime(achievement!.remainingTime!),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inHours > 1) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Color _getTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.islamic:
        return Colors.green;
      case AchievementType.personal:
        return Colors.purple;
      case AchievementType.professional:
        return Colors.black;
      case AchievementType.fitness:
        return Colors.blue;
      case AchievementType.education:
        return Colors.amber;
      case AchievementType.creative:
        return Colors.orange;
      case AchievementType.other:
        return Colors.teal;
    }
  }
}

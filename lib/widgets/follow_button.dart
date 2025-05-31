import 'package:flutter/material.dart';
import 'package:social_app/utils/app_localizations.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final bool isLoading;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onFollow,
    required this.onUnfollow,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor:
              isFollowing
                  ? theme.colorScheme.surface
                  : theme.colorScheme.primary,
          side:
              isFollowing
                  ? BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  )
                  : null,
        ),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isFollowing
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }

    return isFollowing
        ? OutlinedButton(
          onPressed: onUnfollow,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(l10n.translate('following')),
        )
        : ElevatedButton(
          onPressed: onFollow,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(l10n.translate('follow')),
        );
  }
}

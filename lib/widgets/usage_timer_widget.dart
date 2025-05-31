import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/usage_tracker_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';

/// UsageTimerWidget displays the user's daily usage progress in a modern, accessible, and responsive way.
/// It uses the app's design system, localization, and adapts to all screen sizes.
class UsageTimerWidget extends StatelessWidget {
  final bool compact;
  const UsageTimerWidget({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppTheme.seenTheme(context, isArabic: l10n.isArabic);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    // Responsive sizing
    final double iconSize =
        isDesktop
            ? 28
            : isTablet
            ? 22
            : (compact ? 18 : 22);
    final double fontSize =
        isDesktop
            ? 18
            : isTablet
            ? 15
            : (compact ? 13 : 16);
    final double progressWidth =
        isDesktop
            ? 120
            : isTablet
            ? 90
            : (compact ? 60 : 90);

    return Consumer<UnifiedUsageTrackerService>(
      builder: (context, usageService, child) {
        final totalSeconds = usageService.totalUsageSeconds;
        final remainingSeconds = usageService.remainingTimeSeconds;
        final maxSeconds = totalSeconds + remainingSeconds;
        final progress = maxSeconds > 0 ? totalSeconds / maxSeconds : 0.0;
        final isLimitReached = usageService.isLimitReached;

        // Localized label
        final timerLabel =
            isLimitReached
                ? l10n.translate('limitReached')
                : '${l10n.translate('remainingTime')}: ${usageService.formattedRemainingTime}';

        // Accessibility: semantic label for screen readers
        final semanticLabel =
            isLimitReached
                ? l10n.translate('limitReached')
                : '${l10n.translate('usage_time')} ${usageService.formattedRemainingTime}';

        // Color logic
        Color progressColor;
        if (progress >= 1.0) {
          progressColor = Colors.red;
        } else if (progress >= 0.8) {
          progressColor = Colors.orange;
        } else if (progress >= 0.5) {
          progressColor = Colors.amber;
        } else {
          progressColor = colorScheme.primary;
        }

        return Theme(
          data: theme,
          child: Directionality(
            textDirection:
                l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Semantics(
              label: semanticLabel,
              value: usageService.formattedRemainingTime,
              child: AnimatedOpacity(
                opacity: isLimitReached ? 0.6 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isDesktop
                            ? 24
                            : isTablet
                            ? 16
                            : 12,
                    vertical: compact ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isLimitReached
                            ? Colors.red.shade50
                            : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isLimitReached
                              ? Colors.red.shade300
                              : colorScheme.primary.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color:
                            isLimitReached ? Colors.red : colorScheme.primary,
                        size: iconSize,
                        semanticLabel: l10n.translate('usage_time'),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          timerLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            color:
                                isLimitReached
                                    ? Colors.red
                                    : colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isLimitReached) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: progressWidth,
                          height: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: colorScheme.background
                                  .withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                              semanticsLabel: l10n.translate('usage_time'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

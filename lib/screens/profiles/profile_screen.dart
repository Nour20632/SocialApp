import 'package:flutter/material.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/screens/posts/user_posts_screen.dart';
import 'package:social_app/screens/profiles/edit_profile_screen.dart';
import 'package:social_app/services/achievement_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _hasError = false;
  late AchievementService _achievementService;
  List<AchievementModel> _achievements = [];
  bool _isLoadingAchievements = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _achievementService = AchievementService(Supabase.instance.client);
    _loadAchievements();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final user = await UserService(
        Supabase.instance.client,
      ).getUserById(widget.userId, context);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoadingAchievements = true);
    try {
      final achievements = await _achievementService.getUserAchievements(
        widget.userId,
        context,
      );
      if (mounted) {
        setState(() {
          _achievements = achievements;
        });
      }
    } catch (e) {
      // يمكنك عرض رسالة خطأ إذا أردت
    } finally {
      if (mounted) setState(() => _isLoadingAchievements = false);
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
                icon: const Icon(Icons.refresh),
                onPressed: _loadUser,
                tooltip: l10n.translate('refreshProfile'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
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
                // --- قسم عرض الإنجازات ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: _buildAchievementsSection(context),
                ),
              ],
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
    return RefreshIndicator(
      onRefresh: _loadUser,
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
                  user.postCount,
                  colorScheme,
                  textTheme,
                ),
                _buildStatCard(
                  l10n.translate('followers'),
                  user.followerCount,
                  colorScheme,
                  textTheme,
                ),
                _buildStatCard(
                  l10n.translate('following'),
                  user.followingCount,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.editProfile),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditProfileScreen(userId: widget.userId),
                      ),
                    );
                    if (updated == true) _loadUser();
                  },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: Text(l10n.settings),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // User posts
            Align(
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400, // Set a finite height for the posts list
              child: UserPostsScreen(userId: user.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingAchievements) {
      return Center(child: CircularProgressIndicator());
    }
    if (_achievements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.achievements,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noAchievementsYet,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.achievements, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _achievements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(achievement.title),
                subtitle: Text(achievement.description ?? ''),
                trailing:
                    achievement.achievedDate != null
                        ? Text(
                          '${achievement.achievedDate.year}/${achievement.achievedDate.month}/${achievement.achievedDate.day}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                        : null,
              ),
            );
          },
        ),
      ],
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
            onPressed: _loadUser,
          ),
        ],
      ),
    );
  }
}

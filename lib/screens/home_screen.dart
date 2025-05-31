import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:social_app/bloc/home_bloc.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/screens/achievements/achievement_screen.dart';
import 'package:social_app/screens/posts/edit_post_screen.dart';
import 'package:social_app/services/achievement_service.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/utils/app_settings.dart';
import 'package:social_app/widgets/connectivity_banner.dart';
import 'package:social_app/widgets/post_card.dart';

/// Home screen for the Seen social media application
/// Displays user posts, achievements, and provides navigation to other features
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Core services and controllers
  late HomeBloc _homeBloc;
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late AnimationController _achievementCollapseController;
  late Animation<double> _fabAnimation;
  late Animation<double> _achievementCollapseAnimation;

  // State management
  bool _hasConnection = true;
  bool _isProcessingLike = false;
  bool _showAchievements = true;
  Timer? _connectivityTimer;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeBloc();
    _setupConnectivityMonitoring();
    _hideSystemUI();

    // Load data after widget is built to avoid build-time async operations
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  /// Hide system UI elements (status bar, navigation bar)
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // Alternative approach for hiding only status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Initialize all animation controllers and scroll listeners
  void _initializeControllers() {
    _scrollController = ScrollController()..addListener(_handleScrollEvent);

    // FAB animation with smooth curves
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Achievement section collapse animation
    _achievementCollapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _achievementCollapseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _achievementCollapseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fabAnimationController.forward();
    _achievementCollapseController.forward();
  }

  /// Initialize the HomeBloc with required services
  void _initializeBloc() {
    _homeBloc = HomeBloc(
      postService: PostService(supabase),
      userService: UserService(supabase),
      achievementService: AchievementService(supabase),
    );
  }

  /// Setup connectivity monitoring for offline/online states
  void _setupConnectivityMonitoring() {
    // Simulate connectivity check - replace with actual connectivity package
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Load initial data with proper error handling
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      await _homeBloc.loadInitialData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context).errorLoadingData);
      }
    }
  }

  /// Handle refresh with loading state management
  Future<void> _handleRefresh() async {
    if (!mounted) return;

    try {
      await _homeBloc.refreshData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context).errorRefreshingData);
      }
    }
  }

  /// Handle scroll events for infinite loading and FAB visibility
  void _handleScrollEvent() {
    // Infinite scroll loading
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_homeBloc.isLoadingMore &&
        _hasConnection) {
      _homeBloc.loadMorePosts();
    }

    // FAB visibility based on scroll direction
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_fabAnimationController.isCompleted) {
        _fabAnimationController.reverse();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (_fabAnimationController.isDismissed) {
        _fabAnimationController.forward();
      }
    }
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    // Implement actual connectivity check here
    // For now, assume connected
    if (mounted && !_hasConnection) {
      setState(() => _hasConnection = true);
    }
  }

  /// Toggle achievements section visibility
  void _toggleAchievementsVisibility() {
    setState(() => _showAchievements = !_showAchievements);

    if (_showAchievements) {
      _achievementCollapseController.forward();
    } else {
      _achievementCollapseController.reverse();
    }
  }

  /// Handle post like/unlike with debouncing
  void _handlePostLike(String postId) {
    if (_isProcessingLike) return;

    setState(() => _isProcessingLike = true);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        await _homeBloc.toggleLikePost(postId);
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(AppLocalizations.of(context).errorLikingPost);
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingLike = false);
        }
      }
    });
  }

  /// Navigate to comments screen
  void _navigateToComments(String postId) {
    Navigator.of(context)
        .pushNamed('/comments', arguments: {'postId': postId})
        .then((_) => _homeBloc.refreshData());
  }

  /// Handle post sharing
  void _sharePost(PostModel post) {
    // Implement actual sharing logic here
    _showInfoSnackBar(AppLocalizations.of(context).comingSoon);
  }

  /// Delete post with confirmation dialog
  Future<void> _deletePost(String postId) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(l10n.confirmDelete),
            content: Text(l10n.confirmDeletePostMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _homeBloc.deletePost(postId);
        if (mounted) {
          _showSuccessSnackBar(l10n.postDeleted);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(l10n.errorDeletingPost);
        }
      }
    }
  }

  /// Navigate to edit post screen
  Future<void> _editPost(PostModel post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPostScreen(post: post)),
    );

    if (result == true && mounted) {
      _homeBloc.refreshData();
    }
  }

  /// Show error snackbar with consistent styling
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success snackbar with consistent styling
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar with consistent styling
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show bottom sheet for create options
  void _showCreateOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(l10n.shareYourAchievement),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create_achievement');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.createPost),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create_post');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _fabAnimationController.dispose();
    _achievementCollapseController.dispose();
    _scrollController.removeListener(_handleScrollEvent);
    _scrollController.dispose();
    _homeBloc.dispose();

    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final appSettings = Provider.of<AppSettings>(context);
    final theme = AppTheme.seenTheme(context, isArabic: appSettings.isArabic);
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > mobileBreakpoint;
    final isDesktop = screenSize.width > tabletBreakpoint;

    return Theme(
      data: theme,
      child: StreamBuilder<HomeState>(
        stream: _homeBloc.stateStream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? HomeState.initial();

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            // Remove the extendBodyBehindAppBar and use a custom app bar
            body: SafeArea(
              top: false, // Allow content to go behind status bar
              child: Column(
                children: [
                  // Custom app bar that replaces the default one
                  _buildCustomAppBar(theme, l10n, isTablet),

                  // Connectivity banner for offline state
                  if (!_hasConnection)
                    ConnectivityBanner(
                      message: l10n.noInternetConnection,
                      color: theme.colorScheme.error,
                    ),

                  // Main content area
                  Expanded(
                    child: _buildMainContent(
                      state,
                      theme,
                      l10n,
                      appSettings.isArabic,
                      isTablet,
                      isDesktop,
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              l10n,
              theme,
              appSettings.isArabic,
            ),
            floatingActionButton: _buildFloatingActionButton(theme, l10n),
          );
        },
      ),
    );
  }

  /// Build custom app bar with proper spacing and no system UI overlap
  Widget _buildCustomAppBar(
    ThemeData theme,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    return Container(
      // Add top padding to avoid status bar overlap
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App title
          Text(
            l10n.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notifications button
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: theme.colorScheme.primary,
                  semanticLabel: l10n.notifications,
                ),
                tooltip: l10n.notifications,
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),

              IconButton(
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Dashboard',
                onPressed:
                    () =>
                        Navigator.pushReplacementNamed(context, '/second_home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build main content with responsive layout and better spacing
  Widget _buildMainContent(
    HomeState state,
    ThemeData theme,
    AppLocalizations l10n,
    bool isArabic,
    bool isTablet,
    bool isDesktop,
  ) {
    if (state.isLoading && state.posts.isEmpty) {
      return _buildLoadingState(theme, isTablet);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.background,
      displacement: 40,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Add some top spacing
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Achievements section with better spacing
          _buildAchievementsSection(state, theme, l10n, isArabic, isTablet),

          // Content divider with proper spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Posts feed with improved layout
          _buildPostsFeed(state, theme, l10n, isTablet, isDesktop),

          // Bottom spacing for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  /// Build responsive achievements section with improved layout
  Widget _buildAchievementsSection(
    HomeState state,
    ThemeData theme,
    AppLocalizations l10n,
    bool isArabic,
    bool isTablet,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8), // Reduced margin
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height:
              _showAchievements ? (isTablet ? 120 : 120) : 50, // Reduced height
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12), // Smaller border radius
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              // Simplified toggle button without title
              _buildAchievementToggleButton(theme),

              // Achievements content without header
              if (_showAchievements)
                Expanded(
                  child: FadeTransition(
                    opacity: _achievementCollapseAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        8,
                      ), // Reduced padding
                      child: _buildAchievementsList(
                        state,
                        theme,
                        l10n,
                        isArabic,
                        isTablet,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build achievement toggle button with better styling (no title)
  Widget _buildAchievementToggleButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 40, // Reduced height
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleAchievementsVisibility,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ), // Reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centered
              children: [
                AnimatedRotation(
                  turns: _showAchievements ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                    size: 20, // Smaller icon
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build achievements list with improved spacing and layout (no create card)
  Widget _buildAchievementsList(
    HomeState state,
    ThemeData theme,
    AppLocalizations l10n,
    bool isArabic,
    bool isTablet,
  ) {
    if (state.isLoadingAchievements) {
      return _buildAchievementsLoadingState(theme, isTablet);
    }

    if (state.achievements.isEmpty) {
      return Center(
        child: Text(
          l10n.noAchievementsYet,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    // Larger card dimensions for better display
    final cardWidth = isTablet ? 140.0 : 120.0; // Increased width
    final cardHeight = isTablet ? 80.0 : 70.0; // Maintained height

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2), // Minimal padding
      itemCount: state.achievements.length, // Removed +1 for create card
      itemBuilder: (context, index) {
        final achievement = state.achievements[index];
        return _buildAchievementCard(achievement, theme, cardWidth, cardHeight);
      },
    );
  }

  /// Build individual achievement card with better styling
  Widget _buildAchievementCard(
    dynamic achievement,
    ThemeData theme,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 8), // Reduced margin between cards
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AchievementScreen(achievement: achievement),
                ),
              ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or color
              if (achievement.imageUrl != null)
                Image.network(
                  achievement.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.3,
                        ),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.4),
                        theme.colorScheme.secondaryContainer.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),

              // Subtle gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  ),
                ),
              ),

              // Achievement title
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Text(
                  achievement.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build achievements loading state with better animation
  Widget _buildAchievementsLoadingState(ThemeData theme, bool isTablet) {
    final cardWidth = isTablet ? 140.0 : 120.0; // Increased width
    final cardHeight = isTablet ? 80.0 : 70.0;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: 3, // Reduced skeleton count
      itemBuilder: (context, index) {
        return Container(
          width: cardWidth,
          height: cardHeight,
          margin: const EdgeInsets.only(right: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build posts feed with improved spacing and layout
  Widget _buildPostsFeed(
    HomeState state,
    ThemeData theme,
    AppLocalizations l10n,
    bool isTablet,
    bool isDesktop,
  ) {
    // Calculate responsive padding
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == state.posts.length) {
            return state.isLoadingMore
                ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                )
                : const SizedBox(height: 20);
          }

          final post = state.posts[index];
          return Container(
            margin: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 16,
            ),
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            child: PostCard(
              post: post,
              currentUserId: state.currentUser?.id ?? '',
              onLike: () => _handlePostLike(post.id),
              onComment: () => _navigateToComments(post.id),
              onShare: () => _sharePost(post),
              onDelete:
                  post.authorId == state.currentUser?.id
                      ? () => _deletePost(post.id)
                      : null,
              onEdit:
                  post.authorId == state.currentUser?.id
                      ? () => _editPost(post)
                      : null,
            ),
          );
        },
        childCount: state.posts.length + 1,
        semanticIndexCallback: (widget, localIndex) => localIndex,
      ),
    );
  }

  /// Build loading state with improved skeleton placeholders
  Widget _buildLoadingState(ThemeData theme, bool isTablet) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Top spacing
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Achievements loading with container
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: isTablet ? 160 : 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSkeletonBox(theme, width: 120, height: 20),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSkeletonBox(theme, width: 100, height: 16),
                            _buildSkeletonBox(theme, width: 60, height: 14),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder:
                                (context, index) => Container(
                                  width: isTablet ? 110 : 90,
                                  height: isTablet ? 90 : 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Posts loading
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSkeletonPostCard(theme),
            ),
            childCount: 3,
          ),
        ),
      ],
    );
  }

  /// Build skeleton box for loading states
  Widget _buildSkeletonBox(
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Build skeleton post card for loading state
  Widget _buildSkeletonPostCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonBox(theme, width: 120, height: 16),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(theme, width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkeletonBox(theme, width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonBox(theme, width: double.infinity, height: 12),
          const SizedBox(height: 8),
          _buildSkeletonBox(theme, width: 200, height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSkeletonBox(theme, width: 60, height: 32),
              const SizedBox(width: 16),
              _buildSkeletonBox(theme, width: 80, height: 32),
              const SizedBox(width: 16),
              _buildSkeletonBox(theme, width: 60, height: 32),
            ],
          ),
        ],
      ),
    );
  }

  /// Build bottom navigation bar with improved styling
  Widget _buildBottomNavigationBar(
    AppLocalizations l10n,
    ThemeData theme,
    bool isArabic,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: l10n.search,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.book_outlined),
              activeIcon: const Icon(Icons.menu_book), // Changed to menu_book
              label: l10n.knowledge, // This will be added in AppLocalizations
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.message_outlined),
              activeIcon: const Icon(Icons.message),
              label: l10n.messages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
          currentIndex: 0,
          onTap: (index) {
            // Handle bottom navigation tap
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
                Navigator.pushNamed(context, '/search');
                break;
              case 2:
                Navigator.pushNamed(context, '/knowledge');
                break;
              case 3:
                Navigator.pushNamed(context, '/conversations');
                break;
              case 4:
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          showUnselectedLabels: true,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
        ),
      ),
    );
  }

  /// Build floating action button for creating posts
  Widget _buildFloatingActionButton(ThemeData theme, AppLocalizations l10n) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 6,
        heroTag: "home_fab",
        tooltip: l10n.createPost,
        child: const Icon(Icons.edit, size: 24),
      ),
    );
  }
}

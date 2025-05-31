import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/screens/profiles/other_user_profile.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/widgets/post_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  // تغيير من ConsumerStatefulWidget إلى StatefulWidget
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // تغيير من ConsumerState إلى State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedTab = 0;
  String _lastQuery = '';
  bool _isLoading = false;
  bool _hasError = false;
  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _userResults.clear();
        _postResults.clear();
        _lastQuery = '';
      });
    } else if (query != _lastQuery) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _lastQuery = query;
    });
    try {
      if (_selectedTab == 0) {
        // استخدام Provider.of للحصول على UserService
        final userService = Provider.of<UserService>(context, listen: false);
        final users = await userService.searchUsersWithPublicPosts(query);
        setState(() {
          _userResults = users;
        });
      } else {
        // استخدام Provider.of للحصول على PostService
        final postService = Provider.of<PostService>(context, listen: false);
        final posts = await postService.getPosts(searchQuery: query);
        setState(() {
          _postResults = posts;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (_lastQuery.isNotEmpty) {
      _performSearch(_lastQuery);
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
            elevation: 1,
            backgroundColor: colorScheme.background,
            titleSpacing: 0,
            title: _buildSearchBar(
              context,
              l10n,
              colorScheme,
              textTheme,
              isRtl,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildTabBar(l10n, colorScheme, textTheme),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : (isTablet ? 32 : 8),
                vertical: 8,
              ),
              child: _buildResults(context, l10n, colorScheme, textTheme),
            ),
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
        focusNode: _searchFocusNode,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: l10n.translate('searchHint'),
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
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            tooltip: l10n.translate('clear'),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _userResults.clear();
                _postResults.clear();
                _lastQuery = '';
              });
            },
          ),
        ),
        style: textTheme.bodyMedium,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildTabBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        _buildTabButton(0, l10n.translate('users'), colorScheme, textTheme),
        _buildTabButton(1, l10n.translate('posts'), colorScheme, textTheme),
      ],
    );
  }

  Widget _buildTabButton(
    int index,
    String text,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabChanged(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyPrompt(l10n, colorScheme, textTheme);
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return _buildErrorState(l10n, colorScheme);
    }
    if (_selectedTab == 0) {
      if (_userResults.isEmpty) {
        return _buildNoResultsState(l10n, colorScheme, textTheme);
      }
      return ListView.separated(
        itemCount: _userResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _userResults[index];
          return _UserListItem(
            user: user,
            colorScheme: colorScheme,
            textTheme: textTheme,
            l10n: l10n,
            isRtl: Directionality.of(context) == TextDirection.rtl,
          );
        },
      );
    } else {
      if (_postResults.isEmpty) {
        return _buildNoResultsState(l10n, colorScheme, textTheme);
      }
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
      return ListView.separated(
        itemCount: _postResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _postResults[index];
          return PostCard(
            post: post,
            currentUserId: currentUserId,
            onLike: () async {
              try {
                final postService = Provider.of<PostService>(
                  context,
                  listen: false,
                );
                await postService.likePost(post.id, currentUserId);
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('failedToLike')),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            onComment: () {
              Navigator.pushNamed(
                context,
                '/comments',
                arguments: {'postId': post.id},
              );
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('shareComingSoon')),
                  backgroundColor: colorScheme.primary,
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildEmptyPrompt(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('startSearchPrompt'),
            style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('searchHint'),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('noResults'),
            style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
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
            l10n.translate('errorLoadingResults'),
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
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingUsers(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('trendingUsers'),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<UserModel>>(
          future:
              Provider.of<UserService>(
                context,
                listen: false,
              ).getTrendingUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  l10n.translate('errorLoadingTrending'),
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final users = snapshot.data;
            if (users == null || users.isEmpty) {
              return Center(
                child: Text(
                  l10n.translate('noTrendingUsers'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListItem(
                    user: user,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    l10n: l10n,
                    isRtl: Directionality.of(context) == TextDirection.rtl,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserModel user;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final bool isRtl;

  const _UserListItem({
    required this.user,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${user.displayName}, @${user.username}',
      button: true,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final currentUser = Supabase.instance.client.auth.currentUser;
            if (currentUser != null && user.id == currentUser.id) {
              Navigator.pushNamed(context, '/profile');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => OtherUserProfileScreen(
                        userId: user.id,
                        userService: Provider.of<UserService>(
                          context,
                          listen: false,
                        ),
                        postService: Provider.of<PostService>(
                          context,
                          listen: false,
                        ),
                      ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
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
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            user.bio!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (user.isPrivate)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            l10n.translate('privateAccount'),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  tooltip: l10n.translate('viewProfile'),
                  onPressed: () {
                    final currentUser =
                        Supabase.instance.client.auth.currentUser;
                    if (currentUser != null && user.id == currentUser.id) {
                      Navigator.pushNamed(context, '/profile');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OtherUserProfileScreen(
                                userId: user.id,
                                userService: Provider.of<UserService>(
                                  context,
                                  listen: false,
                                ),
                                postService: Provider.of<PostService>(
                                  context,
                                  listen: false,
                                ),
                              ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

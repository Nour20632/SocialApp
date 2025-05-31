import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/widgets/post_card.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final PostService _postService = PostService(supabase);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _posts = [];
  List<String> _domains = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedDomain;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Load knowledge domains
      final domains = await _postService.getKnowledgeDomains();

      // Load initial posts
      final posts = await _postService.getKnowledgePosts(
        knowledgeDomain: _selectedDomain,
        page: 1,
      );

      if (mounted) {
        setState(() {
          _domains = domains;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load knowledge posts');
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    try {
      setState(() => _isLoadingMore = true);

      final newPosts = await _postService.getKnowledgePosts(
        knowledgeDomain: _selectedDomain,
        page: _currentPage + 1,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showError('Failed to load more posts');
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 500) {
      _loadMorePosts();
    }
  }

  Future<void> _handleSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use searchPosts with postType parameter instead of searchKnowledgePosts
      final posts = await _postService.searchPosts(
        query: query,
        postType: 'KNOWLEDGE',
        knowledgeDomain: _selectedDomain,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to search posts');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          appBar: _buildAppBar(l10n, colorScheme, textTheme),
          body: _buildBody(
            colorScheme,
            textTheme,
            l10n,
            isTablet,
            isDesktop,
            isRtl,
          ),
          floatingActionButton: _buildFAB(colorScheme, l10n),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      title: Text(
        l10n.translate('knowledge'),
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: l10n.translate('knowledgeInfo'),
          onPressed: () => _showKnowledgeInfo(l10n),
        ),
      ],
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    bool isTablet,
    bool isDesktop,
    bool isRtl,
  ) {
    final horizontalPadding = isDesktop ? 80.0 : (isTablet ? 40.0 : 16.0);

    return Column(
      children: [
        _buildSearchAndFilters(colorScheme, textTheme, l10n, isRtl),
        Expanded(
          child:
              _isLoading
                  ? _buildLoadingState(colorScheme)
                  : _posts.isEmpty
                  ? _buildEmptyState(textTheme, l10n, colorScheme)
                  : _buildPostsList(
                    horizontalPadding,
                    colorScheme,
                    textTheme,
                    l10n,
                  ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: textTheme.bodyLarge,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: l10n.translate('searchKnowledge'),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
              filled: true,
            ),
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 12),

          // Domain Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDomainChip(
                  null,
                  l10n.translate('allDomains'),
                  colorScheme,
                  textTheme,
                ),
                const SizedBox(width: 8),
                ..._domains.map(
                  (domain) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDomainChip(
                      domain,
                      domain,
                      colorScheme,
                      textTheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainChip(
    String? domain,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = _selectedDomain == domain;

    return FilterChip(
      label: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedDomain = selected ? domain : null;
          _loadInitialData();
        });
      },
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceVariant,
      checkmarkColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
      ),
    );
  }

  Widget _buildEmptyState(
    TextTheme textTheme,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Text(
        l10n.translate('noContentAvailable'),
        style: textTheme.titleMedium?.copyWith(color: colorScheme.onBackground),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPostsList(
    double horizontalPadding,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      itemCount: _posts.length + 1,
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return _isLoadingMore
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
              : const SizedBox.shrink();
        }

        final post = _posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PostCard(
            post: post,
            currentUserId: supabase.auth.currentUser?.id ?? '',
            onLike: () {}, // Implement like functionality
            onComment: () {}, // Implement comment functionality
            onShare: () {}, // Implement share functionality
          ),
        );
      },
    );
  }

  FloatingActionButton _buildFAB(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return FloatingActionButton(
      onPressed:
          () => Navigator.pushNamed(
            context,
            '/create_post',
            arguments: {'defaultType': 'KNOWLEDGE'},
          ),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: l10n.translate('createKnowledgePost'),
      child: const Icon(Icons.add),
    );
  }

  void _showKnowledgeInfo(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('knowledgeInfo')),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(l10n.translate('knowledgeInfoContent')),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('knowledgeDisclaimer'),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('close')),
            ),
          ],
        );
      },
    );
  }
}

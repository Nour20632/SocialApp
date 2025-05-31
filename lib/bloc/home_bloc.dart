import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/achievement_service.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';

class HomeState {
  final UserModel? currentUser;
  final List<PostModel> posts;
  final List<AchievementModel> achievements;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingAchievements;
  final String? error;

  HomeState({
    this.currentUser,
    required this.posts,
    required this.achievements,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isLoadingAchievements,
    this.error,
  });

  factory HomeState.initial() {
    return HomeState(
      currentUser: null,
      posts: [],
      achievements: [],
      isLoading: true,
      isLoadingMore: false,
      isLoadingAchievements: true,
      error: null,
    );
  }

  HomeState copyWith({
    UserModel? currentUser,
    List<PostModel>? posts,
    List<AchievementModel>? achievements,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingAchievements,
    String? error,
  }) {
    return HomeState(
      currentUser: currentUser ?? this.currentUser,
      posts: posts ?? this.posts,
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingAchievements:
          isLoadingAchievements ?? this.isLoadingAchievements,
      error: error ?? this.error,
    );
  }
}

class HomeBloc {
  // Services
  final PostService _postService;
  final UserService _userService;
  final AchievementService _achievementService;

  // State controller
  final _stateController = BehaviorSubject<HomeState>.seeded(
    HomeState.initial(),
  );
  Stream<HomeState> get stateStream => _stateController.stream;
  HomeState get currentState => _stateController.value;

  // Pagination variables
  int _currentPage = 1;
  final int _postsPerPage = 5;

  // Operation tracking
  bool _isApiCallInProgress = false;

  // Getters for convenience
  bool get isLoading => currentState.isLoading;
  bool get isLoadingMore => currentState.isLoadingMore;

  HomeBloc({
    required PostService postService,
    required UserService userService,
    required AchievementService achievementService,
  }) : _postService = postService,
       _userService = userService,
       _achievementService = achievementService;

  Future<void> loadInitialData() async {
    try {
      _stateController.add(currentState.copyWith(isLoading: true));

      // تحميل بيانات المستخدم أولاً
      await _loadUserData();

      // تحميل الإنجازات والمنشورات بشكل متوازي
      await Future.wait([_loadAchievements(), _loadPosts(refresh: true)]);

      _stateController.add(
        currentState.copyWith(isLoading: false, error: null),
      );
    } catch (e) {
      _stateController.add(
        currentState.copyWith(
          isLoading: false,
          error: 'فشل تحميل البيانات: $e',
        ),
      );
    }
  }

  Future<void> refreshData() async {
    if (_isApiCallInProgress) return;

    _stateController.add(currentState.copyWith(isLoading: true));

    await Future.wait([
      _loadUserData(),
      _loadAchievements(),
      _loadPosts(refresh: true),
    ]);
  }

  Future<void> refreshAchievements() async {
    if (_isApiCallInProgress) return;

    _stateController.add(currentState.copyWith(isLoadingAchievements: true));
    await _loadAchievements();
  }

  Future<void> _loadUserData() async {
    if (_isApiCallInProgress) return;
    _isApiCallInProgress = true;

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Change to use getCurrentUser instead since it doesn't require context
        final userData = await _userService.getCurrentUser();

        if (userData == null) {
          // Create a basic user record if it doesn't exist
          await supabase.from('users').insert({
            'id': user.id,
            'username':
                user.userMetadata?['username'] ??
                'user_${user.id.substring(0, 8)}',
            'email': user.email ?? '',
            'display_name': user.userMetadata?['display_name'] ?? 'User',
            'status': 'ACTIVE',
            'is_verified': false,
            'role': 'USER',
            'account_type': 'PUBLIC',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'last_active': DateTime.now().toIso8601String(),
            'follower_count': 0,
            'following_count': 0,
            'post_count': 0,
          });

          // Try to get the user data again
          final newUserData = await _userService.getCurrentUser();
          _stateController.add(currentState.copyWith(currentUser: newUserData));
        } else {
          _stateController.add(currentState.copyWith(currentUser: userData));
        }

        // Update last active time (non-blocking)
        _updateLastActive(user.id);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _stateController.add(
        currentState.copyWith(error: 'Failed to load user data'),
      );
    } finally {
      _isApiCallInProgress = false;
    }
  }

  Future<void> _updateLastActive(String userId) async {
    try {
      await supabase
          .from('users')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating last active time: $e');
      // Non-critical operation, so we don't show an error to the user
    }
  }

  Future<void> _loadAchievements() async {
    if (currentState.currentUser == null) return;

    try {
      _stateController.add(currentState.copyWith(isLoadingAchievements: true));

      final achievements = await _achievementService.getRecentAchievements(10);

      if (!_stateController.isClosed) {
        _stateController.add(
          currentState.copyWith(
            achievements: achievements,
            isLoadingAchievements: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      if (!_stateController.isClosed) {
        _stateController.add(
          currentState.copyWith(
            isLoadingAchievements: false,
            achievements: [], // تفريغ القائمة في حالة الخطأ
            error: 'فشل تحميل الإنجازات',
          ),
        );
      }
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (currentState.currentUser == null) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _stateController.add(currentState.copyWith(isLoading: true, posts: []));
      } else {
        _stateController.add(currentState.copyWith(isLoadingMore: true));
      }

      final posts = await _postService.getFeed(
        currentState.currentUser!.id,
        page: _currentPage,
        limit: _postsPerPage,
      );

      // Process posts to add like status
      final processedPosts = await Future.wait(
        posts.map((post) async {
          final hasLiked = await _postService.hasUserLikedPost(
            post.id,
            currentState.currentUser!.id,
          );

          return PostModel(
            id: post.id,
            authorId: post.authorId,
            typeId: post.typeId,
            content: post.content,
            visibility: post.visibility,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            author: post.author,
            media: post.media,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            userHasLiked: hasLiked,
          );
        }),
      );

      // Update state with new posts
      if (refresh) {
        _stateController.add(
          currentState.copyWith(posts: processedPosts, isLoading: false),
        );
      } else {
        _stateController.add(
          currentState.copyWith(
            posts: [...currentState.posts, ...processedPosts],
            isLoadingMore: false,
          ),
        );
      }

      // Update page counter for pagination
      if (processedPosts.isNotEmpty) {
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      _stateController.add(
        currentState.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: 'Failed to load posts',
        ),
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (_isApiCallInProgress || currentState.isLoadingMore) return;
    _isApiCallInProgress = true;

    try {
      await _loadPosts(refresh: false);
    } finally {
      _isApiCallInProgress = false;
    }
  }

  Future<void> toggleLikePost(String postId) async {
    if (currentState.currentUser == null || _isApiCallInProgress) return;
    _isApiCallInProgress = true;

    try {
      // Find post in the current list
      final postIndex = currentState.posts.indexWhere(
        (post) => post.id == postId,
      );
      if (postIndex == -1) return;

      final post = currentState.posts[postIndex];

      // Toggle like status optimistically for UI responsiveness
      final newPosts = List<PostModel>.from(currentState.posts);
      final bool currentLikeStatus = post.userHasLiked == true;
      final int newLikeCount =
          currentLikeStatus ? (post.likeCount) - 1 : (post.likeCount) + 1;

      newPosts[postIndex] = PostModel(
        id: post.id,
        authorId: post.authorId,
        typeId: post.typeId,
        content: post.content,
        visibility: post.visibility,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        author: post.author,
        media: post.media,
        likeCount: newLikeCount,
        commentCount: post.commentCount,
        userHasLiked: !currentLikeStatus,
      );

      _stateController.add(currentState.copyWith(posts: newPosts));

      // Perform actual API call
      if (currentLikeStatus) {
        await _postService.unlikePost(postId, currentState.currentUser!.id);
      } else {
        await _postService.likePost(postId, currentState.currentUser!.id);
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert to original state by refreshing the feed
      await _loadPosts(refresh: true);
    } finally {
      _isApiCallInProgress = false;
    }
  }

  Future<void> deletePost(String postId) async {
    if (currentState.currentUser == null || _isApiCallInProgress) return;
    _isApiCallInProgress = true;

    try {
      await _postService.deletePost(postId);

      // Update posts list locally by removing the deleted post
      final updatedPosts =
          currentState.posts.where((post) => post.id != postId).toList();
      _stateController.add(currentState.copyWith(posts: updatedPosts));
    } catch (e) {
      debugPrint('Error deleting post: $e');
      _stateController.add(
        currentState.copyWith(error: 'Failed to delete post'),
      );
    } finally {
      _isApiCallInProgress = false;
    }
  }

  void dispose() {
    _stateController.close();
  }
}

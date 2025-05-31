import 'package:flutter/material.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/widgets/post_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPostsScreen extends StatefulWidget {
  final String userId;

  const UserPostsScreen({super.key, required this.userId});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  late final PostService _postService;
  late final UserService _userService;
  List<PostModel> _posts = [];
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _postService = PostService(client);
    _userService = UserService(client);
    _loadUserAndPosts();
  }

  Future<void> _loadUserAndPosts() async {
    try {
      final user = await _userService.getUserById(widget.userId, context);
      final posts = await _postService.getUserPosts(widget.userId);

      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage();
      }
    }
  }

  void _showErrorMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('فشل في تحميل المنشورات')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Material(
      child:
          _posts.isEmpty
              ? Center(
                child: Text(
                  'لا توجد منشورات',
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final bool isOwnPost = post.authorId == currentUserId;

                  return Material(
                    type: MaterialType.transparency,
                    child: PostCard(
                      post: post,
                      currentUserId: currentUserId ?? '',
                      onLike: () async {
                        try {
                          if (post.userHasLiked) {
                            await _postService.unlikePost(
                              post.id,
                              currentUserId ?? '',
                            );
                          } else {
                            await _postService.likePost(
                              post.id,
                              currentUserId ?? '',
                            );
                          }
                          await _loadUserAndPosts();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('errorLikingPost'),
                                ),
                              ),
                            );
                          }
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
                        // Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('comingSoon'),
                            ),
                          ),
                        );
                      },
                      onDelete:
                          isOwnPost
                              ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('confirmDelete'),
                                        ),
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate(
                                            'confirmDeletePostMessage',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).translate('cancel'),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).translate('delete'),
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _postService.deletePost(post.id);
                                    await _loadUserAndPosts();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).translate('postDeleted'),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).translate('errorDeletingPost'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                              : null,
                      onEdit:
                          isOwnPost
                              ? () {
                                Navigator.pushNamed(
                                  context,
                                  '/edit_post',
                                  arguments: post,
                                );
                              }
                              : null,
                    ),
                  );
                },
              ),
    );
  }
}

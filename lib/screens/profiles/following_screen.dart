import 'package:flutter/material.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<UserModel> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final currentContext = context; // Cache context

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final following = await UserService(
        Supabase.instance.client,
      ).getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          _following = following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(SnackBar(content: const Text('فشل في تحميل البيانات')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('المتابَعون'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadFollowing,
                child:
                    _following.isEmpty
                        ? Center(
                          child: Text(
                            'لا يوجد متابَعون حتى الآن',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                        : ListView.builder(
                          itemCount: _following.length,
                          itemBuilder: (context, index) {
                            final user = _following[index];
                            return _UserCard(user: user);
                          },
                        ),
              ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap:
            () => Navigator.pushNamed(
              context,
              '/other_profile',
              arguments: user.id,
            ),
        leading: CircleAvatar(
          radius: 24,
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
                    style: const TextStyle(color: Colors.white),
                  )
                  : null,
        ),
        title: Text(
          user.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('@${user.username}'),
        trailing: _UnfollowButton(userId: user.id),
      ),
    );
  }
}

class _UnfollowButton extends StatelessWidget {
  final String userId;

  const _UnfollowButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == userId) {
      return const SizedBox.shrink();
    }

    return OutlinedButton(
      onPressed: () async {
        try {
          final userService = UserService(Supabase.instance.client);
          await userService.unfollowUser(currentUserId!, userId);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم إلغاء المتابعة')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل في إلغاء المتابعة: $e')));
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.error.withOpacity(0.1),
        foregroundColor: theme.colorScheme.error,
        side: BorderSide(color: theme.colorScheme.error),
      ),
      child: const Text('إلغاء المتابعة'),
    );
  }
}

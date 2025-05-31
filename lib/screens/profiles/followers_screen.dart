import 'package:flutter/material.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  late final UserService _userService;
  List<UserModel> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userService = UserService(Supabase.instance.client);
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    final currentContext = context; // Cache context

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final followers = await _userService.getFollowers(widget.userId);

      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(SnackBar(content: Text('فشل في تحميل البيانات')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('المتابِعون'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadFollowers,
                child:
                    _followers.isEmpty
                        ? Center(
                          child: Text(
                            'لا يوجد متابِعون حتى الآن',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                        : ListView.builder(
                          itemCount: _followers.length,
                          itemBuilder: (context, index) {
                            final user = _followers[index];
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
        trailing: _FollowButton(userId: user.id),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final String userId;

  const _FollowButton({required this.userId});

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
          await userService.followUser(currentUserId!, userId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب المتابعة')),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل في المتابعة: $e')));
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary),
      ),
      child: const Text('متابعة'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:social_app/models/follow_request_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/user_service.dart';

class FollowRequestTile extends StatefulWidget {
  final FollowRequest request;
  final UserModel requester;
  final Function() onRequestHandled;
  final UserService userService;

  const FollowRequestTile({
    super.key,
    required this.request,
    required this.requester,
    required this.onRequestHandled,
    required this.userService,
  });

  @override
  State<FollowRequestTile> createState() => _FollowRequestTileState();
}

class _FollowRequestTileState extends State<FollowRequestTile> {
  bool _isLoading = false;

  Future<void> _handleRequest(BuildContext context, String status) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.userService.respondToFollowRequest(
        widget.request.id,
        status,
      );
      widget.onRequestHandled();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed('/other_profile', arguments: widget.requester.id);
        },
        child: CircleAvatar(
          backgroundImage: NetworkImage(widget.requester.profileImageUrl!),
        ),
      ),
      title: Text(widget.requester.displayName ?? widget.requester.username),
      subtitle: Text('يريد متابعتك'),
      trailing:
          _isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleRequest(context, 'accepted'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleRequest(context, 'declined'),
                  ),
                ],
              ),
    );
  }
}

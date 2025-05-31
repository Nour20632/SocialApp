import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/messaging_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/utils/app_localizations.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _messagingService = MessagingService();
  final _userService = UserService(supabase);
  final _searchController = TextEditingController();
  final _selectedUsers = <UserModel>{};
  bool _isGroup = false;
  bool _isLoading = false;
  String _searchQuery = '';

  Future<void> _createConversation() async {
    if (_selectedUsers.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userIds = _selectedUsers.map((user) => user.id).toList();
      final conversation = await _messagingService.createConversation(
        userIds: userIds,
        isGroup: _isGroup && _selectedUsers.length > 1,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/chat',
          arguments: conversation,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('failedToCreateConversation'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          l10n.translate('newConversation'),
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('searchUsers'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: theme.textTheme.bodyMedium,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundImage:
                            user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                        child:
                            user.profileImageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      label: Text(user.displayName),
                      onDeleted: () {
                        setState(() {
                          _selectedUsers.remove(user);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          if (_selectedUsers.length > 1)
            SwitchListTile(
              title: Text(l10n.translate('groupConversation')),
              value: _isGroup,
              onChanged: (value) {
                setState(() => _isGroup = value);
              },
            ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _userService.searchUsers(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(l10n.translate('errorLoadingUsers')),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return Center(child: Text(l10n.translate('noUsersFound')));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUsers.contains(user);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                        child:
                            user.profileImageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                              : const Icon(Icons.check_circle_outline),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUsers.remove(user);
                          } else {
                            _selectedUsers.add(user);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          _selectedUsers.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _createConversation,
                label:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          _isGroup
                              ? l10n.translate('createGroup')
                              : l10n.translate('startConversation'),
                        ),
                icon: Icon(_isGroup ? Icons.group_add : Icons.chat),
              )
              : null,
    );
  }
}

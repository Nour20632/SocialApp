import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/conversation_model.dart';
import 'package:social_app/services/messaging_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchController = TextEditingController();
  final _messagingService = MessagingService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppTheme.seenTheme(context, isArabic: l10n.isArabic);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Theme(
      data: theme,
      child: Directionality(
        textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            title: Text(
              l10n.translate('conversations'),
              style: textTheme.titleLarge,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.translate('newConversation'),
                onPressed:
                    () => Navigator.pushNamed(context, '/new_conversation'),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('searchConversations'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ConversationModel>>(
                  stream: _messagingService.getConversations(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.translate('errorLoadingConversations'),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {}); // إعادة تحميل
                              },
                              child: Text(l10n.translate('retry')),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allConversations = snapshot.data ?? [];

                    // تطبيق البحث
                    final conversations =
                        _searchQuery.isEmpty
                            ? allConversations
                            : allConversations.where((conversation) {
                              final currentUserId =
                                  supabase.auth.currentUser?.id ?? '';
                              final displayName =
                                  conversation
                                      .getDisplayName(currentUserId)
                                      .toLowerCase();
                              final lastMessage =
                                  conversation.lastMessageContent
                                      ?.toLowerCase() ??
                                  '';
                              return displayName.contains(_searchQuery) ||
                                  lastMessage.contains(_searchQuery);
                            }).toList();

                    if (conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.chat_bubble_outline,
                              size: 64,
                              color: colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? l10n.translate('noSearchResults')
                                  : l10n.translate('noConversations'),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty) ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text(
                                  l10n.translate('startNewConversation'),
                                ),
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/new_conversation',
                                    ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                child: Text(l10n.translate('clearSearch')),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {}); // إعادة تحميل البيانات
                      },
                      child: ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _buildConversationTile(
                            conversation,
                            l10n,
                            colorScheme,
                            textTheme,
                            isRtl,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    ConversationModel conversation,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isRtl,
  ) {
    final currentUserId = supabase.auth.currentUser?.id ?? '';
    final displayName = conversation.getDisplayName(currentUserId);
    final displayImage = conversation.getDisplayImage(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap:
            () =>
                Navigator.pushNamed(context, '/chat', arguments: conversation),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              displayImage != null ? NetworkImage(displayImage) : null,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child:
              displayImage == null
                  ? Icon(
                    conversation.isGroup ? Icons.group : Icons.person,
                    color: colorScheme.primary,
                  )
                  : null,
        ),
        title: Text(
          displayName,
          style: textTheme.titleMedium?.copyWith(
            fontWeight:
                conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            conversation.lastMessageContent != null
                ? Text(
                  conversation.lastMessageContent!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color:
                        conversation.unreadCount > 0
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.7),
                    fontWeight:
                        conversation.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                )
                : Text(
                  l10n.translate('noMessages'),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeago.format(
                conversation.lastMessageAt,
                locale: l10n.isArabic ? 'ar' : 'en',
              ),
              style: textTheme.bodySmall?.copyWith(
                color:
                    conversation.unreadCount > 0
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                fontWeight:
                    conversation.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : '${conversation.unreadCount}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

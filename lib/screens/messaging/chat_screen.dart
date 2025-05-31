import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/conversation_model.dart';
import 'package:social_app/models/message_model.dart';
import 'package:social_app/services/messaging_service.dart';
import 'package:social_app/theme/app_theme.dart';
import 'package:social_app/utils/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messagingService = MessagingService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  List<File> _selectedFiles = [];
  bool _isAttaching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagingService.markAsRead(widget.conversation.id);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedFiles.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        content: message,
        mediaFiles: _selectedFiles,
      );
      _messageController.clear();
      setState(() => _selectedFiles = []);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('failedToSendMessage'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final result = await _imagePicker.pickImage(source: source);
      if (result != null) {
        setState(() {
          _selectedFiles.add(File(result.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('failedToPickMedia'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppTheme.seenTheme(context, isArabic: l10n.isArabic);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    return Theme(
      data: theme,
      child: Directionality(
        textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 1,
            title: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage:
                    widget.conversation.getDisplayImage(currentUserId) != null
                        ? NetworkImage(
                          widget.conversation.getDisplayImage(currentUserId)!,
                        )
                        : null,
                child:
                    widget.conversation.getDisplayImage(currentUserId) == null
                        ? Icon(
                          widget.conversation.isGroup
                              ? Icons.group
                              : Icons.person,
                        )
                        : null,
              ),
              title: Text(
                widget.conversation.getDisplayName(currentUserId),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              if (widget.conversation.isGroup)
                IconButton(
                  icon: const Icon(Icons.group_add),
                  tooltip: l10n.translate('addMembers'),
                  onPressed: () {},
                ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: l10n.translate('moreOptions'),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _messagingService.getMessages(
                      widget.conversation.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(l10n.translate('errorLoadingMessages')),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return FutureBuilder<List<MessageModel>>(
                        future: Future.value(snapshot.data),
                        builder: (context, messagesSnapshot) {
                          if (messagesSnapshot.hasError) {
                            return Center(
                              child: Text(
                                l10n.translate('errorLoadingMessages'),
                              ),
                            );
                          }
                          if (!messagesSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          // عكس الترتيب ليكون الأقدم في الأعلى والأحدث في الأسفل
                          final messages = List<MessageModel>.from(
                            messagesSnapshot.data!,
                          );
                          messages.sort(
                            (a, b) => a.createdAt.compareTo(b.createdAt),
                          );
                          if (messages.isEmpty) {
                            return Center(
                              child: Text(
                                l10n.translate('NO Messages Yet'),
                                style: textTheme.bodyMedium,
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            reverse: false, // لا تعكس الترتيب
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return _buildMessageBubble(
                                message,
                                l10n,
                                colorScheme,
                                textTheme,
                                currentUserId,
                                isRtl,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // Selected media preview
                if (_selectedFiles.isNotEmpty)
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedFiles[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                // Message input
                _buildMessageInput(theme, colorScheme, textTheme, l10n, isRtl),
                // Attachment options
                if (_isAttaching)
                  _buildAttachmentOptions(l10n, colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String currentUserId,
    bool isRtl,
  ) {
    final isMyMessage = message.senderId == currentUserId;
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: message.content,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMyMessage ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMyMessage && widget.conversation.isGroup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.sender?.displayName ?? l10n.translate('user'),
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          isMyMessage
                              ? Colors.white.withOpacity(0.7)
                              : colorScheme.onSurface,
                    ),
                  ),
                ),
              if (message.media.isNotEmpty)
                ...message.media.map((media) => _buildMediaPreview(media)),
              if (message.content.isNotEmpty)
                Text(
                  message.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isMyMessage ? Colors.white : colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(MessageMediaModel media) {
    switch (media.type) {
      case 'IMAGE':
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(media.url, fit: BoxFit.cover),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessageInput(
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: l10n.translate('attach'),
            onPressed: () {
              setState(() => _isAttaching = !_isAttaching);
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: l10n.translate('writeMessage'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              style: textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon:
                _isSending
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(Icons.send, color: colorScheme.primary),
            tooltip: l10n.translate('send'),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: l10n.translate('gallery'),
            onTap: () => _pickMedia(ImageSource.gallery),
            color: colorScheme.primary,
          ),
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: l10n.translate('camera'),
            onTap: () => _pickMedia(ImageSource.camera),
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

import 'user_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final UserModel? sender;
  final String content;
  final bool encrypted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final bool isDeleted;
  final String? replyToId;
  final MessageModel? replyTo;
  final List<MessageMediaModel> media;
  
  // حقل غير مخزن لتحديد ما إذا كانت الرسالة مرسلة من المستخدم الحالي
  final bool isFromCurrentUser;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.content,
    required this.encrypted,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
    required this.isDeleted,
    this.replyToId,
    this.replyTo,
    this.media = const [],
    this.isFromCurrentUser = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {
    UserModel? sender,
    MessageModel? replyTo,
    List<MessageMediaModel>? media,
    String? currentUserId,
  }) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      sender: sender ?? (json['sender'] != null ? UserModel.fromJson(json['sender']) : null),
      content: json['content'] ?? '',
      encrypted: json['encrypted'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isRead: json['is_read'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      replyToId: json['reply_to_id'],
      replyTo: replyTo ?? (json['reply_to'] != null ? MessageModel.fromJson(json['reply_to']) : null),
      media: media ?? [],
      isFromCurrentUser: currentUserId != null && json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'encrypted': encrypted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_read': isRead,
      'is_deleted': isDeleted,
      'reply_to_id': replyToId,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    UserModel? sender,
    String? content,
    bool? encrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isDeleted,
    String? replyToId,
    MessageModel? replyTo,
    List<MessageMediaModel>? media,
    bool? isFromCurrentUser,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      encrypted: encrypted ?? this.encrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      media: media ?? this.media,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MessageModel(id: $id, senderId: $senderId, content: $content)';
}

class MessageMediaModel {
  final String id;
  final String messageId;
  final String url;
  final String type; // IMAGE, VIDEO, AUDIO, DOCUMENT
  final String? storagePath;
  final DateTime createdAt;

  MessageMediaModel({
    required this.id,
    required this.messageId,
    required this.url,
    required this.type,
    this.storagePath,
    required this.createdAt,
  });

  factory MessageMediaModel.fromJson(Map<String, dynamic> json) {
    return MessageMediaModel(
      id: json['id'],
      messageId: json['message_id'],
      url: json['url'],
      type: json['type'],
      storagePath: json['storage_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'url': url,
      'type': type,
      'storage_path': storagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage => type == 'IMAGE';
  bool get isVideo => type == 'VIDEO';
  bool get isAudio => type == 'AUDIO';
  bool get isDocument => type == 'DOCUMENT';
}

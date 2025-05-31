import 'user_model.dart';

class ConversationModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImageUrl;
  final String createdById;
  final List<ConversationMemberModel> members;
  final String? lastMessageContent;
  final UserModel? lastMessageSender;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    required this.isGroup,
    this.groupName,
    this.groupImageUrl,
    required this.createdById,
    required this.members,
    this.lastMessageContent,
    this.lastMessageSender,
    this.unreadCount = 0,
  });

  // للمحادثات الفردية، نحدد الطرف الآخر
  UserModel? getOtherUser(String currentUserId) {
    if (isGroup) return null;
    
    final otherMembers = members
        .where((m) => m.user.id != currentUserId)
        .map((m) => m.user)
        .toList();
    
    return otherMembers.isNotEmpty ? otherMembers.first : null;
  }

  // للمحادثات الفردية، نحصل على اسم المستخدم الآخر
  String getDisplayName(String currentUserId) {
    if (isGroup) return groupName ?? 'محادثة جماعية';
    
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.displayName ?? 'مستخدم';
  }

  // للمحادثات الفردية، نحصل على صورة المستخدم الآخر
  String? getDisplayImage(String currentUserId) {
    if (isGroup) return groupImageUrl;
    
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.profileImageUrl;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json, {List<ConversationMemberModel>? members}) {
    return ConversationModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessageAt: DateTime.parse(json['last_message_at']),
      isGroup: json['is_group'] ?? false,
      groupName: json['group_name'],
      groupImageUrl: json['group_image_url'],
      createdById: json['created_by'],
      members: members ?? [],
      lastMessageContent: json['last_message_content'],
      lastMessageSender: json['last_message_sender'] != null 
          ? UserModel.fromJson(json['last_message_sender']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'is_group': isGroup,
      'group_name': groupName,
      'group_image_url': groupImageUrl,
      'created_by': createdById,
    };
  }

  ConversationModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    bool? isGroup,
    String? groupName,
    String? groupImageUrl,
    String? createdById,
    List<ConversationMemberModel>? members,
    String? lastMessageContent,
    UserModel? lastMessageSender,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdById: createdById ?? this.createdById,
      members: members ?? this.members,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ConversationMemberModel {
  final String conversationId;
  final UserModel user;
  final DateTime joinedAt;
  final bool isAdmin;
  final DateTime lastReadAt;

  ConversationMemberModel({
    required this.conversationId,
    required this.user,
    required this.joinedAt,
    required this.isAdmin,
    required this.lastReadAt,
  });

  factory ConversationMemberModel.fromJson(Map<String, dynamic> json, {UserModel? user}) {
    return ConversationMemberModel(
      conversationId: json['conversation_id'],
      user: user ?? UserModel.fromJson(json['user'] ?? {}),
      joinedAt: DateTime.parse(json['joined_at']),
      isAdmin: json['is_admin'] ?? false,
      lastReadAt: DateTime.parse(json['last_read_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': user.id,
      'joined_at': joinedAt.toIso8601String(),
      'is_admin': isAdmin,
      'last_read_at': lastReadAt.toIso8601String(),
    };
  }

  ConversationMemberModel copyWith({
    String? conversationId,
    UserModel? user,
    DateTime? joinedAt,
    bool? isAdmin,
    DateTime? lastReadAt,
  }) {
    return ConversationMemberModel(
      conversationId: conversationId ?? this.conversationId,
      user: user ?? this.user,
      joinedAt: joinedAt ?? this.joinedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}

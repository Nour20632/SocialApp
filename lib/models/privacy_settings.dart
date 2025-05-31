class PrivacySettings {
  final String id;
  final String userId;
  final bool isPrivate;
  final bool showActivity;
  final bool allowMentions;
  final String messagePrivacy; // 'EVERYONE', 'follows', 'NONE'
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivacySettings({
    required this.id,
    required this.userId,
    required this.isPrivate,
    required this.showActivity,
    required this.allowMentions,
    required this.messagePrivacy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrivacySettings.fromJson(Map json) {
    return PrivacySettings(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      isPrivate:
          json['is_private'] == null
              ? false
              : (json['is_private'] is bool
                  ? json['is_private']
                  : json['is_private'].toString() == 'true'),
      showActivity:
          json['show_activity'] == null
              ? true
              : (json['show_activity'] is bool
                  ? json['show_activity']
                  : json['show_activity'].toString() == 'true'),
      allowMentions:
          json['allow_mentions'] == null
              ? true
              : (json['allow_mentions'] is bool
                  ? json['allow_mentions']
                  : json['allow_mentions'].toString() == 'true'),
      messagePrivacy: json['message_privacy']?.toString() ?? 'EVERYONE',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  Map toJson() {
    return {
      'id': id,
      'user_id': userId,
      'is_private': isPrivate,
      'show_activity': showActivity,
      'allow_mentions': allowMentions,
      'message_privacy': messagePrivacy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Return a copy of this PrivacySettings with the given fields replaced
  PrivacySettings copyWith({
    String? id,
    String? userId,
    bool? isPrivate,
    bool? showActivity,
    bool? allowMentions,
    String? messagePrivacy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivacySettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isPrivate: isPrivate ?? this.isPrivate,
      showActivity: showActivity ?? this.showActivity,
      allowMentions: allowMentions ?? this.allowMentions,
      messagePrivacy: messagePrivacy ?? this.messagePrivacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

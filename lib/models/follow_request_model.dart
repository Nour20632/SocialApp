class FollowRequest {
  final String id;
  final String followerId;
  final String followingId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool notificationSent;
  final DateTime? seenAt;

  FollowRequest({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notificationSent = false,
    this.seenAt,
  });

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      id: json['id'],
      followerId: json['follower_id'],
      followingId: json['following_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      notificationSent: json['notification_sent'] ?? false,
      seenAt: json['seen_at'] != null ? DateTime.parse(json['seen_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notification_sent': notificationSent,
      'seen_at': seenAt?.toIso8601String(),
    };
  }
}

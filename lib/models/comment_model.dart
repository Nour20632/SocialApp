import 'package:social_app/models/user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      parentId: json['parent_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

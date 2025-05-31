// Changes to PostModel class

import 'package:social_app/models/media_model.dart';
import 'package:social_app/models/user_model.dart';

class PostModel {
  final String id;
  final String authorId;
  final String? typeId;
  final String content;
  final String visibility;
  final String? knowledgeDomain; // New field for knowledge domain
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? author;
  final List<MediaModel>? media;
  final int likeCount;
  final int commentCount;
  final bool userHasLiked;

  PostModel({
    required this.id,
    required this.authorId,
    this.typeId,
    required this.content,
    required this.visibility,
    this.knowledgeDomain, // Added to constructor
    required this.createdAt,
    this.updatedAt,
    this.author,
    this.media,
    this.likeCount = 0,
    this.commentCount = 0,
    this.userHasLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      knowledgeDomain: json['knowledge_domain']?.toString(), // Added parsing
      media:
          json['media'] != null && json['media'] is List
              ? (json['media'] as List)
                  .where((m) => m != null)
                  .map((m) => MediaModel.fromJson(m))
                  .toList()
              : [],
      visibility: json['visibility']?.toString() ?? 'PUBLIC',
      author:
          json['author'] != null ? UserModel.fromJson(json['author']) : null,
      likeCount:
          json['like_count'] is int
              ? json['like_count']
              : (json['like_count'] != null
                  ? int.tryParse(json['like_count'].toString()) ?? 0
                  : (json['likes'] != null &&
                          json['likes'] is List &&
                          json['likes'].isNotEmpty
                      ? (json['likes'][0]['count'] is int
                          ? json['likes'][0]['count']
                          : int.tryParse(
                                json['likes'][0]['count'].toString(),
                              ) ??
                              0)
                      : 0)),
      commentCount:
          json['comment_count'] is int
              ? json['comment_count']
              : (json['comment_count'] != null
                  ? int.tryParse(json['comment_count'].toString()) ?? 0
                  : (json['comments'] != null &&
                          json['comments'] is List &&
                          json['comments'].isNotEmpty
                      ? (json['comments'][0]['count'] is int
                          ? json['comments'][0]['count']
                          : int.tryParse(
                                json['comments'][0]['count'].toString(),
                              ) ??
                              0)
                      : 0)),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      userHasLiked:
          json['user_has_liked'] == null
              ? false
              : (json['user_has_liked'] is bool
                  ? json['user_has_liked']
                  : json['user_has_liked'].toString() == 'true'),
      typeId: json['type_id']?.toString(),
    );
  }

  // Getter to check if this is a knowledge post
  bool get isKnowledgePost => typeId == 'KNOWLEDGE';

  // Getter to get formatted knowledge domain for display
  String get displayKnowledgeDomain {
    if (knowledgeDomain == null || knowledgeDomain!.isEmpty) {
      return '';
    }
    // Capitalize first letter of each word
    return knowledgeDomain!
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : word,
        )
        .join(' ');
  }

  // Add this getter to always provide a list of media URLs for the post
  List<String> get mediaUrls =>
      media != null ? media!.map((m) => m.url).toList() : [];
}

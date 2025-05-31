class MediaModel {
  final String id;
  final String postId;
  final String url;
  final String type;
  final String storagePath; // إضافة حقل لتخزين مسار الملف في التخزين
  final DateTime createdAt;

  MediaModel({
    required this.id,
    required this.postId,
    required this.url,
    required this.type,
    required this.storagePath,
    required this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'],
      postId: json['post_id'],
      url: json['url'],
      type: json['type'],
      storagePath: json['storage_path'] ?? '', // استخراج مسار التخزين
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'url': url,
      'type': type,
      'storage_path': storagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

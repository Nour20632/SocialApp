import 'package:flutter/foundation.dart';
import 'package:social_app/models/user_model.dart';

enum AchievementType {
  islamic,
  personal,
  professional,
  fitness,
  education,
  creative,
  other,
}

class AchievementModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime achievedDate;
  final DateTime createdAt;
  final AchievementType type;
  final String? imageUrl;
  final int celebrationCount;
  final bool hasUserCelebrated;
  final UserModel user;
  final bool isPublic; // إضافة خاصية isPublic
  final DateTime? expiryDate; // Add this field
  final DateTime? completionDate;
  final String status; // New field
  final double progress; // New field
  final Map<String, dynamic>? additionalData; // New field

  AchievementModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.achievedDate,
    required this.createdAt,
    required this.type,
    this.imageUrl,
    required this.celebrationCount,
    required this.hasUserCelebrated,
    required this.user,
    this.isPublic = true, // قيمة افتراضية true
    this.expiryDate, // Add this parameter
    this.completionDate,
    this.status = 'in_progress', // Default value
    this.progress = 0.0, // Default value
    this.additionalData, // Optional field
  });

  factory AchievementModel.fromJson(
    Map<String, dynamic> json, {
    UserModel? user,
  }) {
    AchievementType parseType(String typeStr) {
      try {
        return AchievementType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr.toLowerCase(),
          orElse: () => AchievementType.other,
        );
      } catch (e) {
        debugPrint('Error parsing achievement type: $e');
        return AchievementType.other;
      }
    }

    return AchievementModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      achievedDate: DateTime.parse(json['achieved_date']),
      createdAt: DateTime.parse(json['created_at']),
      type: parseType(json['type']),
      imageUrl: json['image_url'],
      celebrationCount: json['celebration_count'] ?? 0,
      hasUserCelebrated: json['has_user_celebrated'] ?? false,
      isPublic: json['is_public'] ?? true, // إضافة معالجة حقل is_public
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'])
              : null,
      user:
          user ??
          (json['user'] != null
              ? UserModel.fromJson(json['user'])
              : (json['users'] != null
                  ? UserModel.fromJson(json['users'])
                  : UserModel.fromJson(json['profiles'] ?? {}))),
      completionDate:
          json['completion_date'] != null
              ? DateTime.parse(json['completion_date'])
              : null,
      status: json['status'] ?? 'in_progress',
      progress: (json['progress'] ?? 0.0).toDouble(),
      additionalData: json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'achieved_date': achievedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'image_url': imageUrl,
      'celebration_count': celebrationCount,
      'is_public': isPublic, // إضافة حقل is_public للتصدير
      'expiry_date': expiryDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'status': status,
      'progress': progress,
      'additional_data': additionalData,
    };
  }

  // Helper method to get an icon for the achievement type
  static String getTypeIcon(AchievementType type) {
    switch (type) {
      case AchievementType.islamic:
        return '🕌';
      case AchievementType.personal:
        return '🌟';
      case AchievementType.professional:
        return '💼';
      case AchievementType.fitness:
        return '💪';
      case AchievementType.education:
        return '🎓';
      case AchievementType.creative:
        return '🎨';
      case AchievementType.other:
        return '🏆';
    }
  }

  // Add metadata and date getters for compatibility with UI
  Map<String, dynamic>? get metadata {
    // If you store metadata in the JSON, parse it here
    // If not present, return null
    return null;
  }

  DateTime get date => achievedDate;

  // Add helper method to check if achievement is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Add helper method to get remaining time
  Duration? get remainingTime {
    if (expiryDate == null) return null;
    if (isExpired) return Duration.zero;
    return expiryDate!.difference(DateTime.now());
  }
}

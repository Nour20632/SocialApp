import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_service.dart';

class AchievementService {
  final SupabaseClient _supabase;
  final UserService _userService;

  AchievementService(this._supabase) : _userService = UserService(_supabase);

  // جلب إنجازات المستخدم
  Future<List<AchievementModel>> getUserAchievements(
    String userId,
    BuildContext context,
  ) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('*, users(*)')
          .eq('user_id', userId)
          .order('achieved_date', ascending: false);

      // جلب بيانات المستخدم مرة واحدة
      final user = await _userService.getUserById(userId, context);

      final List<AchievementModel> achievements = [];
      for (final item in response) {
        achievements.add(AchievementModel.fromJson(item, user: user));
      }

      return achievements;
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return [];
    }
  }

  // جلب إنجازات مستخدم كما يراها مشاهد معيّن (تراعي is_public وخصوصية الحساب)
  Future<List<AchievementModel>> getUserAchievementsVisibleTo(
    String viewerId,
    String userId,
    BuildContext context,
  ) async {
    try {
      // 1. إذا كان المشاهد هو نفسه صاحب الإنجازات، اعرض الكل
      if (viewerId == userId) {
        return await getUserAchievements(userId, context);
      }

      // 2. جلب معلومات المستخدم للتحقق من نوع الحساب
      final user =
          await _supabase.from('users').select().eq('id', userId).single();

      if (user['account_type'] == 'PUBLIC') {
        // حساب عام: اجلب الإنجازات العامة فقط
        final response = await _supabase
            .from('achievements')
            .select('*, users (*)')
            .eq('user_id', userId)
            .eq('is_public', true)
            .order('created_at', ascending: false);

        if (!context.mounted) return [];

        return response
            .map(
              (json) => AchievementModel.fromJson(
                json,
                user: UserModel.fromJson(json['users']),
              ),
            )
            .toList();
      } else {
        // حساب خاص: تحقق من المتابعة أولاً
        final isFollowing = await _checkIfFollowing(viewerId, userId);

        if (!isFollowing) {
          return []; // لا يمكن مشاهدة أي إنجازات
        }

        final response = await _supabase
            .from('achievements')
            .select('*, users (*)')
            .eq('user_id', userId)
            .eq('is_public', true)
            .order('created_at', ascending: false);

        if (!context.mounted) return [];

        return response
            .map(
              (json) => AchievementModel.fromJson(
                json,
                user: UserModel.fromJson(json['users']),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting visible achievements: $e');
      return [];
    }
  }

  Future<bool> _checkIfFollowing(String followerId, String followingId) async {
    try {
      final response =
          await _supabase
              .from('follows')
              .select()
              .eq('follower_id', followerId)
              .eq('following_id', followingId)
              .single();

      return true; // Will return true if response exists, otherwise catch block will return false
    } catch (e) {
      return false;
    }
  }

  // تم تحديث هذه الدالة لتستخدم _supabase بدلاً من supabase
  Future<List<AchievementModel>> getRecentAchievements([int limit = 10]) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('*, users(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent achievements: $e');
      return [];
    }
  }

  // إنشاء إنجاز جديد - تم إضافة isPublic
  // Modified createAchievement method from achievement_service.dart

  Future<AchievementModel?> createAchievement({
    required String title,
    required String description,
    required DateTime achievedDate,
    required AchievementType type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool isPublic = true,
    Duration? duration,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // تحويل التواريخ إلى UTC
      final now = DateTime.now().toUtc();
      final achievedDateUtc = achievedDate.toUtc();

      // إنشاء البيانات الأساسية
      final Map<String, dynamic> data = {
        'user_id': currentUserId,
        'title': title.trim(),
        'description': description.trim(),
        'achieved_date': achievedDateUtc.toIso8601String(),
        'created_at': now.toIso8601String(),
        'type': type.toString().split('.').last.toUpperCase(),
        'is_public': isPublic,
      };

      // إضافة الحقول الاختيارية فقط إذا كانت موجودة
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (duration != null) {
        data['expiry_date'] = now.add(duration).toUtc().toIso8601String();
      }

      // طباعة البيانات قبل الإرسال
      debugPrint('Attempting to create achievement with data: $data');

      // التحقق من الاتصال بقاعدة البيانات
      try {
        await _supabase.from('achievements').select().limit(1);
      } catch (e) {
        debugPrint('Database connection test failed: $e');
        throw Exception('Database connection failed');
      }

      // محاولة إنشاء الإنجاز
      final response =
          await _supabase
              .from('achievements')
              .insert(data)
              .select('*, users(*)')
              .single();

      debugPrint('Achievement created successfully: $response');

      // تحويل البيانات إلى نموذج
      final achievement = AchievementModel.fromJson(response);

      // تحديث القوائم
      await refreshAchievements();

      return achievement;
    } catch (e, stackTrace) {
      debugPrint('Error creating achievement: $e');
      debugPrint('Stack trace: $stackTrace');

      // تحليل نوع الخطأ وإرجاع رسالة مناسبة
      if (e.toString().contains('duplicate key')) {
        throw Exception('هذا الإنجاز موجود بالفعل');
      } else if (e.toString().contains('violates foreign key')) {
        throw Exception('خطأ في العلاقة مع المستخدم');
      } else if (e.toString().contains('not-authenticated')) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      rethrow;
    }
  }

  Future<void> refreshAchievements() async {
    try {
      debugPrint('Refreshing achievements cache...');
      await getRecentPublicAchievements(forceRefresh: true);
    } catch (e) {
      debugPrint('Error refreshing achievements: $e');
    }
  }

  Future<List<AchievementModel>> getRecentPublicAchievements({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('*, users(*)')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('Fetched achievements: $response');

      return (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent public achievements: $e');
      return [];
    }
  }

  // تحديث إنجاز موجود - تم إضافة isPublic
  Future<AchievementModel?> updateAchievement({
    required String achievementId,
    String? title,
    String? description,
    DateTime? achievedDate,
    AchievementType? type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool? isPublic,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق أولاً من أن الإنجاز ينتمي للمستخدم الحالي
      final existingAchievements = await _supabase
          .from('achievements')
          .select()
          .eq('id', achievementId)
          .eq('user_id', currentUserId);

      if (existingAchievements.isEmpty) {
        throw Exception('Achievement not found or not owned by current user');
      }

      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (achievedDate != null) {
        updateData['achieved_date'] = achievedDate.toIso8601String();
      }
      if (type != null) updateData['type'] = type.toString().split('.').last;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (metadata != null) updateData['metadata'] = metadata;
      if (isPublic != null) updateData['is_public'] = isPublic;

      final response =
          await _supabase
              .from('achievements')
              .update(updateData)
              .eq('id', achievementId)
              .select('*, users(*)')
              .single();

      return AchievementModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating achievement: $e');
      return null;
    }
  }

  // حذف إنجاز
  Future<bool> deleteAchievement(String achievementId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق أولاً من أن الإنجاز ينتمي للمستخدم الحالي
      final existingAchievements = await _supabase
          .from('achievements')
          .select()
          .eq('id', achievementId)
          .eq('user_id', currentUserId);

      if (existingAchievements.isEmpty) {
        throw Exception('Achievement not found or not owned by current user');
      }

      await _supabase.from('achievements').delete().eq('id', achievementId);
      return true;
    } catch (e) {
      debugPrint('Error deleting achievement: $e');
      return false;
    }
  }

  // تسجيل احتفال بالإنجاز (مثل الإعجاب)
  Future<bool> celebrateAchievement(String achievementId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق مما إذا كان المستخدم قد احتفل بالفعل بهذا الإنجاز
      final existingCelebrations = await _supabase
          .from('achievement_celebrations')
          .select()
          .eq('achievement_id', achievementId)
          .eq('user_id', currentUserId);

      if (existingCelebrations.isNotEmpty) {
        // إلغاء الاحتفال إذا كان المستخدم قد احتفل بالفعل
        await _supabase
            .from('achievement_celebrations')
            .delete()
            .eq('achievement_id', achievementId)
            .eq('user_id', currentUserId);
        return false;
      } else {
        // إضافة احتفال جديد
        await _supabase.from('achievement_celebrations').insert({
          'achievement_id': achievementId,
          'user_id': currentUserId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error celebrating achievement: $e');
      return false;
    }
  }

  // الحصول على عدد الاحتفالات لإنجاز معين
  Future<int> getAchievementCelebrationCount(String achievementId) async {
    try {
      final response = await _supabase
          .from('achievement_celebrations')
          .select('count')
          .eq('achievement_id', achievementId);

      return response[0]['count'] ?? 0;
    } catch (e) {
      debugPrint('Error getting celebration count: $e');
      return 0;
    }
  }

  // التحقق مما إذا كان المستخدم قد احتفل بإنجاز معين
  Future<bool> hasUserCelebratedAchievement(String achievementId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return false;
      }

      final response = await _supabase
          .from('achievement_celebrations')
          .select()
          .eq('achievement_id', achievementId)
          .eq('user_id', currentUserId);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user celebrated achievement: $e');
      return false;
    }
  }

  // البحث عن الإنجازات باستخدام كلمة مفتاحية
  Future<List<AchievementModel>> searchAchievements(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('*, users(*)')
          .eq('is_public', true)
          .or('title.ilike.%$query%, description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map<AchievementModel>((item) => AchievementModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error searching achievements: $e');
      return [];
    }
  }

  // رفع صورة للإنجاز وإعادة رابط الصورة
  Future<String?> uploadAchievementImage(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = 'achievements/$currentUserId/$uniqueFileName';

      await _supabase.storage
          .from('media')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              contentType: 'image/jpeg',
            ),
          );

      final imageUrl = _supabase.storage.from('media').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading achievement image: $e');
      return null;
    }
  }

  // Add method to cleanup expired achievements
  Future<void> cleanupExpiredAchievements() async {
    try {
      await _supabase
          .from('achievements')
          .delete()
          .filter('expiry_date', 'lte', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error cleaning up expired achievements: $e');
    }
  }

  Future<AchievementModel> getAchievementById(
    String achievementId,
    BuildContext context,
  ) async {
    try {
      final achievementData =
          await _supabase
              .from('achievements')
              .select('*, users(*)')
              .eq('id', achievementId)
              .single();

      if (!context.mounted) {
        throw Exception('Context is no longer valid');
      }

      final user = await _userService.getUserById(
        achievementData['user_id'],
        context,
      );

      return AchievementModel.fromJson(achievementData, user: user);
    } catch (e) {
      debugPrint('Error getting achievement: $e');
      rethrow;
    }
  }
}

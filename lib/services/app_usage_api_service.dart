// lib/services/app_usage_api_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة واجهة برمجة التطبيقات للتعامل مع إحصائيات استخدام التطبيق
class AppUsageApiService {
  final SupabaseClient _supabase;

  // معدل الوقت الأقصى للاستخدام اليومي بالثواني (3 ساعات)
  static const int defaultDailyLimitSeconds = 10800;

  AppUsageApiService(this._supabase);

  /// الحصول على تاريخ اليوم بتنسيق UTC
  String _getTodayDateUtc() {
    return DateTime.now().toUtc().toString().split('T')[0]; // بتنسيق YYYY-MM-DD
  }

  /// تحديث وقت استخدام المستخدم
  /// [userId] معرف المستخدم
  /// [usedSeconds] الوقت المستخدم بالثواني
  Future<bool> updateUsageTime(String userId, int usedSeconds) async {
    try {
      final today = _getTodayDateUtc();
      final currentTime = DateTime.now().toUtc().toIso8601String();

      // البحث عن سجل اليوم
      final result =
          await _supabase
              .from('daily_app_usage')
              .select()
              .eq('user_id', userId)
              .eq('usage_date', today)
              .maybeSingle();

      if (result != null) {
        // تحديث السجل الموجود
        await _supabase
            .from('daily_app_usage')
            .update({
              'used_time_seconds': result['used_time_seconds'] + usedSeconds,
              'last_active': currentTime,
              'updated_at': currentTime,
            })
            .eq('id', result['id']);
      } else {
        // إنشاء سجل جديد
        await _supabase.from('daily_app_usage').insert({
          'user_id': userId,
          'usage_date': today,
          'used_time_seconds': usedSeconds,
          'last_active': currentTime,
        });
      }
      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث وقت الاستخدام: $e');
      return false;
    }
  }

  /// الحصول على إحصائيات استخدام المستخدم
  /// [userId] معرف المستخدم
  /// [daysBack] عدد الأيام السابقة للحصول على إحصائياتها
  Future<List<Map<String, dynamic>>> getUserUsageStats(
    String userId, {
    int daysBack = 7,
  }) async {
    try {
      final result = await _supabase.rpc(
        'get_user_usage_stats',
        params: {'p_user_id': userId, 'p_days_back': daysBack},
      );

      if (result == null) return [];

      final List<Map<String, dynamic>> stats = List<Map<String, dynamic>>.from(
        result,
      );

      // حساب النسبة المئوية للاستخدام لكل يوم إذا لم تكن موجودة
      for (var i = 0; i < stats.length; i++) {
        if (!stats[i].containsKey('percentage_used')) {
          final usedTimeSeconds = stats[i]['used_time_seconds'] as int? ?? 0;
          stats[i]['percentage_used'] =
              (usedTimeSeconds / defaultDailyLimitSeconds) * 100;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('خطأ في الحصول على إحصائيات الاستخدام: $e');
      return [];
    }
  }

  /// الحصول على وقت الاستخدام اليومي الحالي
  /// [userId] معرف المستخدم
  Future<int> getTodayUsedTime(String userId) async {
    try {
      final today = _getTodayDateUtc();

      final response =
          await _supabase
              .from('daily_app_usage')
              .select('used_time_seconds')
              .eq('user_id', userId)
              .eq('usage_date', today)
              .maybeSingle();

      return response != null
          ? (response['used_time_seconds'] as int?) ?? 0
          : 0;
    } catch (e) {
      debugPrint('خطأ في الحصول على وقت الاستخدام اليومي: $e');
      return 0;
    }
  }

  /// التحقق مما إذا وصل المستخدم للحد الأقصى للاستخدام اليومي
  /// [userId] معرف المستخدم
  /// [maxDailySeconds] الحد الأقصى للاستخدام اليومي بالثواني
  Future<bool> hasReachedDailyLimit(
    String userId, {
    int? maxDailySeconds,
  }) async {
    try {
      final usedTime = await getTodayUsedTime(userId);
      final limit = maxDailySeconds ?? defaultDailyLimitSeconds;
      return usedTime >= limit;
    } catch (e) {
      debugPrint('خطأ في التحقق من الحد الأقصى: $e');
      return false;
    }
  }

  /// الحصول على إنجازات الاستخدام للمستخدم
  /// [userId] معرف المستخدم
  Future<List<Map<String, dynamic>>> getUserUsageAchievements(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .or(
            'type.eq.moderate_usage,type.eq.digital_balance,type.eq.time_manager',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطأ في الحصول على إنجازات الاستخدام: $e');
      return [];
    }
  }

  /// تحديث إنجاز الاستخدام اليومي
  /// [userId] معرف المستخدم
  /// [usedSeconds] الوقت المستخدم بالثواني
  /// [maxDailySeconds] الحد الأقصى للاستخدام اليومي بالثواني
  Future<bool> updateUsageAchievement(
    String userId,
    int usedSeconds, {
    int? maxDailySeconds,
  }) async {
    try {
      final today = _getTodayDateUtc();
      final limit = maxDailySeconds ?? defaultDailyLimitSeconds;
      final usagePercentage = (usedSeconds / limit) * 100;

      final additionalData = {
        'date': today,
        'used_time_seconds': usedSeconds,
        'remaining_time_seconds': limit - usedSeconds,
        'percentage': usagePercentage,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };

      // البحث عن سجل إنجاز موجود لهذا اليوم
      final existingData =
          await _supabase
              .from('achievements')
              .select()
              .eq('user_id', userId)
              .eq('type', 'daily_usage')
              .eq('additional_data->date', today)
              .maybeSingle();

      if (existingData != null) {
        // تحديث السجل الموجود
        await _supabase
            .from('achievements')
            .update({
              'progress': usagePercentage,
              'additional_data': additionalData,
              'status': usedSeconds >= limit ? 'completed' : 'in_progress',
            })
            .eq('id', existingData['id']);
      } else {
        // إنشاء سجل جديد
        await _supabase.from('achievements').insert({
          'user_id': userId,
          'title': 'استخدام التطبيق اليومي',
          'description': 'تتبع وقت استخدام التطبيق ليوم $today',
          'achieved_date': DateTime.now().toUtc().toIso8601String(),
          'type': 'daily_usage',
          'progress': usagePercentage,
          'additional_data': additionalData,
          'status': usedSeconds >= limit ? 'completed' : 'in_progress',
        });
      }

      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث إنجاز الاستخدام: $e');
      return false;
    }
  }

  /// الحصول على ملخص استخدام المستخدم بشكل كامل
  /// [userId] معرف المستخدم
  /// [maxDailySeconds] الحد الأقصى للاستخدام اليومي بالثواني
  Future<Map<String, dynamic>> getUserUsageSummary(
    String userId, {
    int? maxDailySeconds,
    int daysBack = 7,
  }) async {
    try {
      final stats = await getUserUsageStats(userId, daysBack: daysBack);
      final todayUsage = await getTodayUsedTime(userId);
      final limit = maxDailySeconds ?? defaultDailyLimitSeconds;
      final remainingTime = limit - todayUsage;

      // حساب متوسط الاستخدام اليومي
      double averageUsage = 0;
      if (stats.isNotEmpty) {
        int totalUsage = 0;
        for (final stat in stats) {
          totalUsage += stat['used_time_seconds'] as int? ?? 0;
        }
        averageUsage = totalUsage / stats.length;
      }

      return {
        'stats': stats,
        'todayUsage': todayUsage,
        'remainingTime': remainingTime > 0 ? remainingTime : 0,
        'limitReached': todayUsage >= limit,
        'usagePercentage': (todayUsage / limit) * 100,
        'averageUsageSeconds': averageUsage,
        'averageUsageHours': averageUsage / 3600,
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على ملخص الاستخدام: $e');
      return {
        'stats': [],
        'todayUsage': 0,
        'remainingTime': maxDailySeconds ?? defaultDailyLimitSeconds,
        'limitReached': false,
        'usagePercentage': 0,
        'averageUsageSeconds': 0,
        'averageUsageHours': 0,
      };
    }
  }
}

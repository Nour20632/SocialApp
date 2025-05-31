// lib/services/unified_usage_tracker_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_app/utils/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnifiedUsageTrackerService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final BuildContext _context;
  Timer? _activityTimer;
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;
  bool _isTracking = false;

  // وقت الاستخدام المتبقي اليوم (بالثواني)
  int _remainingTimeSeconds = 0;

  // إجمالي وقت الاستخدام اليوم (بالثواني)
  int _totalUsageSeconds = 0;

  // مؤشر ما إذا تم إرسال التنبيهات
  final Map<int, bool> _alertsSent = {};

  // معرف المستخدم الحالي
  String? _userId;

  // إعدادات التنبيهات المحلية
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  UnifiedUsageTrackerService(this._supabase, this._context) {
    _initNotifications();
  }

  // تهيئة نظام التنبيهات
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // الحصول على إعدادات التطبيق
  AppSettings get _appSettings =>
      Provider.of<AppSettings>(_context, listen: false);

  // بدء تتبع نشاط المستخدم
  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    _userId = userId;
    await _loadTodayUsage();

    // التحقق من تفعيل حد الاستخدام وما إذا كان قد تم الوصول إليه
    if (_appSettings.isUsageLimitEnabled && _remainingTimeSeconds <= 0) {
      notifyLimitReached();
      notifyListeners();
      return;
    }

    _isTracking = true;
    _sessionStartTime = DateTime.now();
    _lastActiveTime = _sessionStartTime;

    // بدء مؤقت لتحديث وقت الاستخدام كل 30 ثانية
    _activityTimer = Timer.periodic(
      const Duration(seconds: 30),
      _updateUsageTime,
    );

    notifyListeners();
  }

  // إيقاف تتبع نشاط المستخدم
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _activityTimer?.cancel();
    _activityTimer = null;

    if (_sessionStartTime != null && _lastActiveTime != null) {
      // حساب وقت الجلسة وتحديث قاعدة البيانات
      final sessionDuration =
          _lastActiveTime!.difference(_sessionStartTime!).inSeconds;
      await _updateUsageInDatabase(sessionDuration);
    }

    _isTracking = false;
    _sessionStartTime = null;
    _lastActiveTime = null;

    notifyListeners();
  }

  // تحميل بيانات استخدام اليوم
  Future<void> _loadTodayUsage() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsageDate = prefs.getString('last_usage_date');
      final today = DateTime.now().toIso8601String().split('T')[0];

      // إذا كان آخر استخدام ليس اليوم، أعد ضبط المؤقت وكل القيم
      if (lastUsageDate != today) {
        await _resetForNewDay(today);
      } else {
        // استرجاع البيانات من التخزين المحلي
        _totalUsageSeconds = prefs.getInt('total_usage_today') ?? 0;
        _remainingTimeSeconds =
            _appSettings.maxDailyUsageSeconds - _totalUsageSeconds;
        _remainingTimeSeconds =
            _remainingTimeSeconds < 0 ? 0 : _remainingTimeSeconds;

        // استرجاع حالة التنبيهات المرسلة
        for (int i = 1; i <= 3; i++) {
          _alertsSent[i] = prefs.getBool('alert_${i}_sent_$today') ?? false;
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الاستخدام: $e');
      _totalUsageSeconds = 0;
      _remainingTimeSeconds = _appSettings.maxDailyUsageSeconds;
    }

    notifyListeners();
  }

  // إعادة تعيين بيانات الاستخدام ليوم جديد
  Future<void> _resetForNewDay(String today) async {
    final prefs = await SharedPreferences.getInstance();

    _totalUsageSeconds = 0;
    _remainingTimeSeconds = _appSettings.maxDailyUsageSeconds;
    _alertsSent.clear();

    await prefs.setString('last_usage_date', today);
    await prefs.setInt('total_usage_today', 0);
    await prefs.setInt('remaining_time', _remainingTimeSeconds);

    // حذف التنبيهات القديمة
    for (int i = 1; i <= 3; i++) {
      await prefs.remove('alert_${i}_sent_$today');
    }

    // تحديث قاعدة البيانات إذا كان المستخدم متصلاً
    if (_userId != null) {
      try {
        await _supabase.from('daily_app_usage').insert({
          'user_id': _userId,
          'usage_date': today,
          'used_time_seconds': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('خطأ في تحديث قاعدة البيانات لليوم الجديد: $e');
      }
    }
  }

  // تحديث وقت النشاط (يُستدعى من المؤقت)
  void _updateUsageTime(Timer timer) async {
    if (!_isTracking || _userId == null || _lastActiveTime == null) return;

    final now = DateTime.now();
    final elapsedSeconds = now.difference(_lastActiveTime!).inSeconds;

    if (elapsedSeconds > 0) {
      _lastActiveTime = now;
      _totalUsageSeconds += elapsedSeconds;

      // تحديث الوقت المتبقي إذا كان حد الاستخدام مفعلاً
      if (_appSettings.isUsageLimitEnabled) {
        _remainingTimeSeconds =
            _appSettings.maxDailyUsageSeconds - _totalUsageSeconds;
        _remainingTimeSeconds =
            _remainingTimeSeconds < 0 ? 0 : _remainingTimeSeconds;
      }

      // تخزين البيانات محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_usage_today', _totalUsageSeconds);
      await prefs.setInt('remaining_time', _remainingTimeSeconds);

      // التحقق من الحاجة إلى إرسال تنبيهات
      if (_appSettings.enableUsageAlerts) {
        await _checkAndSendAlerts();
      }

      // التحقق مما إذا تم الوصول إلى الحد الأقصى للاستخدام
      if (_appSettings.isUsageLimitEnabled && _remainingTimeSeconds <= 0) {
        await stopTracking();
        notifyLimitReached();
      }

      notifyListeners();
    }
  }

  // التحقق من الحاجة إلى إرسال تنبيهات وإرسالها
  Future<void> _checkAndSendAlerts() async {
    if (!_appSettings.enableUsageAlerts) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usagePercentage =
        (_totalUsageSeconds / _appSettings.maxDailyUsageSeconds) * 100;

    // تنبيه عند استخدام 50% من الوقت
    if (usagePercentage >= 50 && !(_alertsSent[1] ?? false)) {
      _sendAlert(
        'استخدام التطبيق',
        'لقد استخدمت 50% من الوقت المسموح به اليوم',
      );
      _alertsSent[1] = true;
      await prefs.setBool('alert_1_sent_$today', true);
    }

    // تنبيه عند استخدام 75% من الوقت
    if (usagePercentage >= 75 && !(_alertsSent[2] ?? false)) {
      _sendAlert(
        'استخدام التطبيق',
        'لقد استخدمت 75% من الوقت المسموح به اليوم',
      );
      _alertsSent[2] = true;
      await prefs.setBool('alert_2_sent_$today', true);
    }

    // تنبيه عند استخدام 90% من الوقت
    if (usagePercentage >= 90 && !(_alertsSent[3] ?? false)) {
      _sendAlert(
        'استخدام التطبيق',
        'تحذير: متبقي ${_formatTime(_remainingTimeSeconds)} فقط للاستخدام اليوم',
      );
      _alertsSent[3] = true;
      await prefs.setBool('alert_3_sent_$today', true);
    }
  }

  // تحديث بيانات الاستخدام في قاعدة البيانات
  Future<void> _updateUsageInDatabase(int sessionDurationSeconds) async {
    if (_userId == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // تحديث بيانات الاستخدام اليومية
      final existingData =
          await _supabase
              .from('daily_app_usage')
              .select()
              .eq('user_id', _userId!)
              .eq('usage_date', today)
              .maybeSingle();

      if (existingData != null) {
        await _supabase
            .from('daily_app_usage')
            .update({
              'used_time_seconds':
                  existingData['used_time_seconds'] + sessionDurationSeconds,
              'last_active': DateTime.now().toIso8601String(),
            })
            .eq('id', existingData['id']);
      } else {
        await _supabase.from('daily_app_usage').insert({
          'user_id': _userId,
          'usage_date': today,
          'used_time_seconds': sessionDurationSeconds,
        });
      }

      // تحديث بيانات الإنجازات المتعلقة بالاستخدام (إذا كان حد الاستخدام مفعلاً)
      if (_appSettings.isUsageLimitEnabled) {
        await _updateAchievements();
      }
    } catch (e) {
      debugPrint('خطأ في تحديث بيانات الاستخدام: $e');
    }
  }

  // تحديث بيانات الإنجازات
  Future<void> _updateAchievements() async {
    if (_userId == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usagePercentage =
          (_totalUsageSeconds / _appSettings.maxDailyUsageSeconds) * 100;

      // البحث عن سجل إنجاز موجود لهذا اليوم
      final existingData =
          await _supabase
              .from('achievements')
              .select()
              .eq('user_id', _userId!)
              .eq('type', 'daily_usage')
              .eq('additional_data->date', today)
              .maybeSingle();

      final additionalData = {
        'date': today,
        'used_time_seconds': _totalUsageSeconds,
        'remaining_time_seconds': _remainingTimeSeconds,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (existingData != null) {
        // تحديث السجل الموجود
        await _supabase
            .from('achievements')
            .update({
              'progress': usagePercentage,
              'additional_data': additionalData,
              'status':
                  _remainingTimeSeconds <= 0 && _appSettings.isUsageLimitEnabled
                      ? 'completed'
                      : 'in_progress',
            })
            .eq('id', existingData['id']);
      } else {
        // إنشاء سجل جديد
        await _supabase.from('achievements').insert({
          'user_id': _userId,
          'title': 'استخدام التطبيق اليومي',
          'description': 'تتبع وقت استخدام التطبيق ليوم $today',
          'achieved_date': DateTime.now().toIso8601String(),
          'type': 'daily_usage',
          'progress': usagePercentage,
          'additional_data': additionalData,
          'status':
              _remainingTimeSeconds <= 0 && _appSettings.isUsageLimitEnabled
                  ? 'completed'
                  : 'in_progress',
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحديث بيانات الإنجازات: $e');
    }
  }

  // إرسال تنبيه للمستخدم
  Future<void> _sendAlert(String title, String body) async {
    if (!_appSettings.enableUsageAlerts) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'usage_channel',
          'تنبيهات الاستخدام',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // إشعار بالوصول إلى الحد الأقصى للاستخدام
  void notifyLimitReached() {
    if (!_appSettings.isUsageLimitEnabled || !_appSettings.enableUsageAlerts) {
      return;
    }

    final minutes = _appSettings.maxDailyUsageMinutes;
    final hoursText = minutes >= 60 ? '${minutes ~/ 60} ساعة' : '';
    final minutesText = minutes % 60 > 0 ? ' و ${minutes % 60} دقيقة' : '';
    final timeText = '$hoursText$minutesText';

    _sendAlert(
      'انتهى وقت الاستخدام اليومي',
      'لقد وصلت إلى الحد الأقصى للاستخدام اليومي ($timeText). يرجى العودة غدًا.',
    );
  }

  // تنسيق الوقت للعرض
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hour and $minutes minute';
    } else {
      return '$minutes minute';
    }
  }

  // إعادة ضبط الإحصائيات اليومية
  Future<void> resetDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    _totalUsageSeconds = 0;
    _remainingTimeSeconds = _appSettings.maxDailyUsageSeconds;
    _alertsSent.clear();

    await prefs.setString('last_usage_date', today);
    await prefs.setInt('total_usage_today', 0);
    await prefs.setInt('remaining_time', _remainingTimeSeconds);

    for (int i = 1; i <= 3; i++) {
      await prefs.setBool('alert_${i}_sent_$today', false);
    }

    notifyListeners();
  }

  // الحصول على الإحصائيات
  Future<Map<String, dynamic>> getUserUsageStats(
    String userId, {
    int daysBack = 7,
  }) async {
    try {
      final result = await _supabase.rpc(
        'get_user_usage_stats',
        params: {'p_user_id': userId, 'p_days_back': daysBack},
      );

      return {
        'stats': result ?? [],
        'totalToday': _totalUsageSeconds,
        'remainingToday': _remainingTimeSeconds,
        'limitEnabled': _appSettings.isUsageLimitEnabled,
        'dailyLimit': _appSettings.maxDailyUsageMinutes,
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على إحصائيات الاستخدام: $e');
      return {
        'stats': [],
        'totalToday': _totalUsageSeconds,
        'remainingToday': _remainingTimeSeconds,
        'limitEnabled': _appSettings.isUsageLimitEnabled,
        'dailyLimit': _appSettings.maxDailyUsageMinutes,
      };
    }
  }

  // التحقق مما إذا كان المستخدم قد وصل إلى الحد الأقصى
  Future<bool> checkLimitReached(String userId) async {
    _userId = userId;
    await _loadTodayUsage();
    return _appSettings.isUsageLimitEnabled && _remainingTimeSeconds <= 0;
  }

  // الحصول على الوقت المتبقي
  int get remainingTimeSeconds => _remainingTimeSeconds;

  // الحصول على إجمالي وقت الاستخدام اليوم
  int get totalUsageSeconds => _totalUsageSeconds;

  // التحقق مما إذا كان المستخدم قد وصل إلى الحد الأقصى
  bool get isLimitReached =>
      _appSettings.isUsageLimitEnabled && _remainingTimeSeconds <= 0;

  // تنسيق الوقت المتبقي للعرض
  String get formattedRemainingTime => _formatTime(_remainingTimeSeconds);

  // تنسيق إجمالي وقت الاستخدام للعرض
  String get formattedTotalTime => _formatTime(_totalUsageSeconds);

  // النسبة المئوية للاستخدام
  double get usagePercentage =>
      _appSettings.maxDailyUsageSeconds > 0
          ? (_totalUsageSeconds / _appSettings.maxDailyUsageSeconds) * 100
          : 0;

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

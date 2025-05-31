// lib/services/app_life_cycle_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'usage_tracker_service.dart'; // تعديل لاستخدام الخدمة الصحيحة

/// خدمة إدارة دورة حياة التطبيق - تتبع حالة التطبيق (خلفية/مقدمة) وتحديث التتبع
class AppLifeCycleService with WidgetsBindingObserver {
  final BuildContext context;
  bool _isInitialized = false;

  AppLifeCycleService(this.context) {
    _initialize();
  }

  /// تهيئة الخدمة وإضافة المراقب
  void _initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;

      // بدء التتبع عند تهيئة الخدمة إذا كان المستخدم مسجلاً الدخول
      _startTrackingIfLoggedIn();
    }
  }

  /// التحقق من تسجيل الدخول وبدء التتبع
  void _startTrackingIfLoggedIn() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final usageService = Provider.of<UnifiedUsageTrackerService>(
          context,
          listen: false,
        );
        usageService.startTracking(user.id);
      } catch (e) {
        debugPrint('خطأ في بدء تتبع الاستخدام: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final usageService = Provider.of<UnifiedUsageTrackerService>(
        context,
        listen: false,
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return; // لا داعي للتتبع إذا لم يكن المستخدم مسجلاً الدخول
      }

      switch (state) {
        case AppLifecycleState.resumed:
          // بدء التتبع عندما يعود التطبيق إلى المقدمة
          usageService.startTracking(user.id);
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.inactive:
          // إيقاف التتبع عندما يكون التطبيق في الخلفية
          usageService.stopTracking();
          break;
        case AppLifecycleState.hidden: // إضافة الحالة الجديدة في Flutter الأحدث
          usageService.stopTracking();
          break;
      }
    } catch (e) {
      debugPrint('خطأ في تغيير حالة دورة حياة التطبيق: $e');
    }
  }

  /// التأكد من تنظيف الموارد عند الإنهاء
  void dispose() {
    if (_isInitialized) {
      try {
        final usageService = Provider.of<UnifiedUsageTrackerService>(
          context,
          listen: false,
        );
        usageService.stopTracking();
      } catch (e) {
        debugPrint('خطأ في إيقاف تتبع الاستخدام: $e');
      }

      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }
}

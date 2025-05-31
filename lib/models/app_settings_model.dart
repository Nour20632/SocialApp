// lib/models/app_settings_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsModel {
  // إعدادات المستخدم
  final bool isArabic;
  final Locale locale;
  final bool isUsageLimitEnabled; // تمكين/تعطيل حد الاستخدام
  final int maxDailyUsageMinutes; // الحد الأقصى للاستخدام (بالدقائق)
  final bool showUsageTimer; // عرض مؤقت الاستخدام في الواجهة
  final bool enableUsageAlerts; // تمكين التنبيهات

  const AppSettingsModel({
    this.isArabic = false,
    this.locale = const Locale('en'),
    this.isUsageLimitEnabled = false,
    this.maxDailyUsageMinutes = 180, // 3 ساعات افتراضياً
    this.showUsageTimer = true,
    this.enableUsageAlerts = true,
  });

  // إنشاء نسخة جديدة مع تحديث بعض الإعدادات
  AppSettingsModel copyWith({
    bool? isArabic,
    Locale? locale,
    bool? isUsageLimitEnabled,
    int? maxDailyUsageMinutes,
    bool? showUsageTimer,
    bool? enableUsageAlerts,
  }) {
    return AppSettingsModel(
      isArabic: isArabic ?? this.isArabic,
      locale: locale ?? this.locale,
      isUsageLimitEnabled: isUsageLimitEnabled ?? this.isUsageLimitEnabled,
      maxDailyUsageMinutes: maxDailyUsageMinutes ?? this.maxDailyUsageMinutes,
      showUsageTimer: showUsageTimer ?? this.showUsageTimer,
      enableUsageAlerts: enableUsageAlerts ?? this.enableUsageAlerts,
    );
  }

  // تحويل الإعدادات إلى JSON للتخزين
  Map<String, dynamic> toJson() {
    return {
      'isArabic': isArabic,
      'locale': locale.languageCode,
      'isUsageLimitEnabled': isUsageLimitEnabled,
      'maxDailyUsageMinutes': maxDailyUsageMinutes,
      'showUsageTimer': showUsageTimer,
      'enableUsageAlerts': enableUsageAlerts,
    };
  }

  // إنشاء إعدادات من JSON
  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      isArabic: json['isArabic'] ?? false,
      locale: Locale(json['locale'] ?? 'en'),
      isUsageLimitEnabled: json['isUsageLimitEnabled'] ?? false,
      maxDailyUsageMinutes: json['maxDailyUsageMinutes'] ?? 180,
      showUsageTimer: json['showUsageTimer'] ?? true,
      enableUsageAlerts: json['enableUsageAlerts'] ?? true,
    );
  }

  // حفظ الإعدادات محلياً
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isArabic', isArabic);
    await prefs.setString('locale', locale.languageCode);
    await prefs.setBool('isUsageLimitEnabled', isUsageLimitEnabled);
    await prefs.setInt('maxDailyUsageMinutes', maxDailyUsageMinutes);
    await prefs.setBool('showUsageTimer', showUsageTimer);
    await prefs.setBool('enableUsageAlerts', enableUsageAlerts);
  }

  // تحميل الإعدادات من التخزين المحلي
  static Future<AppSettingsModel> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsModel(
      isArabic: prefs.getBool('isArabic') ?? false,
      locale: Locale(prefs.getString('locale') ?? 'en'),
      isUsageLimitEnabled: prefs.getBool('isUsageLimitEnabled') ?? false,
      maxDailyUsageMinutes: prefs.getInt('maxDailyUsageMinutes') ?? 180,
      showUsageTimer: prefs.getBool('showUsageTimer') ?? true,
      enableUsageAlerts: prefs.getBool('enableUsageAlerts') ?? true,
    );
  }
}

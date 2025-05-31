// lib/utils/app_settings.dart
import 'package:flutter/material.dart';
import 'package:social_app/models/app_settings_model.dart';

class AppSettings extends ChangeNotifier {
  AppSettingsModel _settings = const AppSettingsModel();

  // الإعدادات الحالية
  AppSettingsModel get settings => _settings;

  // اختصارات للوصول السريع للإعدادات الشائعة
  bool get isArabic => _settings.isArabic;
  Locale get locale => _settings.locale;
  bool get isUsageLimitEnabled => _settings.isUsageLimitEnabled;
  int get maxDailyUsageMinutes => _settings.maxDailyUsageMinutes;
  int get maxDailyUsageSeconds => _settings.maxDailyUsageMinutes * 60;
  bool get showUsageTimer => _settings.showUsageTimer;
  bool get enableUsageAlerts => _settings.enableUsageAlerts;

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await AppSettingsModel.loadFromPrefs();
    notifyListeners();
  }

  // تحديث اللغة
  Future<void> setLocale(String languageCode) async {
    final newSettings = _settings.copyWith(
      isArabic: languageCode == 'ar',
      locale: Locale(languageCode),
    );
    await _updateSettings(newSettings);
  }

  // تفعيل/تعطيل حد الاستخدام
  Future<void> setUsageLimitEnabled(bool enabled) async {
    final newSettings = _settings.copyWith(isUsageLimitEnabled: enabled);
    await _updateSettings(newSettings);
  }

  // تعيين الحد الأقصى للاستخدام اليومي
  Future<void> setMaxDailyUsage(int minutes) async {
    final newSettings = _settings.copyWith(maxDailyUsageMinutes: minutes);
    await _updateSettings(newSettings);
  }

  // تفعيل/تعطيل إظهار مؤقت الاستخدام
  Future<void> setShowUsageTimer(bool show) async {
    final newSettings = _settings.copyWith(showUsageTimer: show);
    await _updateSettings(newSettings);
  }

  // تفعيل/تعطيل التنبيهات
  Future<void> setEnableUsageAlerts(bool enable) async {
    final newSettings = _settings.copyWith(enableUsageAlerts: enable);
    await _updateSettings(newSettings);
  }

  // تحديث الإعدادات وحفظها
  Future<void> _updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    await _settings.saveToPrefs();
    notifyListeners();
  }

  // إعادة تعيين الإعدادات إلى القيم الافتراضية
  Future<void> resetToDefaults() async {
    _settings = const AppSettingsModel();
    await _settings.saveToPrefs();
    notifyListeners();
  }
}

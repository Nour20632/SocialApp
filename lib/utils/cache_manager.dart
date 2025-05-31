import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._();
  factory AppCacheManager() => _instance;
  AppCacheManager._();

  // تخزين مؤقت في الذاكرة
  final Map<String, dynamic> _memoryCache = {};

  // تخزين مؤقت للملفات
  final _fileCache = CacheManager(
    Config(
      'app_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'app_cache_db'),
      fileService: HttpFileService(),
    ),
  );

  // تخزين البيانات في الذاكرة
  Future<void> cacheData(String key, dynamic data, {Duration? duration}) async {
    _memoryCache[key] = data;
    if (duration != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${key}_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt('${key}_duration', duration.inSeconds);
    }
  }

  // استرجاع البيانات من الذاكرة
  dynamic getCachedData(String key) {
    return _memoryCache[key];
  }

  // التحقق من صلاحية البيانات المخزنة
  Future<bool> isDataValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('${key}_timestamp');
    final duration = prefs.getInt('${key}_duration');

    if (timestamp == null || duration == null) return false;

    final storedTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(storedTime).inSeconds < duration;
  }

  // تخزين ملف
  Future<void> putFile(String url, List<int> bytes) async {
    await _fileCache.putFile(url, Uint8List.fromList(bytes));
  }

  // استرجاع ملف
  Future<FileInfo?> getFileFromCache(String url) async {
    return await _fileCache.getFileFromCache(url);
  }

  // مسح جميع البيانات المخزنة
  Future<void> clearCache() async {
    _memoryCache.clear();
    await _fileCache.emptyCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // مسح بيانات محددة
  Future<void> removeData(String key) async {
    _memoryCache.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${key}_timestamp');
    await prefs.remove('${key}_duration');
  }
}

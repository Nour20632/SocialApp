import 'package:flutter/foundation.dart';

class PerformanceUtils {
  static bool get shouldOptimize => !kDebugMode;

  static const int pageSize = 10;
  static const Duration cacheTimeout = Duration(minutes: 5);

  static Future<T> computeAsync<T>(
    Future<T> Function() computation, {
    bool useIsolate = true,
  }) async {
    if (!useIsolate || !shouldOptimize) {
      return await computation();
    }
    return await compute((message) async => await computation(), null);
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const CustomShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: baseColor ?? 
          (isDark ? Colors.grey[850]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? 
          (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      period: duration,
      child: child,
    );
  }
}

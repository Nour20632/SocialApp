import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(milliseconds: 1500),
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // تبسيط الحركة باستخدام متحكم واحد فقط
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // بدء الحركة
    _animationController.forward();

    // الانتقال التلقائي بعد انتهاء المدة
    if (widget.autoNavigate) {
      _animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isNavigating) {
          _navigateToNextScreen();
        }
      });
    }
  }

  // الانتقال للشاشة التالية
  void _navigateToNextScreen() {
    if (!mounted || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // استخدام ألوان من السمة المحددة
    final Color primaryColor = theme.colorScheme.primary;
    final Color backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: DotsPainter(
                    animation: _animationController,
                    dotColor: primaryColor,
                    dotCount: 5,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DotsPainter extends CustomPainter {
  final Animation<double> animation;
  final Color dotColor;
  final int dotCount;

  // حجم النقاط وعدد الدوائر
  final double baseRadius = 4.0;
  final double maxRadiusMultiplier = 1.8;

  DotsPainter({
    required this.animation,
    required this.dotColor,
    this.dotCount = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // رسم دائرة النقاط
    for (int i = 0; i < dotCount; i++) {
      // حساب موقع كل نقطة على الدائرة
      final angle = 2 * math.pi * i / dotCount;

      // إضافة تأخير لكل نقطة بناءً على موقعها
      final dotDelay = i / dotCount;
      final dotAnimation = (animation.value + dotDelay) % 1.0;

      // حساب حجم النقطة بناءً على الحركة
      final dotScale = 0.5 + math.sin(dotAnimation * math.pi) * 0.5;
      final dotRadius = baseRadius * (1 + dotScale * maxRadiusMultiplier);

      // حساب موقع النقطة
      final dotOffset = Offset(
        center.dx + math.cos(angle) * radius * 0.7,
        center.dy + math.sin(angle) * radius * 0.7,
      );

      // رسم النقطة مع تأثير الشفافية
      final paint =
          Paint()
            ..color = dotColor.withOpacity(0.3 + dotScale * 0.7)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(dotOffset, dotRadius, paint);
    }

    // رسم التأثير الإضافي للنقاط (موجة خارجية)
    _drawRippleEffect(canvas, center, radius, animation.value);
  }

  // رسم تأثير الموجة الخارجية
  void _drawRippleEffect(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    // تأثير دائري ينتشر للخارج
    final rippleProgress = progress % 1.0;
    final rippleRadius = radius * rippleProgress * 1.3;
    final rippleOpacity = (1.0 - rippleProgress) * 0.4;

    if (rippleOpacity > 0) {
      final ripplePaint =
          Paint()
            ..color = dotColor.withOpacity(rippleOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DotsPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}

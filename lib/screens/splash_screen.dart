import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;
  final String? logoAssetPath;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(milliseconds: 1500), // Max 1.5 seconds
    this.logoAssetPath = 'assets/splash_icon.png',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  // Colors matching the existing app theme
  // Colors matching the green app theme
  final Color backgroundColor = const Color(0xFFB2DFDA); // Very light green
  final Color primaryColor = const Color(0xFF009473); // Primary green
  final Color secondaryColor = const Color(0xFFF5F5F5); // Icon white

  @override
  void initState() {
    super.initState();

    // Simple animation controller for the brief animation
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Create fade in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Create scale animation (subtle)
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start animation
    _animationController.forward();

    // Navigate to next screen after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeInAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogo(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // If logo asset path is provided
    if (widget.logoAssetPath != null) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            widget.logoAssetPath!,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback to text-based logo
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // سين (Arabic "Seen")
          Text(
            "سين",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          // SEEN
          Container(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "SEEN",
              style: TextStyle(
                color: secondaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

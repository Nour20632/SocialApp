import 'dart:async';

import 'package:flutter/material.dart';

/// Widget for displaying challenges that users can complete to gain extra time
class ChallengeDialog extends StatefulWidget {
  final String title;
  final String description;
  final String language;
  final Function() onComplete;

  const ChallengeDialog({
    super.key,
    required this.title,
    required this.description,
    required this.language,
    required this.onComplete,
  });

  @override
  _ChallengeDialogState createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isCompleting = false;
  int _countdownSeconds = 30; // Default countdown time
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Adjust countdown based on challenge type
    if (widget.title.contains('Breathing') || widget.title.contains('تنفس')) {
      _countdownSeconds = 60;
    } else if (widget.title.contains('Walk') || widget.title.contains('مشي')) {
      _countdownSeconds = 120;
    }

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleComplete() async {
    setState(() => _isCompleting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _animation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              widget.language == 'ar'
                  ? 'الوقت المتبقي: $_countdownSeconds ثانية'
                  : 'Time left: $_countdownSeconds s',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed:
                (_countdownSeconds == 0 && !_isCompleting)
                    ? _handleComplete
                    : null,
            child:
                _isCompleting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(widget.language == 'ar' ? 'تم' : 'Done'),
          ),
        ],
      ),
    );
  }
}

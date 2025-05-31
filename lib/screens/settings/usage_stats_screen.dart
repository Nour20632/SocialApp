import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class UsageStatisticsScreen extends StatefulWidget {
  final String userId;

  const UsageStatisticsScreen({super.key, required this.userId});

  @override
  State<UsageStatisticsScreen> createState() => _UsageStatisticsScreenState();
}

class _UsageStatisticsScreenState extends State<UsageStatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _cardController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;
  Timer? _timeTimer;
  DateTime _currentTime = DateTime.now();

  // بيانات وهمية للإحصائيات (أقل من 3 ساعات)
  // يمكن تحميل البيانات بناءً على userId المرسل
  final Map<String, dynamic> stats = {
    'todayUsage': 127, // دقيقة (2 ساعة و7 دقائق)
    'weeklyAverage': 98, // دقيقة
    'totalSessions': 23,
    'pickups': 47,
    'notifications': 156,
    'maxDailyLimit': 180, // 3 ساعات
  };

  @override
  void initState() {
    super.initState();

    // يمكنك هنا تحميل البيانات بناءً على widget.userId
    // await _loadUserStats(widget.userId);

    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (stats['todayUsage'] / stats['maxDailyLimit']).clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _startAnimations();
    _startTimer();
  }

  // دالة لتحميل بيانات المستخدم (يمكن تطويرها لاحقاً)
  Future<void> _loadUserStats(String userId) async {
    // هنا يمكن استدعاء API أو قاعدة البيانات لتحميل بيانات المستخدم
    // مثال:
    // final userStats = await ApiService.getUserStats(userId);
    // setState(() {
    //   stats.addAll(userStats);
    // });
  }

  void _startAnimations() {
    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _progressController.forward();
    });
  }

  void _startTimer() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}س ${mins}د';
    }
    return '${mins}د';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return Colors.red;
    if (progress >= 0.7) return Colors.orange;
    if (progress >= 0.5) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFEBF4FF), Color(0xFFF0F4FF), Color(0xFFF5F3FF)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildMainProgressCard(),
                  const SizedBox(height: 30),
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  _buildWeeklyChart(),
                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        final animValue = _cardAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: animValue,
          child: Column(
            children: [
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ).createShader(bounds),
                child: const Text(
                  'إحصائيات الاستخدام اليومية',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getArabicDate(_currentTime),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainProgressCard() {
    final progressPercentage = (stats['todayUsage'] / stats['maxDailyLimit'])
        .clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        final animValue = _cardAnimation.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'وقت الاستخدام اليوم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(stats['todayUsage']),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'من أصل ${_formatTime(stats['maxDailyLimit'])}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getProgressColor(progressPercentage),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _getUsageStatus(progressPercentage),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildCircularProgress(progressPercentage),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularProgress(double progress) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animValue = _progressAnimation.value.clamp(0.0, 1.0);
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: animValue,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        'مكتمل',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    final statsData = [
      {
        'icon': Icons.bar_chart,
        'title': 'المتوسط الأسبوعي',
        'value': _formatTime(stats['weeklyAverage']),
        'subtitle': 'يومياً',
        'color': Colors.blue,
      },
      {
        'icon': Icons.smartphone,
        'title': 'جلسات الاستخدام',
        'value': '${stats['totalSessions']}',
        'subtitle': 'جلسة اليوم',
        'color': Colors.green,
      },
      {
        'icon': Icons.touch_app,
        'title': 'مرات فتح الهاتف',
        'value': '${stats['pickups']}',
        'subtitle': 'مرة اليوم',
        'color': Colors.purple,
      },
      {
        'icon': Icons.notifications,
        'title': 'الإشعارات',
        'value': '${stats['notifications']}',
        'subtitle': 'إشعار اليوم',
        'color': Colors.pink,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        return _buildStatCard(
          statsData[index],
          Duration(milliseconds: 200 * index),
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, Duration delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final animValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(stat['icon'], color: stat['color'], size: 18),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stat['value'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          stat['subtitle'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  stat['title'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    final weekData = [60, 80, 45, 90, 70, 55, 85];
    final weekDays = [
      'السبت',
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        final animValue = _cardAnimation.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات الأسبوع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(weekData.length, (index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0.0,
                            end: (weekData[index] / 100).clamp(0.0, 1.0),
                          ),
                          duration: Duration(milliseconds: 800 + (index * 100)),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            final animValue = value.clamp(0.0, 1.0);
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 20,
                                  height: (65 * animValue).clamp(0.0, 65.0),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF60A5FA),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  weekDays[index],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Text(
      'آخر تحديث: ${_getArabicTime(_currentTime)}',
      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      textAlign: TextAlign.center,
    );
  }

  String _getArabicDate(DateTime date) {
    final arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final arabicDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return '${arabicDays[date.weekday - 1]}، ${date.day} ${arabicMonths[date.month - 1]} ${date.year}';
  }

  String _getArabicTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getUsageStatus(double progress) {
    if (progress >= 0.9) return 'تجاوزت الحد المسموح';
    if (progress >= 0.7) return 'اقتربت من الحد';
    return 'استخدام معتدل';
  }
}

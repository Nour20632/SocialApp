import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/models/conversation_model.dart';
import 'package:social_app/screens/achievements/achievement_details_screen.dart';
import 'package:social_app/screens/achievements/achievement_screen.dart';
import 'package:social_app/screens/achievements/add_achievement_screen.dart';
import 'package:social_app/screens/achievements/all_achievements_screen.dart';
import 'package:social_app/screens/knowledge/knowledge_screen.dart';
import 'package:social_app/screens/messaging/chat_screen.dart';
import 'package:social_app/screens/messaging/conversations_screen.dart';
import 'package:social_app/screens/messaging/new_conversation_screen.dart';
import 'package:social_app/screens/notifications_screen.dart';
import 'package:social_app/screens/profiles/edit_profile_screen.dart';
import 'package:social_app/screens/profiles/other_user_profile.dart';
import 'package:social_app/screens/profiles/profile_screen.dart';
import 'package:social_app/screens/search_screen.dart';
import 'package:social_app/screens/second_home_screen.dart';
import 'package:social_app/screens/settings/about_screen.dart';
import 'package:social_app/screens/settings/usage_stats_screen.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/services/usage_tracker_service.dart';
import 'package:social_app/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/authentification/login_screen.dart';
import 'screens/authentification/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/posts/comments_screen.dart';
import 'screens/posts/create_post_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/app_life_cycle_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_localizations.dart';
import 'utils/app_settings.dart';
import 'widgets/usage_timer_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التخزين المحلي وضبط حالة التطبيق
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_state', 'foreground');

  // ضبط اتجاه الشاشة للوضع الرأسي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // تهيئة Supabase
    await Supabase.initialize(
      url: 'https://jzinhmgoewgznhbfrypt.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6aW5obWdvZXdnem5oYmZyeXB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1NzU1NDEsImV4cCI6MjA2MTE1MTU0MX0.V2XpOADh02zeTatB9rq4-tZS1uooQtpbP_qJNUKu8g8',
    );
  } catch (e) {
    debugPrint('خطأ في تهيئة Supabase: $e');
  }

  runApp(const SocialApp());
}

class SocialApp extends StatelessWidget {
  const SocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings()),
        Provider<SupabaseClient>.value(value: Supabase.instance.client),
        ChangeNotifierProxyProvider<AppSettings, UnifiedUsageTrackerService>(
          create:
              (context) =>
                  UnifiedUsageTrackerService(Supabase.instance.client, context),
          update: (context, settings, previous) => previous!,
        ),
        Provider<UserService>(
          create: (context) => UserService(Supabase.instance.client),
        ),
        Provider<PostService>(
          create: (context) => PostService(Supabase.instance.client),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLifeCycleService _lifeCycleService;
  bool _isLoading = true;
  bool _isLimitReached = false;
  bool _showUsageTimer = true; // متغير محلي للتحكم في الإظهار

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // تأخير تهيئة الخدمات حتى اكتمال بناء الإطار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    if (!mounted) return;

    _lifeCycleService = AppLifeCycleService(context);
    await _checkUserAndStartTracking();

    // الاستماع للتغييرات في حالة حد الاستخدام
    final usageTracker = Provider.of<UnifiedUsageTrackerService>(
      context,
      listen: false,
    );

    usageTracker.addListener(_onUsageStatusChanged);
  }

  void _onUsageStatusChanged() {
    if (!mounted) return;

    final usageTracker = Provider.of<UnifiedUsageTrackerService>(
      context,
      listen: false,
    );

    setState(() {
      _isLimitReached = usageTracker.isLimitReached;
    });
  }

  Future<void> _checkUserAndStartTracking() async {
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final usageService = Provider.of<UnifiedUsageTrackerService>(
        context,
        listen: false,
      );

      final user = supabase.auth.currentUser;
      if (user != null) {
        final isLimitReached = await usageService.checkLimitReached(user.id);

        if (!mounted) return;
        setState(() {
          _isLimitReached = isLimitReached;
          _isLoading = false;
        });

        if (!isLimitReached) {
          // بدء تتبع الاستخدام إذا لم يتم الوصول للحد الأقصى
          usageService.startTracking(user.id);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في فحص المستخدم وبدء التتبع: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final usageTracker = Provider.of<UnifiedUsageTrackerService>(
      context,
      listen: false,
    );

    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق في الواجهة الأمامية
        await prefs.setString('app_state', 'foreground');
        debugPrint('حالة التطبيق: في الواجهة');

        // إعادة بدء تتبع الاستخدام عند العودة للتطبيق
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null && !usageTracker.isLimitReached) {
          usageTracker.startTracking(currentUser.id);
        }
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // التطبيق في الخلفية
        await prefs.setString('app_state', 'background');
        debugPrint('حالة التطبيق: في الخلفية');

        // إيقاف تتبع الاستخدام عند مغادرة التطبيق
        usageTracker.stopTracking();
        break;
    }
  }

  @override
  void dispose() {
    // إلغاء الاستماع للتغييرات وتنظيف الموارد
    final usageTracker = Provider.of<UnifiedUsageTrackerService>(
      context,
      listen: false,
    );
    usageTracker.removeListener(_onUsageStatusChanged);

    WidgetsBinding.instance.removeObserver(this);
    _lifeCycleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer<AppSettings>(
      builder: (context, appSettings, _) {
        return MaterialApp(
          title: 'Social App',
          theme: AppTheme.seenTheme(context, isArabic: appSettings.isArabic),

          // إعدادات اللغة
          locale: appSettings.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          debugShowCheckedModeBanner: false,
          home:
              _isLimitReached ? const LimitReachedScreen() : _buildHomeScreen(),

          // تعريف المسارات الثابتة
          routes: _buildAppRoutes(context),

          // التعامل مع المسارات الديناميكية
          onGenerateRoute: (settings) => _generateRoutes(settings, context),
        );
      },
    );
  }

  Map<String, Widget Function(BuildContext)> _buildAppRoutes(
    BuildContext context,
  ) {
    return {
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignupScreen(),
      '/home': (context) => const HomeScreen(),
      '/create_post': (context) => const CreatePostScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/search': (context) => const SearchScreen(),
      '/second_home': (context) => const SecondHomeScreen(),
      '/about': (context) => const AboutScreen(),
      '/usage_stats': (context) => const UsageStatisticsScreen(userId: ''),
      '/notifications':
          (context) => NotificationScreen(
            userService: Provider.of<UserService>(context, listen: false),
            postService: Provider.of<PostService>(context, listen: false),
          ),
      '/all_achievements': (context) => AllAchievementsScreen(),
      '/add_achievement': (context) => const AddAchievementScreen(),
      '/conversations': (context) => const ConversationsScreen(),
      '/new_conversation': (context) => const NewConversationScreen(),
      '/chat':
          (context) => ChatScreen(
            conversation:
                ModalRoute.of(context)!.settings.arguments as ConversationModel,
          ),
      '/knowledge': (context) => const KnowledgeScreen(),
      '/create_achievement':
          (context) => const AddAchievementScreen(),
    
    };
  }

  Route<dynamic>? _generateRoutes(
    RouteSettings settings,
    BuildContext context,
  ) {
    switch (settings.name) {
      case '/profile':
        final String userId =
            settings.arguments as String? ??
            Supabase.instance.client.auth.currentUser?.id ??
            '';
        return MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId));

      case '/edit_profile':
        final String userId =
            settings.arguments as String? ??
            Supabase.instance.client.auth.currentUser?.id ??
            '';
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(userId: userId),
        );

      case '/other_profile':
        final String userId = settings.arguments as String;
        return MaterialPageRoute(
          builder:
              (_) => OtherUserProfileScreen(
                userId: userId,
                userService: Provider.of<UserService>(context, listen: false),
                postService: Provider.of<PostService>(context, listen: false),
              ),
        );

      case '/comments':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CommentsScreen(postId: args['postId']),
        );

      case '/achievement_details':
        final String achievementId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) {
            final achievement =
                ModalRoute.of(context)!.settings.arguments as AchievementModel;
            return AchievementDetailsScreen(
              achievement: achievement,
              achievementId: achievementId,
            );
          },
        );
      case '/achievement_screen':
        (context) {
          final achievement =
              ModalRoute.of(context)!.settings.arguments as AchievementModel;
          return AchievementScreen(achievement: achievement);
        };
    }
    return null;
  }

  Widget _buildHomeScreen() {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return const LoginScreen();
      }

      // الصفحة الرئيسية مع مؤقت الاستخدام
      return Consumer<AppSettings>(
        builder: (context, settings, _) {
          final bool showTimerSetting = settings.showUsageTimer;

          return Scaffold(
            // ...existing code...
            body: Column(
              children: [
                if (showTimerSetting)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // زر إظهار/إخفاء المؤقت
                        IconButton(
                          icon: Icon(
                            _showUsageTimer
                                ? Icons
                                    .expand_less // مثلث للأعلى (إخفاء)
                                : Icons.bar_chart, // أيقونة إحصائيات (إظهار)
                            color: Colors.blue,
                          ),
                          tooltip:
                              _showUsageTimer ? 'إخفاء المؤقت' : 'عرض المؤقت',
                          onPressed: () {
                            setState(() {
                              _showUsageTimer = !_showUsageTimer;
                            });
                          },
                        ),
                        // المؤقت نفسه
                        if (_showUsageTimer)
                          const Expanded(
                            child: UsageTimerWidget(compact: true),
                          ),
                      ],
                    ),
                  ),
                Expanded(child: HomeScreen()),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('خطأ في بناء الشاشة الرئيسية: $e');
      return const LoginScreen();
    }
  }
}

class LimitReachedScreen extends StatelessWidget {
  const LimitReachedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        final maxMinutes = settings.maxDailyUsageMinutes;
        final String timeText = _formatTimeForDisplay(maxMinutes);

        // استعلام النصوص المترجمة
        final titleText =
            AppLocalizations.of(context).translate('limit_reached_title');
        final messageText = AppLocalizations.of(
          context,
        ).translate('limit_reached_message');
        final closeButtonText = AppLocalizations.of(
          context,
        ).translate('close_app');

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 24),
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$messageText ($timeText). يرجى العودة غدًا للاستمتاع بالتطبيق مرة أخرى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      closeButtonText,
                      style: const TextStyle(fontSize: 16),
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

  String _formatTimeForDisplay(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;

      if (remainingMinutes == 0) {
        return '$hours hours';
      } else {
        return '$hours hours and $remainingMinutes minutes';
      }
    } else {
      return '$minutes minutes';
    }
  }
}

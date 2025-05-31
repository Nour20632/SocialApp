import 'package:flutter/material.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllAchievementsScreen extends StatelessWidget {
  const AllAchievementsScreen({super.key});

  Future<List<AchievementModel>> fetchAchievements() async {
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('Current user: $user');
    if (user == null) {
      debugPrint('User not logged in');
      return [];
    }
    try {
      final data = await Supabase.instance.client
          .from('achievements')
          .select('*, user:users(*)')
          .order('created_at', ascending: false);
      debugPrint('Fetched achievements: $data');
      return data
          .map<AchievementModel>((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كل الإنجازات')),
      body: FutureBuilder<List<AchievementModel>>(
        future: fetchAchievements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب الإنجازات'));
          }
          if (Supabase.instance.client.auth.currentUser == null) {
            return const Center(child: Text('يرجى تسجيل الدخول أولاً'));
          }
          final achievements = snapshot.data ?? [];
          if (achievements.isEmpty) {
            return const Center(child: Text('لا توجد إنجازات متاحة'));
          }
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return ListTile(
                title: Text(achievement.title),
                subtitle: Text(achievement.description),
              );
            },
          );
        },
      ),
    );
  }
}

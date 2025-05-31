import 'package:flutter/material.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/services/achievement_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementDetailsScreen extends StatefulWidget {
  final String achievementId;

  const AchievementDetailsScreen({
    super.key,
    required this.achievementId,
    required AchievementModel achievement,
  });

  @override
  State<AchievementDetailsScreen> createState() =>
      _AchievementDetailsScreenState();
}

class _AchievementDetailsScreenState extends State<AchievementDetailsScreen> {
  late final AchievementService _achievementService;
  AchievementModel? _achievement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _achievementService = AchievementService(Supabase.instance.client);
    _loadAchievement();
  }

  Future<void> _loadAchievement() async {
    try {
      final achievement = await _achievementService.getAchievementById(
        widget.achievementId,
        context,
      );
      setState(() {
        _achievement = achievement;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل في تحميل الإنجاز')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_achievement == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('لم يتم العثور على الإنجاز')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_achievement!.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_achievement!.imageUrl != null)
              Image.network(
                _achievement!.imageUrl!,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _achievement!.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _achievement!.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التفاصيل', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'تاريخ الإنجاز: ${_achievement!.createdAt.toLocal().toString().split(' ')[0]}',
                              ),
                            ],
                          ),
                          if (_achievement!.completionDate != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تاريخ الإتمام: ${_achievement!.completionDate!.toLocal().toString().split(' ')[0]}',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/screens/settings/usage_stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _cleanupResources() async {
    // Cleanup resources like:
    // - Clear temporary files
    // - Reset state
    // - Close connections
    debugPrint('Cleaning up resources...');
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help'),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('إحصائيات الاستخدام'),
            onTap: () {
              if (currentUserId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => UsageStatisticsScreen(userId: currentUserId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                await supabase.auth.signOut();
                if (!mounted) return;
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                if (!mounted) return;
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (!mounted) return;
                if (mounted) {}
              }
            },
          ),
        ],
      ),
    );
  }
}

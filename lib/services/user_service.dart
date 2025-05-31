import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constants
const Duration _cacheTimeout = Duration(minutes: 15);

// Provider definition
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(Supabase.instance.client);
});

// Cache data class - Moved outside UserService
class _CachedUserData {
  final UserModel user;
  final DateTime timestamp;

  _CachedUserData(this.user) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > _cacheTimeout;
}

class UserService {
  final SupabaseClient _supabase;
  final Map<String, _CachedUserData> _userCache = {};

  UserService(this._supabase);

  // Public getters
  SupabaseClient get supabaseClient => _supabase;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==========================================
  // User Validation Methods
  // ==========================================

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  bool _isValidStatus(UserStatus status) {
    return UserStatus.values.contains(status);
  }

  bool _isValidRole(UserRole role) {
    return UserRole.values.contains(role);
  }

  bool _isValidAccountType(AccountType type) {
    return AccountType.values.contains(type);
  }

  // ==========================================
  // User CRUD Operations
  // ==========================================

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check cache first
      if (_userCache.containsKey(user.id)) {
        final cachedData = _userCache[user.id];
        if (cachedData != null && !cachedData.isExpired) {
          return cachedData.user;
        }
      }

      final userData =
          await _supabase.from('users').select().eq('id', user.id).single();

      final userModel = UserModel.fromJson(userData);

      // Update cache
      _userCache[user.id] = _CachedUserData(userModel);

      return userModel;
    } on PostgrestException catch (e) {
      debugPrint('Database error getting current user: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      rethrow;
    }
  }

  Future<UserModel> getUserById(String userId, BuildContext context) async {
    if (!context.mounted) return UserModel.empty();

    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        final cachedData = _userCache[userId];
        if (cachedData != null && !cachedData.isExpired) {
          return cachedData.user;
        }
      }

      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      if (!context.mounted) return UserModel.empty();

      final user = UserModel.fromJson(response);
      _userCache[userId] = _CachedUserData(user);

      return user;
    } on PostgrestException catch (e) {
      if (!context.mounted) return UserModel.empty();
      debugPrint('Database error getting user: ${e.message}');
      throw Exception(
        AppLocalizations.of(context).translate('error_loading_user'),
      );
    } catch (e) {
      if (!context.mounted) return UserModel.empty();
      debugPrint('Error getting user: $e');
      throw Exception(
        AppLocalizations.of(context).translate('error_loading_user'),
      );
    }
  }

  // ==========================================
  // Profile Management
  // ==========================================

  Future<UserModel> updateProfile({
    required String userId,
    required BuildContext context,
    String? username,
    String? displayName,
    String? bio,
    AccountType? accountType,
    UserStatus? status,
    UserRole? role,
  }) async {
    if (!context.mounted) throw Exception('Context is no longer valid');

    try {
      final l10n = AppLocalizations.of(context);
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate username if provided
      if (username != null) {
        if (!_isValidUsername(username)) {
          throw Exception(l10n.translate('invalid_username_error'));
        }

        // Check username uniqueness
        final existingUser =
            await _supabase
                .from('users')
                .select('id')
                .eq('username', username)
                .neq('id', userId)
                .maybeSingle();

        if (existingUser != null) {
          if (!context.mounted) throw Exception('Context is no longer valid');
          throw Exception(l10n.translate('username_exists_error'));
        }

        updateData['username'] = username;
      }

      // Add other fields if provided
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (accountType != null) updateData['account_type'] = accountType.value;
      if (status != null && _isValidStatus(status)) {
        updateData['status'] = status.value;
      }
      if (role != null && _isValidRole(role)) {
        updateData['role'] = role.value;
      }

      // Update user in database
      final updatedUser =
          await _supabase
              .from('users')
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();

      final userModel = UserModel.fromJson(updatedUser);
      _userCache[userId] = _CachedUserData(userModel);

      return userModel;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // ==========================================
  // العلاقات بين المستخدمين (متابعة، حظر)
  // ==========================================

  // المتابعة: استخدام RPC للمعالجة الآمنة في الخادم
  Future<void> followUser(String followerId, String followingId) async {
    try {
      // استخدام وظيفة RPC لمعالجة المتابعة بشكل آمن
      await _supabase.rpc(
        'create_follow_relationship',
        params: {'p_follower_id': followerId, 'p_following_id': followingId},
      );
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  // دالة جديدة للرد على طلب المتابعة باستخدام RPC
  Future<void> respondToFollowRequest(
    String followId,
    String status, // 'accepted' or 'declined'
  ) async {
    try {
      final action = status == 'accepted' ? 'accept' : 'decline';

      await _supabase.rpc(
        'handle_follow_request',
        params: {'p_follow_id': followId, 'p_action': action},
      );
    } catch (e) {
      debugPrint('Error responding to follow request: $e');
      rethrow;
    }
  }

  // إلغاء المتابعة: استخدام RPC
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabase.rpc(
        'delete_follow_relationship',
        params: {'p_follower_id': followerId, 'p_following_id': followingId},
      );
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      throw Exception('Failed to unfollow user');
    }
  }

  /// التحقق من حالة المتابعة بين مستخدمين
  Future<Map<String, dynamic>> getFollowStatus(
    String followerId,
    String followingId,
  ) async {
    try {
      final result =
          await _supabase
              .from('follows')
              .select()
              .eq('follower_id', followerId)
              .eq('following_id', followingId)
              .maybeSingle();

      return {
        'isFollowing': result != null && result['status'] == 'accepted',
        'isPending': result != null && result['status'] == 'pending',
        'isDeclined': result != null && result['status'] == 'declined',
        'followId': result?['id'],
        'seenAt': result?['seen_at'],
        'notificationSent': result?['notification_sent'] ?? false,
      };
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return {
        'isFollowing': false,
        'isPending': false,
        'isDeclined': false,
        'followId': null,
        'seenAt': null,
        'notificationSent': false,
      };
    }
  }

  /// الحصول على طلبات المتابعة المعلقة
  Future<List<Map<String, dynamic>>> getPendingFollowRequests() async {
    try {
      final requests = await _supabase
          .from('follows')
          .select('''
            *,
            follower:users!follower_id (
              id,
              username,
              display_name,
              profile_image_url,
              is_verified
            )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(requests);
    } catch (e) {
      debugPrint('Error fetching follow requests: $e');
      return [];
    }
  }

  /// تحديث حالة طلب المتابعة
  Future<void> updateFollowRequestStatus(String followId, String status) async {
    try {
      await respondToFollowRequest(followId, status);
    } catch (e) {
      debugPrint('Error updating follow request: $e');
      rethrow;
    }
  }

  /// تحديث حقل seen_at عند رؤية الطلب
  Future<void> markFollowRequestAsSeen(String followId) async {
    try {
      await _supabase
          .from('follows')
          .update({
            'seen_at': DateTime.now().toIso8601String(),
            'notification_sent': true,
          })
          .eq('id', followId);
    } catch (e) {
      debugPrint('Error marking follow request as seen: $e');
    }
  }

  // باقي الدوال بدون تغيير
  // ==========================================
  // إحصائيات المستخدم
  // ==========================================

  // استخدام RPC لإعادة حساب إحصائيات المستخدم
  Future<void> refreshUserStatistics(String userId) async {
    try {
      await _supabase.rpc(
        'recalculate_user_stats',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      debugPrint('Error refreshing user statistics: $e');
    }
  }

  // التحقق مما إذا كان المستخدم أ يتابع المستخدم ب
  Future<bool> checkIfFollowing(String followerId, String followingId) async {
    try {
      final result = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .eq('status', 'accepted'); // تأكد من أن المتابعة مقبولة

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if following: $e');
      return false;
    }
  }

  // الحصول على متابعي المستخدم
  Future<List<UserModel>> getFollowers(String userId, {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('follower:users!follower_id(*)')
          .eq('following_id', userId)
          .eq('status', 'accepted') // تأكد من أن المتابعة مقبولة
          .limit(limit);

      return data
          .map<UserModel>((item) => UserModel.fromJson(item['follower']))
          .toList();
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  // الحصول على المستخدمين الذين يتابعهم المستخدم
  Future<List<UserModel>> getFollowing(String userId, {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('following:users!following_id(*)')
          .eq('follower_id', userId)
          .eq('status', 'accepted') // تأكد من أن المتابعة مقبولة
          .limit(limit);

      return data
          .map<UserModel>((item) => UserModel.fromJson(item['following']))
          .toList();
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  // حظر مستخدم
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      // أولاً، إلغاء متابعة المستخدم إذا كان متابعًا بالفعل
      final isFollowing = await checkIfFollowing(userId, blockedUserId);
      if (isFollowing) {
        await unfollowUser(userId, blockedUserId);
      }

      // أيضًا، إزالة أي متابعة من المستخدم المحظور للمستخدم الحالي
      final isBeingFollowed = await checkIfFollowing(blockedUserId, userId);
      if (isBeingFollowed) {
        await unfollowUser(blockedUserId, userId);
      }

      // الآن قم بحظر المستخدم
      await _supabase.from('blocked_users').insert({
        'user_id': userId,
        'blocked_user_id': blockedUserId,
      });
    } catch (e) {
      debugPrint('Error blocking user: $e');
      throw Exception('Failed to block user: $e');
    }
  }

  // إلغاء حظر مستخدم
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', blockedUserId);
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      throw Exception('Failed to unblock user: $e');
    }
  }

  // التحقق مما إذا كان المستخدم محظورًا
  Future<bool> isUserBlocked(
    String userId,
    String potentiallyBlockedUserId,
  ) async {
    try {
      final result = await _supabase
          .from('blocked_users')
          .select()
          .eq('user_id', userId)
          .eq('blocked_user_id', potentiallyBlockedUserId);

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // الحصول على المستخدمين المحظورين
  Future<List<UserModel>> getBlockedUsers(String userId) async {
    try {
      final data = await _supabase
          .from('blocked_users')
          .select('blocked:users!blocked_user_id(*)')
          .eq('user_id', userId);

      return data
          .map<UserModel>((item) => UserModel.fromJson(item['blocked']))
          .toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  // تحديث صورة الملف الشخصي
  Future<String?> updateProfileImage(
    String userId,
    File imageFile,
    BuildContext context,
  ) async {
    if (!context.mounted) return null;

    try {
      final l10n = AppLocalizations.of(context);

      if (!imageFile.existsSync()) {
        throw Exception(l10n.translate('file_not_found'));
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception(l10n.translate('empty_file'));
      }

      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

      if (!validExtensions.contains(fileExtension)) {
        throw Exception(
          AppLocalizations.of(context).translate('invalidFileType'),
        );
      }

      // Generate unique filename
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Upload file
      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update user profile
      await _supabase
          .from('users')
          .update({'profile_image_url': imageUrl})
          .eq('id', userId);

      return imageUrl;
    } catch (e) {
      if (!context.mounted) return null;
      debugPrint(
        '${AppLocalizations.of(context).translate("image_upload_error")}: $e',
      );
      return null;
    }
  }

  Future<UserModel?> saveProfileChanges({
    required String userId,
    required BuildContext context,
    String? displayName,
    String? bio,
    File? imageFile,
    AccountType? accountType,
  }) async {
    if (!context.mounted) return null;

    try {
      final updateData = <String, dynamic>{};

      // تجميع البيانات المراد تحديثها
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (accountType != null) updateData['account_type'] = accountType.value;

      // التحقق من صحة البيانات قبل الحفظ
      final tempUser = UserModel.fromJson({
        ...updateData,
        'id': userId,
        'username': 'temp', // قيمة مؤقتة للتحقق
        'email': 'temp@email.com', // قيمة مؤقتة للتحقق
      });

      if (!tempUser.isValid) {
        throw Exception(
          AppLocalizations.of(context).translate('invalidProfileData'),
        );
      }

      // معالجة الصورة إذا وجدت
      if (imageFile != null) {
        final imageUrl = await updateProfileImage(userId, imageFile, context);
        if (imageUrl != null) {
          updateData['profile_image_url'] = imageUrl;
        }
      }

      // إذا لم تكن هناك بيانات للتحديث، أعد المستخدم الحالي
      if (updateData.isEmpty) {
        return await getUserById(userId, context);
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final updatedUser =
          await _supabase
              .from('users')
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();

      return UserModel.fromJson(updatedUser);
    } catch (e) {
      if (!context.mounted) return null;
      debugPrint(
        '${AppLocalizations.of(context).translate('errorSavingChanges')}: $e',
      );
      return null;
    }
  }

  // ==========================================
  // إدارة الحساب (تفعيل، تعطيل، الأمان)
  // ==========================================

  // تعطيل الحساب
  Future<void> deactivateAccount(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'status': UserStatus.inactive.value})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error deactivating account: $e');
      throw Exception('Failed to deactivate account: $e');
    }
  }

  // إعادة تفعيل الحساب
  Future<void> reactivateAccount(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'status': UserStatus.active.value})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error reactivating account: $e');
      throw Exception('Failed to reactivate account: $e');
    }
  }

  // التحقق مما إذا كان الحساب نشطًا
  Future<bool> isAccountActive(String userId) async {
    try {
      final userData =
          await _supabase
              .from('users')
              .select('status')
              .eq('id', userId)
              .single();

      return userData['status'] == 'ACTIVE';
    } catch (e) {
      debugPrint('Error checking if account is active: $e');
      return false;
    }
  }

  // تحديث البريد الإلكتروني (يتطلب إعادة المصادقة)
  Future<void> updateEmail(String userId, String newEmail) async {
    try {
      // تحديث في Supabase Auth
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      // تحديث في جدول المستخدمين أيضًا
      await _supabase
          .from('users')
          .update({'email': newEmail})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating email: $e');
      throw Exception('Failed to update email: $e');
    }
  }

  // تحديث كلمة المرور (يتطلب إعادة المصادقة)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  // التحقق من بريد المستخدم
  Future<void> verifyEmail(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_verified': true})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error verifying email: $e');
      throw Exception('Failed to verify email: $e');
    }
  }

  // طلب التحقق من البريد الإلكتروني (يرسل بريدًا للتحقق)
  Future<void> requestEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // استخدام طريقة Supabase لإعادة تعيين البريد الإلكتروني (يجب تمكينها في إعدادات المشروع)
      await _supabase.auth.resetPasswordForEmail(user.email!);
    } catch (e) {
      debugPrint('Error requesting email verification: $e');
      throw Exception('Failed to request email verification: $e');
    }
  }

  // ==========================================
  // دوال التحقق من الصلاحيات
  // ==========================================

  // التحقق مما إذا كان المستخدم يمكنه عرض ملف تعريف آخر
  Future<bool> canViewProfile(String viewerId, String profileId) async {
    try {
      final result = await _supabase.rpc(
        'can_view_profile',
        params: {'viewer_id': viewerId, 'profile_id': profileId},
      );
      return result as bool;
    } catch (e) {
      debugPrint('Error checking profile view permission: $e');
      return false;
    }
  }

  // التحقق مما إذا كان المستخدم يمكنه إرسال رسائل إلى مستخدم آخر
  Future<bool> canMessageUser(String senderId, String recipientId) async {
    try {
      final result = await _supabase.rpc(
        'can_message_user',
        params: {'sender_id': senderId, 'recipient_id': recipientId},
      );
      return result as bool;
    } catch (e) {
      debugPrint('Error checking messaging permission: $e');
      return false;
    }
  }

  // البحث عن المستخدمين الذين لديهم منشورات عامة فقط
  Future<List<UserModel>> searchUsersWithPublicPosts(
    String query, {
    int limit = 20,
  }) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .ilike('username', '%$query%')
          .inFilter('id', await _getUserIdsWithPublicPosts())
          .limit(limit);

      return data.map<UserModel>((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error searching users with public posts: $e');
      return [];
    }
  }

  // Helper: جلب معرفات المستخدمين الذين لديهم منشورات عامة
  Future<List<String>> _getUserIdsWithPublicPosts() async {
    try {
      final posts = await _supabase
          .from('posts')
          .select('author_id')
          .eq('visibility', 'PUBLIC');

      final ids = <String>{};
      for (final post in posts) {
        if (post['author_id'] != null) {
          ids.add(post['author_id'].toString());
        }
      }
      return ids.toList();
    } catch (e) {
      debugPrint('Error getting user ids with public posts: $e');
      return [];
    }
  }

  Future<bool> canViewAchievements(String viewerId, String profileId) async {
    try {
      // Check if viewing own profile
      if (viewerId == profileId) return true;

      // Get user's account type
      final userData = await getCurrentUser(); // Use getCurrentUser instead

      // If account is public, anyone can view achievements
      if (userData?.accountType == AccountType.public) return true;

      // For private accounts, check if viewer is following
      return await checkIfFollowing(viewerId, profileId);
    } catch (e) {
      debugPrint('Error checking achievement view permission: $e');
      return false;
    }
  }

  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    try {
      final data = await _supabase
          .from('achievements')
          .select('*, user:users(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data
          .map<AchievementModel>((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user achievements: $e');
      return [];
    }
  }

  Future<List<UserModel>> getTrendingUsers({int limit = 10}) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('status', UserStatus.active.value)
          .order('follower_count', ascending: false)
          .order('last_active', ascending: false)
          .limit(limit);

      return data.map<UserModel>((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting trending users: $e');
      return [];
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        // استخدام المميزات المحسنة للمستخدمين النشطين حديثاً
        final data = await _supabase
            .from('users')
            .select()
            .eq('status', UserStatus.active.value)
            .neq('id', currentUserId!)
            .gte(
              'last_active',
              DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
            )
            .order('is_verified', ascending: false)
            .order('last_active', ascending: false)
            .limit(15);

        return data.map<UserModel>((item) => UserModel.fromJson(item)).toList();
      }

      // بحث محسن مع ترتيب ذكي
      final data = await _supabase
          .from('users')
          .select()
          .eq('status', UserStatus.active.value)
          .neq('id', currentUserId!)
          .or(
            'username.ilike.%$query%,display_name.ilike.%$query%,bio.ilike.%$query%',
          )
          .order('is_verified', ascending: false)
          .order('follower_count', ascending: false)
          .order('last_active', ascending: false)
          .limit(25);

      final users =
          data.map<UserModel>((item) => UserModel.fromJson(item)).toList();

      // ترتيب إضافي للنتائج الأكثر صلة
      users.sort((a, b) {
        // المستخدمون المتحققون أولاً
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;

        // المطابقة الminuteلاسم المستخدم
        if (a.username.toLowerCase().startsWith(query.toLowerCase())) return -1;
        if (b.username.toLowerCase().startsWith(query.toLowerCase())) return 1;

        // المستخدمون النشطون حديثاً
        if (a.isRecentlyActive && !b.isRecentlyActive) return -1;
        if (!a.isRecentlyActive && b.isRecentlyActive) return 1;

        // عدد المتابعين
        return b.followerCount.compareTo(a.followerCount);
      });

      return users;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }
}

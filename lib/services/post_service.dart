import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:social_app/models/comment_model.dart';
import 'package:social_app/models/media_model.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _supabase;

  PostService(this._supabase);

  // القيم المسموح بها لنوع المنشور
  static const List<String> validPostTypes = [
    'REGULAR',
    'ANNOUNCEMENT',
    'EVENT',
    'POLL',
    'KNOWLEDGE', // Added new type
  ];

  // أنواع الوسائط المدعومة وامتداداتها
  static const Map<String, List<String>> mediaTypeExtensions = {
    'IMAGE': ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
    'VIDEO': ['mp4', 'mov', 'avi', 'wmv', 'mkv', 'webm'],
    'AUDIO': ['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    'DOCUMENT': ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
  };

  // Helper method to get common post selection - FIXED RELATIONSHIP AMBIGUITY

  // تعديل الجزء الخاص بعملية الاختيار في الاستعلامات
  String get _postSelection => '''
  *,
  author:users!posts_author_id_fkey (
    id,
    username,
    display_name,
    profile_image_url
  ),
  media!fk_post(*),
  likes_count:likes(count),
  comments_count:comments!comments_post_id_fkey(count)
''';

  // التحقق من الصلاحيات
  Future<bool> _verifyPostOwnership(String postId, String userId) async {
    try {
      final post =
          await _supabase
              .from('posts')
              .select('author_id')
              .eq('id', postId)
              .maybeSingle();

      if (post == null) {
        throw Exception('Post not found');
      }

      return post['author_id'] == userId;
    } catch (e) {
      debugPrint('Error verifying post ownership: $e');
      throw Exception('Failed to verify post ownership: $e');
    }
  }

  // التحقق من صلاحية نوع المنشور
  bool _isValidPostType(String? typeId) {
    if (typeId == null) return true;
    return validPostTypes.contains(typeId);
  }

  Future<PostModel> createPost({
    required String authorId,
    required String content,
    String visibility = 'PUBLIC',
    String? typeId,
    String? knowledgeDomain, // New parameter
    List<File>? mediaFiles,
  }) async {
    try {
      // التحقق من وجود جلسة نشطة
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session found - please login first');
      }

      // التحقق من مطابقة المستخدم الحالي
      final currentUserId = _supabase.auth.currentUser?.id;
      debugPrint('Current user ID: $currentUserId');
      debugPrint('Author ID: $authorId');

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (currentUserId != authorId) {
        throw Exception(
          'Unauthorized: User mismatch - current user does not match author',
        );
      }

      // التحقق من صلاحية نوع المنشور
      if (typeId != null && !_isValidPostType(typeId)) {
        throw Exception('Invalid post type');
      }

      // Always provide a valid typeId (default to 'REGULAR' if null or invalid)
      final String safeTypeId =
          (typeId != null && validPostTypes.contains(typeId))
              ? typeId
              : 'REGULAR';

      // Validate knowledge domain for KNOWLEDGE posts
      if (safeTypeId == 'KNOWLEDGE') {
        if (knowledgeDomain == null || knowledgeDomain.trim().isEmpty) {
          throw Exception('Knowledge domain is required for knowledge posts');
        }
        if (knowledgeDomain.trim().length < 2) {
          throw Exception('Knowledge domain must be at least 2 characters');
        }
        if (knowledgeDomain.trim().length > 100) {
          throw Exception('Knowledge domain must be less than 100 characters');
        }
      }

      // Create post with knowledge domain
      final postInsertData = {
        'author_id': authorId,
        'content': content,
        'visibility': visibility,
        'type_id': safeTypeId,
        if (safeTypeId == 'KNOWLEDGE' && knowledgeDomain != null)
          'knowledge_domain': knowledgeDomain.trim(),
      };

      final postData =
          await _supabase
              .from('posts')
              .insert(postInsertData)
              .select()
              .single();

      // Increment user's post count after successful post creation
      await _updateUserPostCount(authorId, increment: true);

      final postId = postData['id'] as String;
      if (postId.isEmpty) {
        throw Exception('Failed to get valid post ID');
      }

      // Upload media if any
      List<MediaModel> uploadedMedia = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        uploadedMedia = await _uploadMediaFiles(mediaFiles, postId);
      }

      // استرجاع المنشور الكامل مع الوسائط
      try {
        final fullPost =
            await _supabase
                .from('posts')
                .select(
                  '*, author:users!posts_author_id_fkey(*)',
                ) // <-- هنا التصحيح
                .eq('id', postId)
                .maybeSingle();

        if (fullPost == null) {
          throw Exception('Post not found after creation');
        }

        // تعديل البيانات للتوافق مع PostModel
        final postMap = Map<String, dynamic>.from(fullPost);
        postMap['like_count'] = fullPost['likes_count']?[0]?['count'] ?? 0;
        postMap['comment_count'] =
            fullPost['comments_count']?[0]?['count'] ?? 0;

        return PostModel.fromJson(postMap);
      } catch (e) {
        debugPrint('Error retrieving full post: $e');

        // بديل: استرجاع المنشور بسيط دون العلاقات المتداخلة
        final simplePost =
            await _supabase.from('posts').select().eq('id', postId).single();

        // استرجاع الوسائط منفصلة
        final mediaList =
            uploadedMedia.isNotEmpty
                ? uploadedMedia
                : await _getMediaForPost(postId);

        // إنشاء نموذج المنشور يدويًا
        final postMap = Map<String, dynamic>.from(simplePost);
        postMap['media'] = mediaList.map((m) => m.toJson()).toList();
        postMap['like_count'] = 0;
        postMap['comment_count'] = 0;

        return PostModel.fromJson(postMap);
      }
    } catch (e) {
      debugPrint('Create post error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        debugPrint('Postgrest error details: ${e.details}');
        debugPrint('Postgrest error hint: ${e.hint}');
      }
      rethrow;
    }
  }

  // استرجاع وسائط المنشور
  Future<List<MediaModel>> _getMediaForPost(String postId) async {
    try {
      final mediaData = await _supabase
          .from('media')
          .select()
          .eq('post_id', postId);

      return mediaData
          .map<MediaModel>((data) => MediaModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching media: $e');
      return [];
    }
  }

  // رفع ملفات الوسائط وإنشاء سجلات لها
  Future<List<MediaModel>> _uploadMediaFiles(
    List<File> files,
    String postId,
  ) async {
    final List<MediaModel> uploadedMedia = [];
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) throw Exception('User not authenticated');

    for (final file in files) {
      try {
        final fileExt = file.path.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final storagePath = 'posts/$postId/$fileName';

        // رفع الملف
        await _supabase.storage
            .from('media')
            .upload(
              storagePath,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        // الحصول على الرابط العام
        final url = _supabase.storage.from('media').getPublicUrl(storagePath);
        debugPrint('Media URL: $url');

        // إضافة سجل في جدول الوسائط
        final mediaData =
            await _supabase
                .from('media')
                .insert({
                  'post_id': postId,
                  'url': url,
                  'type': _detectMediaType(file),
                  'storage_path': storagePath,
                })
                .select()
                .single();

        uploadedMedia.add(MediaModel.fromJson(mediaData));
      } catch (e) {
        debugPrint('Error uploading media file: $e');
        // نستمر في محاولة رفع باقي الملفات حتى لو فشل أحدها
      }
    }

    return uploadedMedia;
  }

  // تحديد نوع الوسيط بناءً على امتداد الملف
  String _detectMediaType(File file) {
    final extension = file.path.split('.').last.toLowerCase();

    for (final entry in mediaTypeExtensions.entries) {
      if (entry.value.contains(extension)) {
        return entry.key;
      }
    }

    return 'OTHER';
  }

  // حذف وسيط معين بواسطة معرفه
  Future<void> deleteMedia(String mediaId) async {
    try {
      // التحقق من ملكية المنشور
      final mediaData =
          await _supabase
              .from('media')
              .select('post_id, storage_path')
              .eq('id', mediaId)
              .single();

      final postId = mediaData['post_id'] as String;
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق من أن المستخدم هو مالك المنشور
      final isOwner = await _verifyPostOwnership(postId, currentUserId);
      if (!isOwner) {
        throw Exception('Unauthorized: Not post owner');
      }

      // حذف الملف من التخزين
      final storagePath = mediaData['storage_path'] as String;
      if (storagePath.isNotEmpty) {
        await _supabase.storage.from('media').remove([storagePath]);
      }

      // حذف السجل من قاعدة البيانات
      await _supabase.from('media').delete().eq('id', mediaId);
    } catch (e) {
      debugPrint('Error deleting media: $e');
      throw Exception('Failed to delete media: $e');
    }
  }

  // إضافة وسائط جديدة إلى منشور موجود
  Future<List<MediaModel>> addMediaToPost({
    required String postId,
    required List<File> mediaFiles,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق من أن المستخدم هو مالك المنشور
      final isOwner = await _verifyPostOwnership(postId, currentUserId);
      if (!isOwner) {
        throw Exception('Unauthorized: Not post owner');
      }

      // رفع ملفات الوسائط
      return await _uploadMediaFiles(mediaFiles, postId);
    } catch (e) {
      debugPrint('Error adding media to post: $e');
      throw Exception('Failed to add media to post: $e');
    }
  }

  // Helper method لمعالجة أعداد الإعجابات والتعليقات بشكل موحد
  Map<String, dynamic> _processPostCounts(Map<String, dynamic> post) {
    final postMap = Map<String, dynamic>.from(post);

    // معالجة عدد الإعجابات - الإعجابات تأتي كقائمة تحتوي على عنصر واحد فيه حقل 'count'
    if (post['likes_count'] is List && post['likes_count'].isNotEmpty) {
      postMap['like_count'] = post['likes_count'][0]['count'] ?? 0;
    } else {
      postMap['like_count'] = 0;
    }

    // معالجة عدد التعليقات - التعليقات تأتي كقائمة تحتوي على عنصر واحد فيه حقل 'count'
    if (post['comments_count'] is List && post['comments_count'].isNotEmpty) {
      postMap['comment_count'] = post['comments_count'][0]['count'] ?? 0;
    } else {
      postMap['comment_count'] = 0;
    }

    return postMap;
  }

  // تصحيح دالة getUserPosts
  Future<List<PostModel>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final data = await _supabase
          .from('posts')
          .select('''
          *,
          author:users!posts_author_id_fkey(*),
          media!fk_post(*),
          likes_count:likes(count),
          comments_count:comments!comments_post_id_fkey(count)
        ''')
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return data.map((post) {
        final postMap = _processPostCounts(post);
        return PostModel.fromJson(postMap);
      }).toList();
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      throw Exception('Failed to load user posts: $e');
    }
  }

  // تصحيح دالة getPosts
  Future<List<PostModel>> getPosts({
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      // بناء الاستعلام الأساسي مع التصفية المناسبة
      var query = _supabase.from('posts').select(_postSelection);

      // إضافة عوامل التصفية
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.textSearch(
          'content',
          searchQuery,
          type: TextSearchType.plain,
        );
      }

      // إضافة شروط إضافية مع 'not' أو 'filter'
      query = query.filter('visibility', 'eq', 'PUBLIC');

      // تطبيق الترتيب والصفحات
      final data = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return data.map((post) {
        final postMap = _processPostCounts(post);

        // التحقق من إعجاب المستخدم الحالي
        postMap['user_has_liked'] =
            post['user_has_liked'] != null && post['user_has_liked'].isNotEmpty;

        return PostModel.fromJson(postMap);
      }).toList();
    } catch (e) {
      debugPrint('Failed to load posts: $e');
      throw Exception('Failed to load posts: $e');
    }
  }

  // تصحيح دالة getPost
  Future<PostModel> getPost(String postId, {String? currentUserId}) async {
    try {
      var query = _supabase
          .from('posts')
          .select('''
          *,
          author:users!posts_author_id_fkey(*),
          media!fk_post(*),
          likes_count:likes(count),
          comments_count:comments!comments_post_id_fkey(count)
        ''')
          .eq('id', postId);

      final data = await query.single();
      final postMap = _processPostCounts(data);

      // التحقق من إعجاب المستخدم الحالي إذا تم توفير معرفه
      if (currentUserId != null) {
        final hasLiked =
            await _supabase
                .from('likes')
                .select()
                .eq('post_id', postId)
                .eq('user_id', currentUserId)
                .maybeSingle();

        postMap['user_has_liked'] = hasLiked != null;
      }

      return PostModel.fromJson(postMap);
    } catch (e) {
      debugPrint('Failed to fetch post: $e');
      throw Exception('Failed to fetch post: $e');
    }
  }

  // تصحيح دالة updatePost
  Future<PostModel> updatePost({
    required String postId,
    required String content,
    String? typeId,
    String? visibility,
    String? knowledgeDomain, // New parameter
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق من أن المستخدم هو مالك المنشور
      final isOwner = await _verifyPostOwnership(postId, currentUserId);
      if (!isOwner) {
        throw Exception('Unauthorized: Not post owner');
      }

      // التحقق من صلاحية نوع المنشور
      if (typeId != null && !_isValidPostType(typeId)) {
        throw Exception('Invalid post type');
      }

      // Validate knowledge domain for KNOWLEDGE posts
      if (typeId == 'KNOWLEDGE') {
        if (knowledgeDomain == null || knowledgeDomain.trim().isEmpty) {
          throw Exception('Knowledge domain is required for knowledge posts');
        }
        if (knowledgeDomain.trim().length < 2) {
          throw Exception('Knowledge domain must be at least 2 characters');
        }
        if (knowledgeDomain.trim().length > 100) {
          throw Exception('Knowledge domain must be less than 100 characters');
        }
      }

      final updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (typeId != null) {
        updateData['type_id'] = typeId;

        // Add or remove knowledge domain based on post type
        if (typeId == 'KNOWLEDGE' && knowledgeDomain != null) {
          updateData['knowledge_domain'] = knowledgeDomain.trim();
        } else if (typeId != 'KNOWLEDGE') {
          // Skip setting knowledge_domain if it's not a KNOWLEDGE post
          updateData.remove('knowledge_domain');
        }
      }

      if (visibility != null) {
        updateData['visibility'] = visibility;
      }

      await _supabase.from('posts').update(updateData).eq('id', postId);

      // استرجاع المنشور المحدث
      final updatedPost =
          await _supabase
              .from('posts')
              .select('''
              *,
              author:users!posts_author_id_fkey(*),
              media!fk_post(*),
              likes_count:likes(count),
              comments_count:comments!comments_post_id_fkey(count)
            ''')
              .eq('id', postId)
              .single();

      final postMap = _processPostCounts(updatedPost);
      return PostModel.fromJson(postMap);
    } catch (e) {
      debugPrint('Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // تصحيح دالة getFeed
  Future<List<PostModel>> getFeed(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final followedUsers = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      if (followedUsers.isEmpty) {
        return getUserPosts(userId, page: page, limit: limit);
      }

      final followedUserIds =
          followedUsers.map((row) => row['following_id'].toString()).toList();

      followedUserIds.add(userId);

      final data = await _supabase
          .from('posts')
          .select('''
            *,
            author:users!posts_author_id_fkey(*),
            media!fk_post(*),
            likes_count:likes(count),
            comments_count:comments!comments_post_id_fkey(count)
          ''')
          .inFilter('author_id', followedUserIds)
          .eq('visibility', 'PUBLIC')
          .order('created_at', ascending: false)
          .range(from, to);

      return data.map((post) {
        final postMap = _processPostCounts(post);
        return PostModel.fromJson(postMap);
      }).toList();
    } catch (e) {
      debugPrint('Error loading feed: $e');
      throw Exception('Failed to load feed: $e');
    }
  }

  // تصحيح دالة sharePost
  Future<PostModel> sharePost({
    required String originalPostId,
    required String authorId,
    String? additionalContent,
  }) async {
    try {
      // جلب بيانات المنشور الأصلي
      final originalPost = await getPost(originalPostId);

      // إنشاء منشور جديد مع الإشارة للمنشور الأصلي
      final postData =
          await _supabase
              .from('posts')
              .insert({
                'author_id': authorId,
                'content': additionalContent ?? '',
                'visibility': originalPost.visibility,
                'type_id': originalPost.typeId,
                'shared_post_id': originalPostId,
              })
              .select()
              .single();

      final postId = postData['id'] as String;
      if (postId.isEmpty) {
        throw Exception('Failed to get valid post ID');
      }

      // استرجاع المنشور الجديد مع العلاقات
      final fullPost =
          await _supabase
              .from('posts')
              .select('''
                *,
                author:users!posts_author_id_fkey(*),
                media!fk_post(*),
                likes_count:likes(count),
                comments_count:comments!comments_post_id_fkey(count)
              ''')
              .eq('id', postId)
              .maybeSingle();

      if (fullPost == null) {
        throw Exception('Post not found after sharing');
      }

      final postMap = _processPostCounts(fullPost);
      return PostModel.fromJson(postMap);
    } catch (e) {
      debugPrint('Error sharing post: $e');
      throw Exception('Failed to share post: $e');
    }
  }

  // تصحيح دالة getLastUserPost
  Future<PostModel?> getLastUserPost(String userId) async {
    try {
      final data =
          await _supabase
              .from('posts')
              .select('''
                *,
                author:users!posts_author_id_fkey(*),
                media!fk_post(*),
                likes_count:likes(count),
                comments_count:comments!comments_post_id_fkey(count)
              ''')
              .eq('author_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (data == null) return null;

      final postMap = _processPostCounts(data);
      return PostModel.fromJson(postMap);
    } catch (e) {
      debugPrint('Error getting last user post: $e');
      return null;
    }
  }

  // استرجاع منشورات مستخدم معين - تصحيح

  // الإعجاب بمنشور
  Future<void> likePost(String postId, String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != userId) {
        throw Exception('Unauthorized: User mismatch');
      }

      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error liking post: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  // إلغاء الإعجاب بمنشور
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != userId) {
        throw Exception('Unauthorized: User mismatch');
      }

      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error unliking post: $e');
      throw Exception('Failed to unlike post: $e');
    }
  }

  // التحقق مما إذا كان المستخدم قد أعجب بالمنشور
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final response =
          await _supabase
              .from('likes')
              .select()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if user liked post: $e');
      return false;
    }
  }

  // استرجاع تعليقات منشور - FIXED FK REFERENCE
  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final data = await _supabase
          .from('comments')
          .select('*, user:users!comments_user_id_fkey(*)')
          .eq('post_id', postId)
          .filter('parent_id', 'is', null)
          .order('created_at', ascending: true)
          .range(from, to);

      return data.map((comment) => CommentModel.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('Error loading comments: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  // منطق مشاركة منشور (Share) - تصحيح

  // إضافة تعليق إلى منشور - FIXED FK REFERENCE
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != userId) {
        throw Exception('Unauthorized: User mismatch');
      }

      final commentData = {
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'parent_id': parentId,
      };

      final data =
          await _supabase
              .from('comments')
              .insert(commentData)
              .select('*, user:users!comments_user_id_fkey(*)')
              .single();

      return CommentModel.fromJson(data);
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // حذف منشور
  Future<void> deletePost(String postId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get post author before deletion
      final post =
          await _supabase
              .from('posts')
              .select('author_id')
              .eq('id', postId)
              .single();

      final authorId = post['author_id'] as String;

      // التحقق من أن المستخدم هو مالك المنشور
      final isOwner = await _verifyPostOwnership(postId, currentUserId);

      // التحقق من صلاحيات المسؤول
      final isAdmin = await _isUserAdmin(currentUserId);

      if (!isOwner && !isAdmin) {
        throw Exception('Unauthorized: Not post owner or admin');
      }

      // حذف جميع ملفات الوسائط من التخزين
      await _deleteAllPostMedia(postId);

      // حذف المنشور (سيؤدي إلى حذف السجلات المرتبطة به بفضل CASCADE)
      await _supabase.from('posts').delete().eq('id', postId);

      // Decrement author's post count after successful deletion
      await _updateUserPostCount(authorId, increment: false);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // حذف جميع ملفات وسائط المنشور من التخزين
  Future<void> _deleteAllPostMedia(String postId) async {
    try {
      final mediaData = await _supabase
          .from('media')
          .select('storage_path')
          .eq('post_id', postId);

      if (mediaData.isNotEmpty) {
        final storagePaths =
            mediaData
                .map((item) => item['storage_path'] as String)
                .where((path) => path.isNotEmpty)
                .toList();

        if (storagePaths.isNotEmpty) {
          await _supabase.storage.from('media').remove(storagePaths);
        }
      }
    } catch (e) {
      debugPrint('Error deleting post media files: $e');
      // نستمر حتى لو فشل حذف الملفات
    }
  }

  // التحقق من صلاحيات المسؤول
  Future<bool> _isUserAdmin(String userId) async {
    try {
      final userData =
          await _supabase
              .from('users')
              .select('role')
              .eq('id', userId)
              .single();

      final role = userData['role'] as String;
      return role == 'ADMIN' || role == 'MODERATOR';
    } catch (e) {
      return false;
    }
  }

  // حذف تعليق
  Future<void> deleteComment(String commentId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // التحقق من أن المستخدم هو صاحب التعليق أو صاحب المنشور أو مسؤول
      final commentData =
          await _supabase
              .from('comments')
              .select('user_id, post_id')
              .eq('id', commentId)
              .single();

      final commentUserId = commentData['user_id'] as String;
      final postId = commentData['post_id'] as String;

      // إذا كان المستخدم هو صاحب التعليق، يمكنه حذفه
      if (currentUserId == commentUserId) {
        await _supabase.from('comments').delete().eq('id', commentId);
        return;
      }

      // إذا كان المستخدم هو صاحب المنشور، يمكنه حذف التعليق
      final isPostOwner = await _verifyPostOwnership(postId, currentUserId);
      if (isPostOwner) {
        await _supabase.from('comments').delete().eq('id', commentId);
        return;
      }

      // إذا كان المستخدم مسؤولًا، يمكنه حذف التعليق
      final isAdmin = await _isUserAdmin(currentUserId);
      if (isAdmin) {
        await _supabase.from('comments').delete().eq('id', commentId);
        return;
      }

      throw Exception('Unauthorized: Cannot delete this comment');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  // استرجاع المستخدمين الذين أعجبوا بمنشور
  Future<List<UserModel>> getLikedByUsers(String postId) async {
    try {
      final response = await _supabase
          .from('likes')
          .select('''
            user:users!likes_user_id_fkey (
              id,
              username,
              display_name,
              profile_image_url
            )
          ''')
          .eq('post_id', postId);

      return response.map((like) => UserModel.fromJson(like['user'])).toList();
    } catch (e) {
      debugPrint('Error loading users who liked post: $e');
      throw Exception('Failed to load likes: $e');
    }
  }

  // Helper method to update user's post count
  Future<void> _updateUserPostCount(
    String userId, {
    bool increment = true,
  }) async {
    try {
      await _supabase.rpc(
        'update_user_post_count',
        params: {'user_id': userId, 'increment': increment},
      );
    } catch (e) {
      debugPrint('Error updating post count: $e');
      // Don't throw - this is a non-critical operation
    }
  }

  // Get accurate post count for a user
  Future<int> getUserPostCount(String userId) async {
    try {
      final userData =
          await _supabase
              .from('users')
              .select('post_count')
              .eq('id', userId)
              .single();

      return (userData['post_count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting user post count: $e');
      return 0;
    }
  }

  // New method to get knowledge posts
  Future<List<PostModel>> getKnowledgePosts({
    String? knowledgeDomain,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      var query = _supabase.from('posts').select(_postSelection);

      query = query.eq('type_id', 'KNOWLEDGE');

      if (knowledgeDomain != null && knowledgeDomain.isNotEmpty) {
        query = query.ilike(
          'knowledge_domain',
          '%${knowledgeDomain.toLowerCase()}%',
        );
      }

      final data = await query
          .eq('visibility', 'PUBLIC')
          .order('created_at', ascending: false)
          .range(from, to);

      return data.map((post) {
        final postMap = _processPostCounts(post);
        return PostModel.fromJson(postMap);
      }).toList();
    } catch (e) {
      debugPrint('Failed to load knowledge posts: $e');
      throw Exception('Failed to load knowledge posts: $e');
    }
  }

  // New method to get knowledge domains
  Future<List<String>> getKnowledgeDomains() async {
    try {
      final data = await _supabase
          .from('posts')
          .select('knowledge_domain')
          .eq('type_id', 'KNOWLEDGE')
          .not('knowledge_domain', 'is', null);

      final domains =
          data
              .map((row) => row['knowledge_domain'])
              .where(
                (domain) =>
                    domain != null && domain is String && domain.isNotEmpty,
              )
              .map((domain) => (domain as String).trim().toLowerCase())
              .toSet()
              .toList();

      domains.sort();
      return domains;
    } catch (e) {
      debugPrint('Failed to load knowledge domains: $e');
      return [];
    }
  }

  Future<List<PostModel>> searchPosts({
    String? query,
    String? postType,
    String? knowledgeDomain,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      var supabaseQuery = _supabase.from('posts').select(_postSelection);

      // Apply filters
      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.textSearch(
          'content',
          query,
          type: TextSearchType.plain,
        );
      }

      if (postType != null && postType.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('type_id', postType);
      }

      if (knowledgeDomain != null && knowledgeDomain.isNotEmpty) {
        supabaseQuery = supabaseQuery.ilike(
          'knowledge_domain',
          '%$knowledgeDomain%',
        );
      }

      final data = await supabaseQuery
          .eq('visibility', 'PUBLIC')
          .order('created_at', ascending: false)
          .range(from, to);

      return data.map((post) {
        final postMap = _processPostCounts(post);
        return PostModel.fromJson(postMap);
      }).toList();
    } catch (e) {
      debugPrint('Failed to search posts: $e');
      throw Exception('Failed to search posts: $e');
    }
  }
}

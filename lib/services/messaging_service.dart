import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:social_app/models/conversation_model.dart';
import 'package:social_app/models/message_model.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/encryption_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MessagingService {
  final EncryptionService _encryptionService = EncryptionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = Uuid();

  // الاشتراك في المحادثات - إصلاح المشكلة
  Stream<List<ConversationModel>> getConversations() {
    return _supabase
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', _userId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <ConversationModel>[];

          final conversationIds =
              rows.map((row) => row['conversation_id'] as String).toList();

          final conversations = await _supabase
    .from('conversations')
    .select('id, created_at, updated_at, last_message_at, is_group, group_name, group_image_url, created_by') // <-- التعديل هنا
    .inFilter('id', conversationIds)
    .order('last_message_at', ascending: false);
    // جلب معلومات المستخدمين المنشئين للمحادثات
final createdByUserIds = conversations
    .map((conv) => conv['created_by'] as String)
    .toSet()
    .toList();

final createdByUsers = await _supabase
    .from('users')
    .select('id, username, display_name, profile_image_url')
    .inFilter('id', createdByUserIds);
          // الحصول على أعضاء المحادثات - استخدام inFilter بدلاً من in_
          final membersData = await _supabase
              .from('conversation_members')
              .select('*, user:users(*)')
              .inFilter('conversation_id', conversationIds);

          // الحصول على آخر رسالة لكل محادثة
          final lastMessages = await _supabase
              .from('messages')
              .select('conversation_id, content, created_at, sender_id')
              .inFilter('conversation_id', conversationIds)
              .eq('is_deleted', false)
              .order('created_at', ascending: false);

          // تجميع البيانات
          final result =
              conversations.map((conv) {
                final members =
                    membersData
                        .where((m) => m['conversation_id'] == conv['id'])
                        .map((m) => ConversationMemberModel.fromJson(m))
                        .toList();

                // البحث عن آخر رسالة
                final lastMessage =
                    lastMessages
                        .where((msg) => msg['conversation_id'] == conv['id'])
                        .firstOrNull;

                // إضافة معلومات آخر رسالة إلى بيانات المحادثة
                final conversationData = Map<String, dynamic>.from(conv);
                if (lastMessage != null) {
                  conversationData['last_message_content'] =
                      lastMessage['content'];
                  conversationData['last_message_at'] =
                      lastMessage['created_at'];
                }

                return ConversationModel.fromJson(
                  conversationData,
                  members: members,
                );
              }).toList();

          return result;
        });
  }

  // إنشاء محادثة جديدة - إضافة تحديث last_message_at
  Future<ConversationModel> createConversation({
    required List<String> userIds,
    String? groupName,
    String? groupImageUrl,
    bool isGroup = false,
  }) async {
    // التأكد من أن المستخدم الحالي موجود في القائمة
    if (!userIds.contains(_userId)) {
      userIds.add(_userId);
    }

    // إنشاء محادثة جديدة
    final conversationData =
        await _supabase
            .from('conversations')
            .insert({
              'is_group': isGroup,
              'group_name': groupName,
              'group_image_url': groupImageUrl,
              'created_by': _userId,
              'last_message_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

    final conversationId = conversationData['id'];

    // إنشاء مفتاح تشفير للمحادثة
    await _encryptionService.setConversationKey(conversationId);

    // إضافة الأعضاء
    await Future.wait(
      userIds.map((userId) async {
        return _supabase.from('conversation_members').insert({
          'conversation_id': conversationId,
          'user_id': userId,
          'is_admin': userId == _userId,
          'joined_at': DateTime.now().toIso8601String(),
          'last_read_at': DateTime.now().toIso8601String(),
        });
      }),
    );

    // الحصول على معلومات المستخدمين - استخدام inFilter بدلاً من in_
    final users = await _supabase
        .from('users')
        .select('*')
        .inFilter('id', userIds);

    final members =
        users.map((userData) {
          final user = UserModel.fromJson(userData);
          return ConversationMemberModel(
            conversationId: conversationId,
            user: user,
            joinedAt: DateTime.now(),
            isAdmin: userData['id'] == _userId,
            lastReadAt: DateTime.now(),
          );
        }).toList();

    return ConversationModel.fromJson(conversationData, members: members);
  }

  // الاشتراك في رسائل محادثة معينة - إصلاح التصفية
  Stream<List<MessageModel>> getMessages(String conversationId) {
    // تحديث وقت آخر قراءة
    _updateLastRead(conversationId);

     return _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true)
        .asStream()
        .asyncMap((rows) async {
          final messageList = <MessageModel>[];

          if (rows.isEmpty) return messageList;

          // الحصول على معلومات الوسائط للرسائل
          final messageIds = rows.map((row) => row['id']).toList();
          final mediaData = await _supabase
              .from('message_media')
              .select('*')
              .inFilter('message_id', messageIds);

          // الحصول على معلومات المرسلين
          final senderIds =
              rows.map((row) => row['sender_id']).toSet().toList();
          final sendersData = await _supabase
              .from('users')
              .select('*')
              .inFilter('id', senderIds);

          // تجميع الرسائل مع فك التشفير
          for (final row in rows) {
            // فك تشفير محتوى الرسالة
            String content = row['content'];
            if (row['encrypted'] == true) {
              try {
                content = await _encryptionService
                    .decryptMessageForConversation(content, conversationId);
              } catch (e) {
                print('خطأ في فك التشفير: $e');
                content = 'رسالة مشفرة';
              }
            }

            // الحصول على معلومات المرسل
            final senderData =
                sendersData
                    .where((user) => user['id'] == row['sender_id'])
                    .firstOrNull;

            if (senderData == null) continue;

            final sender = UserModel.fromJson(senderData);

            // معالجة الوسائط المرفقة
            final messageMedia =
                mediaData
                    .where((media) => media['message_id'] == row['id'])
                    .map((media) => MessageMediaModel.fromJson(media))
                    .toList();

            // إضافة الرسالة إلى القائمة
            messageList.add(
              MessageModel.fromJson(
                {...row, 'content': content},
                sender: sender,
                media: messageMedia,
                currentUserId: _userId,
              ),
            );
          }

          return messageList;
        });
  }

  // إرسال رسالة جديدة - إضافة تحديث last_message_at للمحادثة
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    List<File>? mediaFiles,
  }) async {
    // تشفير محتوى الرسالة
    final encryptedContent = await _encryptionService
        .encryptMessageForConversation(content, conversationId);

    // إنشاء الرسالة
    final messageData =
        await _supabase
            .from('messages')
            .insert({
              'conversation_id': conversationId,
              'sender_id': _userId,
              'content': encryptedContent,
              'encrypted': true,
              'reply_to_id': replyToId,
            })
            .select()
            .single();

    // تحديث وقت آخر رسالة في المحادثة
    await _supabase
        .from('conversations')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    // معالجة الملفات المرفقة إذا وجدت
    List<MessageMediaModel> mediaModels = [];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      await Future.wait(
        mediaFiles.map((file) async {
          // تحديد نوع الوسائط
          String mediaType;
          final ext = path.extension(file.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
            mediaType = 'IMAGE';
          } else if (['.mp4', '.mov', '.avi', '.webm'].contains(ext)) {
            mediaType = 'VIDEO';
          } else if (['.mp3', '.wav', '.ogg', '.m4a'].contains(ext)) {
            mediaType = 'AUDIO';
          } else {
            mediaType = 'DOCUMENT';
          }

          // إنشاء مسار التخزين
          final filename = '${_uuid.v4()}$ext';
          final storagePath =
              'messages/$conversationId/${messageData['id']}/$filename';

          // رفع الملف
          await _supabase.storage.from('media').upload(storagePath, file);

          // الحصول على URL الملف
          final fileUrl = _supabase.storage
              .from('media')
              .getPublicUrl(storagePath);

          // إضافة سجل الوسائط
          final mediaData =
              await _supabase
                  .from('message_media')
                  .insert({
                    'message_id': messageData['id'],
                    'url': fileUrl,
                    'type': mediaType,
                    'storage_path': storagePath,
                  })
                  .select()
                  .single();

          mediaModels.add(MessageMediaModel.fromJson(mediaData));
        }),
      );
    }

    // تحديث وقت آخر قراءة
    await _updateLastRead(conversationId);

    // الحصول على معلومات المرسل
    final senderData =
        await _supabase.from('users').select('*').eq('id', _userId).single();

    final sender = UserModel.fromJson(senderData);

    return MessageModel.fromJson(
      {...messageData, 'content': content},
      sender: sender,
      currentUserId: _userId,
      media: mediaModels,
    );
  }

  // تعليم الرسالة كمقروءة
  Future<void> markAsRead(String conversationId) async {
    await _updateLastRead(conversationId);
  }

  // حذف رسالة
  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId)
        .eq('sender_id', _userId);
  }

  // إضافة مستخدمين إلى محادثة جماعية
  Future<void> addUsersToConversation(
    String conversationId,
    List<String> userIds,
  ) async {
    // التحقق من أن المحادثة جماعية
    final conversation =
        await _supabase
            .from('conversations')
            .select('is_group')
            .eq('id', conversationId)
            .single();

    if (conversation['is_group'] != true) {
      throw Exception('لا يمكن إضافة مستخدمين إلى محادثة غير جماعية');
    }

    // التحقق من أن المستخدم الحالي مسؤول
    final membership =
        await _supabase
            .from('conversation_members')
            .select('is_admin')
            .eq('conversation_id', conversationId)
            .eq('user_id', _userId)
            .single();

    if (membership['is_admin'] != true) {
      throw Exception('ليس لديك صلاحية إضافة مستخدمين');
    }

    // إضافة المستخدمين
    await Future.wait(
      userIds.map((userId) async {
        return _supabase.from('conversation_members').upsert({
          'conversation_id': conversationId,
          'user_id': userId,
          'is_admin': false,
          'joined_at': DateTime.now().toIso8601String(),
          'last_read_at': DateTime.now().toIso8601String(),
        });
      }),
    );
  }

  // إزالة مستخدم من محادثة جماعية
  Future<void> removeUserFromConversation(
    String conversationId,
    String userId,
  ) async {
    // التحقق من أن المحادثة جماعية
    final conversation =
        await _supabase
            .from('conversations')
            .select('is_group')
            .eq('id', conversationId)
            .single();

    if (conversation['is_group'] != true) {
      throw Exception('لا يمكن إزالة مستخدمين من محادثة غير جماعية');
    }

    // التحقق من أن المستخدم الحالي مسؤول أو أنه يزيل نفسه
    if (userId != _userId) {
      final membership =
          await _supabase
              .from('conversation_members')
              .select('is_admin')
              .eq('conversation_id', conversationId)
              .eq('user_id', _userId)
              .single();

      if (membership['is_admin'] != true) {
        throw Exception('ليس لديك صلاحية إزالة مستخدمين');
      }
    }

    // إزالة المستخدم
    await _supabase
        .from('conversation_members')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  // دالة مساعدة للتحقق من وجود محادثة بين مستخدمين
  Future<ConversationModel?> findDirectConversation(String otherUserId) async {
    try {
      // البحث عن محادثة خاصة بين المستخدمين
      final result = await _supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', _userId);

      if (result.isEmpty) return null;

      final myConversationIds =
          result.map((row) => row['conversation_id']).toList();

      // البحث عن المحادثات التي يشارك فيها المستخدم الآخر
      final otherUserConversations = await _supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', otherUserId)
          .inFilter('conversation_id', myConversationIds);

      if (otherUserConversations.isEmpty) return null;

      final sharedConversationIds =
          otherUserConversations.map((row) => row['conversation_id']).toList();

      // البحث عن المحادثة غير الجماعية
      final conversations = await _supabase
          .from('conversations')
          .select('*')
          .inFilter('id', sharedConversationIds)
          .eq('is_group', false);

      if (conversations.isEmpty) return null;

      // العثور على المحادثة التي تحتوي على مستخدمين فقط
      for (final conv in conversations) {
        // استخدام length بدلاً من count
        final members = await _supabase
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', conv['id']);

        if (members.length == 2) {
          // الحصول على الأعضاء
          final membersData = await _supabase
              .from('conversation_members')
              .select('*, user:users(*)')
              .eq('conversation_id', conv['id']);

          final membersList =
              membersData
                  .map((m) => ConversationMemberModel.fromJson(m))
                  .toList();

          return ConversationModel.fromJson(conv, members: membersList);
        }
      }

      return null;
    } catch (e) {
      print('خطأ في البحث عن المحادثة المباشرة: $e');
      return null;
    }
  }

  String get _userId => _supabase.auth.currentUser?.id ?? '';

  // تحديث وقت آخر قراءة
  Future<void> _updateLastRead(String conversationId) async {
    try {
      await _supabase
          .from('conversation_members')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', _userId);
    } catch (e) {
      print('خطأ في تحديث وقت القراءة: $e');
    }
  }
}

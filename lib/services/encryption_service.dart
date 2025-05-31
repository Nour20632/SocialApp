import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyName = 'message_encryption_key';
  static const _ivName = 'message_encryption_iv';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _defaultKey =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'; // 32 bytes
  static const String _defaultIv = 'ABCDEFGHIJKLMNOP'; // 16 bytes

  Future<Encrypter> _getEncrypter() async {
    String keyStr = await _secureStorage.read(key: _keyName) ?? _defaultKey;
    
    final key =
        _isValidBase64(keyStr) ? Key.fromBase64(keyStr) : Key.fromUtf8(keyStr);
    return Encrypter(AES(key, mode: AESMode.cbc));
  }

  Future<IV> _getIV() async {
    String ivStr = await _secureStorage.read(key: _ivName) ?? _defaultIv;
    // استخدم fromBase64 إذا كان ivStr يبدو base64 وإلا fromUtf8 (للتوافق)
    return _isValidBase64(ivStr) ? IV.fromBase64(ivStr) : IV.fromUtf8(ivStr);
  }

  // تهيئة المفاتيح عند أول استخدام أو إعادة تعيينها
  Future<void> initializeKeys({bool reset = false}) async {
    if (reset || await _secureStorage.read(key: _keyName) == null) {
      // إنشاء مفتاح جديد وحفظه
      final key = Key.fromSecureRandom(32);
      await _secureStorage.write(key: _keyName, value: key.base64);
    }

    if (reset || await _secureStorage.read(key: _ivName) == null) {
      // إنشاء IV جديد وحفظه
      final iv = IV.fromSecureRandom(16);
      await _secureStorage.write(key: _ivName, value: iv.base64);
    }
  }

  // تشفير رسالة
  Future<String> encryptMessage(String message) async {
    try {
      await initializeKeys();
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      final encrypted = encrypter.encrypt(message, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('Error encrypting message: $e');
      // في حالة الفشل، نعيد الرسالة كما هي مع علامة
      return '[UNENCRYPTED]:$message';
    }
  }

  // فك تشفير رسالة
  Future<String> decryptMessage(String encryptedMessage) async {
    try {
      // التحقق من ما إذا كانت الرسالة غير مشفرة أو نص عادي
      if (encryptedMessage.startsWith('[UNENCRYPTED]:')) {
        return encryptedMessage.substring(14);
      }
      // إذا لم تكن Base64 صحيحة، نعيد النص كما هو
      if (!_isValidBase64(encryptedMessage)) {
        return encryptedMessage;
      }
      await initializeKeys();
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      final encrypted = Encrypted.fromBase64(encryptedMessage);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Error decrypting message: $e');
      // في حالة الفشل نعرض الرسالة كما هي
      return encryptedMessage;
    }
  }

  // دالة مساعدة أفضل للتحقق من base64
  bool _isValidBase64(String str) {
    try {
      if (str.isEmpty || str.length % 4 != 0) return false;
      final base64Regex = RegExp(r'^[a-zA-Z0-9+/]*={0,2}$');
      return base64Regex.hasMatch(str);
    } catch (_) {
      return false;
    }
  }

  // إنشاء مفتاح مشترك (نموذجي) بناءً على معرف المحادثة
  // هذه طريقة بسيطة، وللتطبيقات الفعلية قد تحتاج إلى نهج أكثر أمانًا
  Future<void> setConversationKey(
    String conversationId, {
    String? sharedKey,
  }) async {
    final keyNameForConversation = '${_keyName}_$conversationId';
    final ivNameForConversation = '${_ivName}_$conversationId';

    if (sharedKey != null) {
      // استخدام المفتاح المشترك المقدم
      await _secureStorage.write(key: keyNameForConversation, value: sharedKey);
    } else {
      // إنشاء مفتاح جديد
      final key = Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: keyNameForConversation,
        value: key.base64,
      );
    }

    // إنشاء IV جديد
    final iv = IV.fromSecureRandom(16);
    await _secureStorage.write(key: ivNameForConversation, value: iv.base64);
  }

  // الحصول على المفتاح الخاص بمحادثة معينة
  Future<String?> getConversationKey(String conversationId) async {
    final keyNameForConversation = '${_keyName}_$conversationId';
    return await _secureStorage.read(key: keyNameForConversation);
  }

  // تشفير رسالة باستخدام مفتاح محادثة محدد
  Future<String> encryptMessageForConversation(
    String message,
    String conversationId,
  ) async {
    try {
      final keyNameForConversation = '${_keyName}_$conversationId';
      final ivNameForConversation = '${_ivName}_$conversationId';

      // التحقق من وجود مفتاح للمحادثة، وإلا استخدام المفتاح الافتراضي
      String? keyStr = await _secureStorage.read(key: keyNameForConversation);
      String? ivStr = await _secureStorage.read(key: ivNameForConversation);

      if (keyStr == null || ivStr == null) {
        // إذا لم يكن هناك مفتاح محدد للمحادثة، نستخدم المفتاح العام
        return await encryptMessage(message);
      }

      final key =
          _isValidBase64(keyStr)
              ? Key.fromBase64(keyStr)
              : Key.fromUtf8(keyStr);
      final iv =
          _isValidBase64(ivStr) ? IV.fromBase64(ivStr) : IV.fromUtf8(ivStr);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final encrypted = encrypter.encrypt(message, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('Error encrypting message for conversation: $e');
      return '[UNENCRYPTED]:$message';
    }
  }

  // فك تشفير رسالة باستخدام مفتاح محادثة محدد
  Future<String> decryptMessageForConversation(
    String encryptedMessage,
    String conversationId,
  ) async {
    try {
      // التحقق من ما إذا كانت الرسالة غير مشفرة
      if (encryptedMessage.startsWith('[UNENCRYPTED]:')) {
        return encryptedMessage.substring(14);
      }
      // إذا لم تكن Base64 صحيحة، نعيد النص كما هو
      if (!_isValidBase64(encryptedMessage)) {
        return encryptedMessage;
      }

      final keyNameForConversation = '${_keyName}_$conversationId';
      final ivNameForConversation = '${_ivName}_$conversationId';

      // التحقق من وجود مفتاح للمحادثة، وإلا استخدام المفتاح الافتراضي
      String? keyStr = await _secureStorage.read(key: keyNameForConversation);
      String? ivStr = await _secureStorage.read(key: ivNameForConversation);

      if (keyStr == null || ivStr == null) {
        // إذا لم يكن هناك مفتاح محدد للمحادثة، نستخدم المفتاح العام
        return await decryptMessage(encryptedMessage);
      }

      final key =
          _isValidBase64(keyStr)
              ? Key.fromBase64(keyStr)
              : Key.fromUtf8(keyStr);
      final iv =
          _isValidBase64(ivStr) ? IV.fromBase64(ivStr) : IV.fromUtf8(ivStr);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final encrypted = Encrypted.fromBase64(encryptedMessage);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Error decrypting message for conversation: $e');
      return encryptedMessage;
    }
  }
}

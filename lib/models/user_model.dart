import 'package:equatable/equatable.dart';

/// نموذج المستخدم الشامل مع جميع التحسينات والمعالجات
class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final bool isVerified;
  final UserStatus status;
  final UserRole role;
  final AccountType accountType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActive;
  final int postCount;
  final int followerCount;
  final int followingCount;

  // حقول إضافية لواجهة المستخدم
  final bool? isFollowing;
  final bool? isFollowedBy;
  final bool? hasUnreadMessages;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    required this.isVerified,
    required this.status,
    required this.role,
    required this.accountType,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
    this.postCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowing,
    this.isFollowedBy,
    this.hasUnreadMessages,
  });

  /// إنشاء مستخدم فارغ للحالات الافتراضية
  factory UserModel.empty() {
    return UserModel(
      id: '',
      username: '',
      email: '',
      displayName: '',
      isVerified: false,
      status: UserStatus.inactive,
      role: UserRole.user,
      accountType: AccountType.public,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  /// إنشاء مستخدم من JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: _parseString(json['id']),
        username: _parseString(json['username']),
        email: _parseString(json['email']),
        displayName: _parseString(json['display_name']),
        bio: json['bio']?.toString(),
        profileImageUrl: json['profile_image_url']?.toString(),
        isVerified: _parseBool(json['is_verified']),
        status: UserStatus.fromString(_parseString(json['status'], 'ACTIVE')),
        role: UserRole.fromString(_parseString(json['role'], 'USER')),
        accountType: AccountType.fromString(
          _parseString(json['account_type'], 'PUBLIC'),
        ),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
        lastActive: _parseDateTime(json['last_active']),
        postCount: _parseInt(json['post_count']),
        followerCount: _parseInt(json['follower_count']),
        followingCount: _parseInt(json['following_count']),
        isFollowing:
            json['is_following'] != null
                ? _parseBool(json['is_following'])
                : null,
        isFollowedBy:
            json['is_followed_by'] != null
                ? _parseBool(json['is_followed_by'])
                : null,
        hasUnreadMessages:
            json['has_unread_messages'] != null
                ? _parseBool(json['has_unread_messages'])
                : null,
      );
    } catch (e) {
      throw FormatException('خطأ في تحويل JSON إلى UserModel: $e');
    }
  }

  /// تحويل إلى JSON للعرض (يشمل جميع الحقول)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'is_verified': isVerified,
      'status': status.value,
      'role': role.value,
      'account_type': accountType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'post_count': postCount,
      'follower_count': followerCount,
      'following_count': followingCount,
      if (isFollowing != null) 'is_following': isFollowing,
      if (isFollowedBy != null) 'is_followed_by': isFollowedBy,
      if (hasUnreadMessages != null) 'has_unread_messages': hasUnreadMessages,
    };
  }

  /// تحويل إلى JSON لقاعدة البيانات (بدون الحقول الإضافية)
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'is_verified': isVerified,
      'status': status.value,
      'role': role.value,
      'account_type': accountType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'post_count': postCount,
      'follower_count': followerCount,
      'following_count': followingCount,
    };
  }

  /// إنشاء نسخة محدثة من المستخدم
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    bool? isVerified,
    UserStatus? status,
    UserRole? role,
    AccountType? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    int? postCount,
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
    bool? isFollowedBy,
    bool? hasUnreadMessages,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }

  // ===================== Getters =====================

  /// التحقق من نشاط المستخدم
  bool get isActive => status == UserStatus.active;

  /// التحقق من أن المستخدم مشرف
  bool get isAdmin => role == UserRole.admin;

  /// التحقق من أن المستخدم مشرف أو مدير
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;

  /// التحقق من أن الحساب خاص
  bool get isPrivate => accountType == AccountType.private;

  /// التحقق من النشاط الأخير (خلال 15 دقيقة)
  bool get isRecentlyActive {
    final fifteenMinutesAgo = DateTime.now().subtract(
      const Duration(minutes: 15),
    );
    return lastActive.isAfter(fifteenMinutesAgo);
  }

  /// التحقق من النشاط اليوم
  bool get isActiveToday {
    final today = DateTime.now();
    return lastActive.year == today.year &&
        lastActive.month == today.month &&
        lastActive.day == today.day;
  }

  /// الحصول على مدة انقطاع المستخدم
  Duration get inactiveDuration => DateTime.now().difference(lastActive);

  /// التحقق من صحة بيانات المستخدم
  bool get isValid {
    return id.isNotEmpty &&
        username.length >= 3 &&
        email.contains('@') &&
        displayName.isNotEmpty &&
        _isValidEmail(email);
  }

  /// الحصول على اسم العرض المختصر (أول 20 حرف)
  String get shortDisplayName {
    return displayName.length > 20
        ? '${displayName.substring(0, 20)}...'
        : displayName;
  }

  /// تحديد لون الحالة
  String get statusColor {
    switch (status) {
      case UserStatus.active:
        return '#4CAF50'; // أخضر
      case UserStatus.inactive:
        return '#9E9E9E'; // رمادي
      case UserStatus.suspended:
        return '#FF9800'; // برتقالي
      case UserStatus.banned:
        return '#F44336'; // أحمر
    }
  }

  // ===================== Helper Methods =====================

  /// دوال مساعدة لتحليل البيانات
  static String _parseString(dynamic value, [String defaultValue = '']) {
    return value?.toString() ?? defaultValue;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  // ===================== Equatable =====================

  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, displayName: $displayName)';
}

// ===================== Enums =====================

/// حالات المستخدم
enum UserStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  suspended('SUSPENDED'),
  banned('BANNED');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'INACTIVE':
        return UserStatus.inactive;
      case 'SUSPENDED':
        return UserStatus.suspended;
      case 'BANNED':
        return UserStatus.banned;
      default:
        throw ArgumentError('حالة مستخدم غير صحيحة: $value');
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'نشط';
      case UserStatus.inactive:
        return 'غير نشط';
      case UserStatus.suspended:
        return 'معلق';
      case UserStatus.banned:
        return 'محظور';
    }
  }
}

/// أدوار المستخدم
enum UserRole {
  user('USER'),
  moderator('MODERATOR'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return UserRole.user;
      case 'MODERATOR':
        return UserRole.moderator;
      case 'ADMIN':
        return UserRole.admin;
      default:
        throw ArgumentError('دور مستخدم غير صحيح: $value');
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'مستخدم';
      case UserRole.moderator:
        return 'مشرف';
      case UserRole.admin:
        return 'مدير';
    }
  }

  /// ترتيب الأولوية للأدوار
  int get priority {
    switch (this) {
      case UserRole.user:
        return 1;
      case UserRole.moderator:
        return 2;
      case UserRole.admin:
        return 3;
    }
  }
}

/// أنواع الحسابات
enum AccountType {
  public('PUBLIC'),
  private('PRIVATE');

  const AccountType(this.value);
  final String value;

  static AccountType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PUBLIC':
        return AccountType.public;
      case 'PRIVATE':
        return AccountType.private;
      default:
        throw ArgumentError('نوع حساب غير صحيح: $value');
    }
  }

  String get displayName {
    switch (this) {
      case AccountType.public:
        return 'عام';
      case AccountType.private:
        return 'خاص';
    }
  }
}

// ===================== Extensions =====================

/// امتدادات مفيدة لقائمة المستخدمين
extension UserListExtensions on List<UserModel> {
  /// ترشيح المستخدمين النشطين فقط
  List<UserModel> get activeUsers => where((user) => user.isActive).toList();

  /// ترشيح المشرفين
  List<UserModel> get moderators => where((user) => user.isModerator).toList();

  /// ترشيح المستخدمين المتصلين حديثاً
  List<UserModel> get recentlyActiveUsers =>
      where((user) => user.isRecentlyActive).toList();

  /// البحث بالاسم أو اسم المستخدم
  List<UserModel> searchByName(String query) {
    final lowercaseQuery = query.toLowerCase();
    return where(
      (user) =>
          user.displayName.toLowerCase().contains(lowercaseQuery) ||
          user.username.toLowerCase().contains(lowercaseQuery),
    ).toList();
  }

  /// ترتيب حسب آخر نشاط
  List<UserModel> sortByLastActive() {
    final sorted = List<UserModel>.from(this);
    sorted.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    return sorted;
  }

  /// ترتيب حسب عدد المتابعين
  List<UserModel> sortByFollowerCount() {
    final sorted = List<UserModel>.from(this);
    sorted.sort((a, b) => b.followerCount.compareTo(a.followerCount));
    return sorted;
  }
}

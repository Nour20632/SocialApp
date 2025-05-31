// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isArabic => locale.languageCode == 'ar';

  /// Dynamic translation lookup by key (returns only String values)
  String translate(String key) {
    final lang = locale.languageCode;
    final value = _localizedValues[lang]?[key];
    if (value is String) return value;
    // fallback to English if not found or not a String
    final enValue = _localizedValues['en']?[key];
    if (enValue is String) return enValue;
    // fallback to key itself
    return key;
  }

  // Remove 'const' from the map and allow function values for dynamic translations
  static final Map<String, Map<String, dynamic>> _localizedValues = {
    'en': {
      // App basics
      'appName': 'Seen',
      'home': 'Home',
      'search': 'Search',
      'messages': 'Messages',
      'profile': 'Profile',
      'settings': 'Settings',
      'unknown': 'Unknown',

      // Navigation
      'navigationError': 'Navigation error occurred. Please try again.',

      // General UI
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'follow': 'Follow',
      'unblock': 'Unblock',
      'notAvailable': 'Not Available',
      'okButton': 'OK',

      // Theme and language
      'language': 'Language',
      'theme': 'Theme',
      'english': 'English',
      'arabic': 'العربية',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',

      // Posts and content
      'posts': 'Posts',
      'createPost': 'Create Post',
      'noPostsYet': 'No posts yet',
      'noPhotosYet': 'No photos yet',
      'noSavedPosts': 'No saved posts yet',
      'addStory': 'Add Story',
      'like': 'Like',
      'comment': 'Comment',
      'share': 'Share',
      'confirmDelete': 'Confirm Delete',
      'confirmDeletePostMessage': 'Are you sure you want to delete this post?',
      'postDeleted': 'Post deleted successfully',
      'failedToDeletePost': 'Failed to delete post',
      'failedToLoadPosts': 'Failed to load posts',
      'failedToUpdateLike': 'Failed to update like status. Please try again.',

      // Time indicators
      'justNow': 'just now',
      'minutesAgo': 'min',
      'hoursAgo': 'h',
      'daysAgo': 'd',
      'monthsAgo': 'm',
      'yearsAgo': 'y',
      'lastActive': 'Last Active',

      // User profiles
      'follows': 'follows',
      'following': 'Following',
      'editProfile': 'Edit Profile',
      'save': 'Save',
      'displayName': 'Display Name',
      'bio': 'Bio',
      'publicAccount': 'Public Account',
      'privateAccount': 'Private Account',
      'failedToLoadUserData': 'Failed to load user data',
      'failedToLoadProfile': 'Failed to load profile',
      'failedToFollowUser': 'Failed to follow user',
      'failedToUnfollowUser': 'Failed to unfollow user',

      // User actions
      'blockUser': 'Block User',
      'unblockUser': 'Unblock User',
      'reportUser': 'Report User',
      'userBlocked': 'User blocked successfully',
      'failedToBlockUser': 'Failed to block user',
      'userUnblocked': 'User unblocked successfully',
      'failedToUnblockUser': 'Failed to unblock user',

      // General errors
      'generalError': 'An error occurred. Please try again',

      // Auth - Login/Signup
      'login': 'Login',
      'signup': 'Signup',
      'logOut': 'Log Out',
      'logoutFailed': 'Failed to log out. Please try again',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': "Don't have an account?",
      'forgotPassword': 'Forgot password?',
      'resetPassword': 'Reset Password',
      'enterEmailForReset': 'Enter your email to receive a password reset link',
      'sendLink': 'Send Link',
      'resetLinkSent': 'Password reset link sent to your email',
      'createAccount': 'Create Account',
      'enterEmail': 'Enter your email',
      'createPassword': 'Create a password',
      'confirmPassword': 'Confirm your password',
      'accountCreatedSuccess':
          'Account created successfully! Please check your email to verify your account.',
      'accountCreatedSuccessfully': 'Account created successfully!',
      'emailVerificationSentTo': 'Verification email sent to',
      'usernameExistsError':
          'This username is already in use. Please try another one.',
      'invalidUsernameError':
          'Invalid username. Please choose a valid username.',
      'notAuthenticatedError': 'You are not authenticated. Please log in.',
        'limit_reached_title': 'Daily Usage Limit Reached',
      'limit_reached_message': 'You have reached your daily usage limit',
      'close_app': 'Close App',
      'return_tomorrow': 'Please come back tomorrow to enjoy the app again',
      'hide_timer': 'Hide Timer',
      'show_timer': 'Show Timer',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',

      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
  
      'add': 'Add',
   
      'notifications': 'Notifications',

      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'update': 'Update',
    
      'copy': 'Copy',
      'paste': 'Paste',
      'select_all': 'Select All',
      'clear': 'Clear',
      'help': 'Help',
      'about': 'About',
      'version': 'Version',
 
      'privacy': 'Privacy',
      'terms': 'Terms of Service',
      'support': 'Support',
      'feedback': 'Feedback',
      'rate_app': 'Rate App',
      'logout': 'Logout',
 
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'remember_me': 'Remember Me',
      'username': 'Username',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'date_of_birth': 'Date of Birth',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      
      'location': 'Location',
      'website': 'Website',
      'social_media': 'Social Media',
      'achievements': 'Achievements',
      'statistics': 'Statistics',
      'activity': 'Activity',
      'friends': 'Friends',
      'followers': 'Followers',

      'comments': 'Comments',
      'likes': 'Likes',
      'shares': 'Shares',
      'views': 'Views',
      'create_post': 'Create Post',
      'new_post': 'New Post',
      'edit_post': 'Edit Post',
      'delete_post': 'Delete Post',
      'publish': 'Publish',
      'draft': 'Draft',
      'schedule': 'Schedule',
      'tag_friends': 'Tag Friends',
      'add_location': 'Add Location',
      'add_photo': 'Add Photo',
      'add_video': 'Add Video',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'record_video': 'Record Video',
      'select_image': 'Select Image',
      'take_photo': 'Take Photo',
      'crop_image': 'Crop Image',
      'apply_filter': 'Apply Filter',
      'message': 'Message',
      'send_message': 'Send Message',
      'new_message': 'New Message',
      'conversations': 'Conversations',
      'chat': 'Chat',
      'call': 'Call',
      'video_call': 'Video Call',
      'voice_message': 'Voice Message',
      'send_photo': 'Send Photo',
      'send_video': 'Send Video',
      'send_file': 'Send File',
      'typing': 'Typing...',
      'online': 'Online',
      'offline': 'Offline',
      'last_seen': 'Last seen',
      'read': 'Read',
      'delivered': 'Delivered',
      'sent': 'Sent',
      'failed': 'Failed',
      'block_user': 'Block User',
      'unblock_user': 'Unblock User',
      'report_user': 'Report User',
      'mute_notifications': 'Mute Notifications',
      'unmute_notifications': 'Unmute Notifications',
      'clear_chat': 'Clear Chat',
      'delete_chat': 'Delete Chat',
      'usage_time': 'Usage Time',
      'daily_limit': 'Daily Limit',
      'weekly_stats': 'Weekly Statistics',
      'monthly_stats': 'Monthly Statistics',
      'total_time': 'Total Time',
      'average_daily': 'Daily Average',
      'most_active_day': 'Most Active Day',
      'least_active_day': 'Least Active Day',
      'usage_trend': 'Usage Trend',
      'time_breakdown': 'Time Breakdown',
      'screen_time': 'Screen Time',
      'app_launches': 'App Launches',
      'session_duration': 'Session Duration',
      'break_reminder': 'Break Reminder',
      'usage_alert': 'Usage Alert',
      'healthy_usage': 'Healthy Usage',
      'excessive_usage': 'Excessive Usage',
      'take_break': 'Take a Break',
      'continue_using': 'Continue Using',
      'set_limit': 'Set Limit',
      'extend_limit': 'Extend Limit',
      'disable_limit': 'Disable Limit',
      'parental_controls': 'Parental Controls',
      'digital_wellbeing': 'Digital Wellbeing',
      'focus_mode': 'Focus Mode',
      'do_not_disturb': 'Do Not Disturb',
      'quiet_hours': 'Quiet Hours',
      'bedtime_mode': 'Bedtime Mode',
      'wind_down': 'Wind Down',
      'morning_routine': 'Morning Routine',

      // Authentication error messages
      'signupFailed': 'Failed to create account. Please try again.',
      'invalidCredentials': 'Invalid email or password.',
      'invalidEmailError': 'Please enter a valid email address.',
      'weakPasswordError':
          'Password is too weak. It should be at least 6 characters.',
      'emailExistsError':
          'This email is already in use. Please try another one.',
      'wrongPasswordError': 'Incorrect password. Please try again.',
      'userNotFoundError': 'No account found with this email.',
      'tooManyRequestsError': 'Too many attempts. Please try again later.',
      'networkError': 'Network connection error. Please check your internet.',
      'generalAuthError': 'Authentication error. Please try again.',
      'emailNotVerifiedError': 'Please verify your email before logging in.',
      'databaseError': 'Error creating account. Please try again.',

      // Form validation
      'emailRequired': 'Please enter your email',
      'passwordRequired': 'Please enter your password',
      'passwordMinLength': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',

      // Email verification
      'emailVerificationTitle': 'Check your email',
      'emailVerificationMessage':
          'We have sent a verification message to your email. Please click the link in the email to verify your account.',
      'emailVerificationInstructions':
          'If you don\'t see the email, check your spam folder.',
      'resendEmailButton': 'Resend Email',
      'verificationEmailResent': 'Verification email resent',

      // Loading states
      'creatingAccount': 'Creating your account...',
      'signingIn': 'Signing in...',
      'sendingResetEmail': 'Sending reset email...',

      // Password reset
      'resetPasswordEmailSent': 'Password reset email sent',
      'resetPasswordInstructions':
          'Check your email for password reset instructions.',

      // Miscellaneous

      // Add missing keys
      'errorLoadingData': 'Failed to load data. Please try again.',
      'errorRefreshingData': 'Failed to refresh data. Please try again.',
      'errorLikingPost': 'Failed to like the post. Please try again.',
      'errorDeletingPost': 'Failed to delete the post. Please try again.',
      'knowledge': 'Knowledge',
      'noInternetConnection': 'No internet connection',
      'viewAll': 'View All',
      'shareYourAchievement': 'Share your achievement',
      'startShareYourThoughts': 'Start sharing your thoughts!',
      'comingSoon': 'Coming soon',

      // Achievements-related (added)
      'achievements': 'Achievements',
      'failedToLoadAchievements': 'Failed to load achievements',
      'privacySettings': 'Privacy Settings',
      'newAchievement': 'New Achievement',
      'shareYourFirstPost': 'Share your first post',
      'noAchievementsYet': 'No achievements yet',
      'addYourFirstAchievement': 'Add your first achievement',
      'editAchievement': 'Edit Achievement',
      'deleteAchievement': 'Delete Achievement',
      'deleteAchievementConfirmation':
          'Are you sure you want to delete this achievement?',
      'achievementDeleted': 'Achievement deleted successfully',
      'failedToDeleteAchievement': 'Failed to delete achievement',
      'followToSeeContent': 'Follow to see content',
      'description': 'Description',
      'type': 'Type',
      'noNotifications': 'No notifications yet',
      'messagesComingSoon': 'Messages screen coming soon',
      'pageNotFound': 'Page Not Found',
      'goHome': 'Go Home',
      'about': 'About',
      'aboutAppContent': 'This is the app description and information.',
      'help': 'Help',

      // User Service Messages
      'userNotFound': 'User not found',
      'invalidUsername':
          'Invalid username. Username should be 3-20 characters and contain only letters, numbers, and underscores.',
      'usernameExists': 'This username is already taken',
      'invalidUserData': 'Invalid user data. Please check all required fields.',
      'errorUpdatingProfile': 'Error updating profile. Please try again.',
      'profileUpdatedSuccess': 'Profile updated successfully',
      'errorLoadingUser': 'Error loading user data. Please try again.',
      'errorFollowingUser': 'Error following user. Please try again.',
      'errorUnfollowingUser': 'Error unfollowing user. Please try again.',
      'followRequestSent': 'Follow request sent successfully',
      'followRequestAccepted': 'Follow request accepted',
      'followRequestDeclined': 'Follow request declined',
      'errorSavingChanges': 'Error saving changes. Please try again.',
      'imageUploadError': 'Error uploading image. Please try again.',
      'invalidFileType':
          'Invalid file type. Please use JPG, PNG, or GIF images.',
      'emptyFile': 'Selected file is empty',
      'fileNotFound': 'Selected file not found',

      // Validation Messages
      'requiredField': 'This field is required',
      'invalidFormat': 'Invalid format',
      'minimumLength': 'Must be at least {count} characters',
      'maximumLength': 'Must not exceed {count} characters',
      'invalidCharacters': 'Contains invalid characters',

      // Chat & Messaging (Added)
      'newConversation': 'New Conversation',
      'searchUsers': 'Search Users',
      'createGroup': 'Create Group',
      'startConversation': 'Start Conversation',
      'failedToCreateConversation': 'Failed to create conversation',
      'selectParticipants': 'Select Participants',
      'noUsersFound': 'No users found',
      'groupConversation': 'Group Conversation',

      // Posts & Content Types (Added)
      'regularPost': 'Regular Post',
      'knowledgePost': 'Knowledge Post',
      'eventPost': 'Event Post',
      'pollPost': 'Poll Post',
      'announcement': 'Announcement',
      'knowledgeDomain': 'Knowledge Domain',
      'enterKnowledgeDomain': 'Enter knowledge domain',
      'shareThoughts': 'Share your thoughts...',
      'addMedia': 'Add Media',
      'removeMedia': 'Remove Media',
      'postVisibility': 'Post Visibility',

      // Usage & Limits (Added)
      'usageLimit': 'Usage Limit',
      'dailyLimit': 'Daily Limit',
      'limitReached': 'Daily Limit Reached',
      'remainingTime': 'Remaining Time',
      'usageStats': 'Usage Statistics',
      'closeApp': 'Close App',

      // Search & Discovery (Added)
      'searchHint': 'Search users...',
      'searchResults': 'Search Results',
      'noResultsFound': 'No results found',
      'tryAnotherSearch': 'Try another search term',
      'suggestedUsers': 'Suggested Users',
      'popularUsers': 'Popular Users',

      // User List & Followers (Added)
      'noFollowers': 'No followers yet',
      'noFollowersDescription':
          'Start connecting with other users to grow your network',
      'errorLoadingFollowers': 'Error loading followers',
    

      // Post Interactions (Added)
      'postCreated': 'Post created successfully',
      'postUpdated': 'Post updated successfully',
      'postCreateError': 'Error creating post',
      'postUpdateError': 'Error updating post',
      'enterContent': 'Enter post content',
      'selectVisibility': 'Select post visibility',
      'attachments': 'Attachments',

      // Main & HomeScreen
      'main_loading': 'Loading...',
      'homeScreen_hide_timer': 'Hide usage timer',
      'homeScreen_show_timer': 'Show usage timer',
      // Limit reached
      'limitReached_title': 'Daily Usage Limit Reached',
      'limitReached_message':
          (String time) =>
              'You have reached your daily usage limit ($time). Please come back tomorrow to enjoy the app again.',
      'limitReached_timeFormat': (int minutes) {
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final remainingMinutes = minutes % 60;
          if (remainingMinutes == 0) {
            return '$hours hour(s)';
          } else {
            return '$hours hour(s) and $remainingMinutes min';
          }
        } else {
          return '$minutes min';
        }
      },
    },
    'ar': {
      // App basics
      'appName': "سين",
      'home': 'الرئيسية',
      'search': 'البحث',
      'messages': 'الرسائل',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'unknown': 'غير معروف',

      // General UI
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'follow': 'متابعة',
      'unblock': 'إلغاء الحظر',
      'notAvailable': 'غير متاح',
      'okButton': 'موافق',
      'optional': 'اختياري',
      'save': 'حفظ',

      // Profile related
      'editProfile': 'تعديل الملف الشخصي',
      'profileUpdateSuccess': 'تم تحديث الملف الشخصي بنجاح',
      'displayName': 'الاسم الظاهر',
      'displayNameRequired': 'الاسم الظاهر مطلوب',
      'username': 'اسم المستخدم',
      'usernameRequired': 'اسم المستخدم مطلوب',
      'usernameMinLength': 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل',
      'bio': 'نبذة تعريفية',
      'enterBio': 'أدخل نبذة تعريفية',
      'accountType': 'نوع الحساب',
      'publicAccount': 'حساب عام',
      'privateAccount': 'حساب خاص',
      'profileImageHint': 'اضغط لتغيير الصورة',

      // Stats and counts
      'posts': 'المنشورات',
      'follows': 'المتابِعون',
      'following': 'يتابع',
      'postCount': '{count} منشور',
      'followersCount': '{count} متابع',
      'followingCount': '{count} يتابع',

      // Navigation
      'navigationError': 'حدث خطأ أثناء الانتقال. يرجى المحاولة مرة أخرى.',

      // Achievements
      'achievements': 'الإنجازات',
      'newAchievement': 'إنجاز جديد',
      'addAchievement': 'إضافة إنجاز',
      'editAchievement': 'تعديل الإنجاز',
      'deleteAchievement': 'حذف الإنجاز',
      'achievementDeleted': 'تم حذف الإنجاز',
      'noAchievementsYet': 'لا توجد إنجازات بعد',
      'addYourFirstAchievement': 'أضف أول إنجازاتك',

      // Posts
      'createPost': 'إنشاء منشور',
      'editPost': 'تعديل المنشور',
      'deletePost': 'حذف المنشور',
      'postDeleted': 'تم حذف المنشور',
      'noPostsYet': 'لا توجد منشورات بعد',
      'shareYourFirstPost': 'شارك أول منشوراتك',

      // Profile actions
      'blockUser': 'حظر المستخدم',
      'reportUser': 'الإبلاغ عن المستخدم',
      'shareProfile': 'مشاركة الملف الشخصي',

      // Privacy
      'privateAccountMessage': 'هذا حساب خاص',
      'followToSeeContent': 'تابع لرؤية المحتوى',
      'followRequestSent': 'تم إرسال طلب المتابعة',
      'unfollow': 'إلغاء المتابعة',

      // Error messages
      'generalError': 'حدث خطأ. يرجى المحاولة مرة أخرى',
      'loadingError': 'حدث خطأ أثناء التحميل',
      'networkError': 'خطأ في الاتصال بالإنترنت',
      'noInternetConnection': 'لا يوجد اتصال بالإنترنت',
      'description': 'الوصف',
      'type': 'النوع',
      'noNotifications': 'لا توجد إشعارات بعد',
      'messagesComingSoon': 'صفحة الرسائل قادمة قريباً',
      'pageNotFound': 'الصفحة غير موجودة',
      'goHome': 'العودة للرئيسية',
      'about': 'حول التطبيق',
      'aboutAppContent': 'هذا وصف ومعلومات التطبيق.',
      'help': 'المساعدة',
      // Add missing keys
      'errorLoadingData': 'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.',
      'errorRefreshingData': 'فشل في تحديث البيانات. يرجى المحاولة مرة أخرى.',
      'errorLikingPost': 'فشل في تسجيل الإعجاب. يرجى المحاولة مرة أخرى.',
      'errorDeletingPost': 'فشل في حذف المنشور. يرجى المحاولة مرة أخرى.',
      'knowledge': 'المعرفة',

      // User Service Messages
      'user_not_found': 'المستخدم غير موجود',
      'error_loading_user': 'خطأ في تحميل بيانات المستخدم',
      'invalid_username_error': 'صيغة اسم المستخدم غير صالحة',
      'username_exists_error': 'اسم المستخدم موجود بالفعل',
      'file_not_found': 'الملف غير موجود',
      'empty_file': 'الملف فارغ',
      'image_upload_error': 'خطأ في رفع الصورة',

      // Validation Messages
      'requiredField': 'هذا الحقل مطلوب',
      'invalidFormat': 'صيغة غير صالحة',
      'minimumLength': 'يجب أن يكون {count} أحرف على الأقل',
      'maximumLength': 'يجب ألا يتجاوز {count} حرف',
      'invalidCharacters': 'يحتوي على أحرف غير صالحة',

      // Chat & Messaging (Added)
      'newConversation': 'محادثة جديدة',
      'searchUsers': 'البحث عن مستخدمين',
      'createGroup': 'إنشاء مجموعة',
      'startConversation': 'بدء محادثة',
      'failedToCreateConversation': 'فشل في إنشاء المحادثة',
      'selectParticipants': 'اختيار المشاركين',
      'noUsersFound': 'لم يتم العثور على مستخدمين',
      'groupConversation': 'محادثة جماعية',

      // Posts & Content Types (Added)
      'regularPost': 'منشور عادي',
      'knowledgePost': 'منشور معرفي',
      'eventPost': 'منشور حدث',
      'pollPost': 'منشور استطلاع',
      'announcement': 'إعلان',
      'knowledgeDomain': 'مجال المعرفة',
      'enterKnowledgeDomain': 'أدخل مجال المعرفة',
      'shareThoughts': 'شارك أفكارك...',
      'addMedia': 'إضافة وسائط',
      'removeMedia': 'إزالة الوسائط',
      'postVisibility': 'خصوصية المنشور',

      // Usage & Limits (Added)
      'usageLimit': 'حد الاستخدام',
      'dailyLimit': 'الحد اليومي',
      'limitReached': 'تم الوصول للحد اليومي',
      'remainingTime': 'الوقت المتبقي',
      'usageStats': 'إحصائيات الاستخدام',
      'closeApp': 'إغلاق التطبيق',

      // Search & Discovery (Added)
      'searchHint': 'البحث عن مستخدمين...',
      'searchResults': 'نتائج البحث',
      'noResultsFound': 'لم يتم العثور على نتائج',
      'tryAnotherSearch': 'جرب مصطلح بحث آخر',
      'suggestedUsers': 'مستخدمون مقترحون',
      'popularUsers': 'المستخدمون الأكثر شهرة',

      // User List & Followers (Added)
      'noFollowers': 'لا يوجد متابعون بعد',
      'noFollowersDescription':
          'ابدأ بالتواصل مع مستخدمين آخرين لتنمية شبكة علاقاتك',
      'errorLoadingFollowers': 'خطأ في تحميل المتابعين',
      'retry': 'إعادة المحاولة',

      // Post Interactions (Added)
      'postCreated': 'تم إنشاء المنشور بنجاح',
      'postUpdated': 'تم تحديث المنشور بنجاح',
      'postCreateError': 'خطأ في إنشاء المنشور',
      'postUpdateError': 'خطأ في تحديث المنشور',
      'enterContent': 'أدخل محتوى المنشور',
      'selectVisibility': 'اختر خصوصية المنشور',
      'attachments': 'المرفقات',
      'limit_reached_title': 'انتهى وقت الاستخدام اليومي',
      'limit_reached_message': 'لقد وصلت إلى الحد الأقصى للاستخدام اليومي',
      'close_app': 'إغلاق التطبيق',
      'return_tomorrow': 'يرجى العودة غدًا للاستمتاع بالتطبيق مرة أخرى',
      'hide_timer': 'إخفاء المؤقت',
      'show_timer': 'عرض المؤقت',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
     
      'ok': 'موافق',
      'yes': 'نعم',
      'no': 'لا',
      
      'add': 'إضافة',
      
      'notifications': 'الإشعارات',
  
      'back': 'رجوع',
      'next': 'التالي',
      'previous': 'السابق',
      'done': 'تم',
     
      'refresh': 'تحديث',
      'update': 'تحديث',
      'share': 'مشاركة',
      'copy': 'نسخ',
      'paste': 'لصق',
      'select_all': 'تحديد الكل',
      'clear': 'مسح',
   
      'version': 'الإصدار',
      'language': 'اللغة',
      'theme': 'المظهر',
      'privacy': 'الخصوصية',
      'terms': 'شروط الخدمة',
      'support': 'الدعم',
      'feedback': 'ملاحظات',
      'rate_app': 'تقييم التطبيق',
      'logout': 'تسجيل الخروج',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'remember_me': 'تذكرني',
  
      'full_name': 'الاسم الكامل',
      'phone_number': 'رقم الهاتف',
      // Main & HomeScreen
      'main_loading': 'جاري التحميل...',
      'homeScreen_hide_timer': 'إخفاء المؤقت',
      'homeScreen_show_timer': 'عرض المؤقت',
      // Limit reached
      'limitReached_title': 'تم الوصول للحد اليومي',
      'limitReached_message':
          (String time) =>
              'لقد وصلت إلى حد الاستخدام اليومي ($time). يرجى العودة غدًا للاستمتاع بالتطبيق مرة أخرى.',
      'limitReached_timeFormat': (int minutes) {
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final remainingMinutes = minutes % 60;
          if (remainingMinutes == 0) {
            return '$hours ساعة';
          } else {
            return '$hours ساعة و $remainingMinutes دقيقة';
          }
        } else {
          return '$minutes دقيقة';
        }
      },
    },
  };

  // --- Fix for function-valued translations ---
  String get main_loading => translate('main_loading');
  String get homeScreen_hide_timer => translate('homeScreen_hide_timer');
  String get homeScreen_show_timer => translate('homeScreen_show_timer');
  String get limitReached_title => translate('limitReached_title');
  String limitReached_message(String time) {
    final lang = locale.languageCode;
    final value = _localizedValues[lang]?['limitReached_message'];
    if (value is Function) return value(time);
    final enValue = _localizedValues['en']?['limitReached_message'];
    if (enValue is Function) return enValue(time);
    return '';
  }

  String limitReached_timeFormat(int minutes) {
    final lang = locale.languageCode;
    final value = _localizedValues[lang]?['limitReached_timeFormat'];
    if (value is Function) return value(minutes);
    final enValue = _localizedValues['en']?['limitReached_timeFormat'];
    if (enValue is Function) return enValue(minutes);
    return '';
  }

  // --- All other getters: always return String only ---
  String get appName => translate('appName');
  String get home => translate('home');
  String get search => translate('search');
  String get messages => translate('messages');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get unknown => translate('unknown');
  String get navigationError => translate('navigationError');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get follow => translate('follow');
  String get unblock => translate('unblock');
  String get notAvailable => translate('notAvailable');
  String get okButton => translate('okButton');
  String get language => translate('language');
  String get theme => translate('theme');
  String get english => translate('english');
  String get arabic => translate('arabic');
  String get darkMode => translate('darkMode');
  String get lightMode => translate('lightMode');
  String get posts => translate('posts');
  String get createPost => translate('createPost');
  String get noPostsYet => translate('noPostsYet');
  String get noPhotosYet => translate('noPhotosYet');
  String get noSavedPosts => translate('noSavedPosts');
  String get addStory => translate('addStory');
  String get like => translate('like');
  String get comment => translate('comment');
  String get share => translate('share');
  String get confirmDelete => translate('confirmDelete');
  String get confirmDeletePostMessage => translate('confirmDeletePostMessage');
  String get postDeleted => translate('postDeleted');
  String get failedToDeletePost => translate('failedToDeletePost');
  String get failedToLoadPosts => translate('failedToLoadPosts');
  String get failedToUpdateLike => translate('failedToUpdateLike');
  String get justNow => translate('justNow');
  String get minutesAgo => translate('minutesAgo');
  String get hoursAgo => translate('hoursAgo');
  String get daysAgo => translate('daysAgo');
  String get monthsAgo => translate('monthsAgo');
  String get yearsAgo => translate('yearsAgo');
  String get lastActive => translate('lastActive');
  String get follows => translate('follows');
  String get following => translate('following');
  String get editProfile => translate('editProfile');
  String get save => translate('save');
  String get displayName => translate('displayName');
  String get bio => translate('bio');
  String get publicAccount => translate('publicAccount');
  String get privateAccount => translate('privateAccount');
  String get failedToLoadUserData => translate('failedToLoadUserData');
  String get failedToLoadProfile => translate('failedToLoadProfile');
  String get failedToFollowUser => translate('failedToFollowUser');
  String get failedToUnfollowUser => translate('failedToUnfollowUser');

  // User actions
  String get blockUser =>
      _localizedValues[locale.languageCode]?['blockUser'] ??
      (_isArabic() ? 'حظر المستخدم' : 'Block User');
  String get unblockUser =>
      _localizedValues[locale.languageCode]?['unblockUser'] ??
      (_isArabic() ? 'إلغاء الحظر' : 'Unblock User');
  String get reportUser =>
      _localizedValues[locale.languageCode]?['reportUser'] ??
      (_isArabic() ? 'الإبلاغ عن المستخدم' : 'Report User');
  String get userBlocked =>
      _localizedValues[locale.languageCode]?['userBlocked'] ??
      (_isArabic() ? 'تم حظر المستخدم بنجاح' : 'User blocked successfully');
  String get failedToBlockUser =>
      _localizedValues[locale.languageCode]?['failedToBlockUser'] ??
      (_isArabic() ? 'فشل في حظر المستخدم' : 'Failed to block user');
  String get userUnblocked =>
      _localizedValues[locale.languageCode]?['userUnblocked'] ??
      (_isArabic()
          ? 'تم إلغاء حظر المستخدم بنجاح'
          : 'User unblocked successfully');
  String get failedToUnblockUser =>
      _localizedValues[locale.languageCode]?['failedToUnblockUser'] ??
      (_isArabic() ? 'فشل في إلغاء حظر المستخدم' : 'Failed to unblock user');

  // General errors
  String get generalError =>
      _localizedValues[locale.languageCode]?['generalError'] ??
      (_isArabic()
          ? 'حدث خطأ. يرجى المحاولة مرة أخرى'
          : 'An error occurred. Please try again');

  // Auth - Login/Signup
  String get login =>
      _localizedValues[locale.languageCode]?['login'] ??
      (_isArabic() ? 'تسجيل الدخول' : 'Login');
  String get signup =>
      _localizedValues[locale.languageCode]?['signup'] ??
      (_isArabic() ? 'إنشاء حساب' : 'Signup');
  String get logOut =>
      _localizedValues[locale.languageCode]?['logOut'] ??
      (_isArabic() ? 'تسجيل الخروج' : 'Log Out');
  String get logoutFailed =>
      _localizedValues[locale.languageCode]?['logoutFailed'] ??
      (_isArabic()
          ? 'فشل في تسجيل الخروج. يرجى المحاولة مرة أخرى'
          : 'Failed to log out. Please try again');
  String get alreadyHaveAccount =>
      _localizedValues[locale.languageCode]?['alreadyHaveAccount'] ??
      (_isArabic() ? 'هل لديك حساب بالفعل؟' : 'Already have an account?');
  String get dontHaveAccount =>
      _localizedValues[locale.languageCode]?['dontHaveAccount'] ??
      (_isArabic() ? 'ليس لديك حساب؟' : "Don't have an account?");
  String get forgotPassword =>
      _localizedValues[locale.languageCode]?['forgotPassword'] ??
      (_isArabic() ? 'نسيت كلمة المرور؟' : 'Forgot password?');
  String get resetPassword =>
      _localizedValues[locale.languageCode]?['resetPassword'] ??
      (_isArabic() ? 'إعادة تعيين كلمة المرور' : 'Reset Password');
  String get enterEmailForReset =>
      _localizedValues[locale.languageCode]?['enterEmailForReset'] ??
      (_isArabic()
          ? 'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور'
          : 'Enter your email to receive a password reset link');
  String get sendLink =>
      _localizedValues[locale.languageCode]?['sendLink'] ??
      (_isArabic() ? 'إرسال الرابط' : 'Send Link');
  String get resetLinkSent =>
      _localizedValues[locale.languageCode]?['resetLinkSent'] ??
      (_isArabic()
          ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
          : 'Password reset link sent to your email');
  String get createAccount =>
      _localizedValues[locale.languageCode]?['createAccount'] ??
      (_isArabic() ? 'إنشاء حساب' : 'Create Account');
  String get enterEmail =>
      _localizedValues[locale.languageCode]?['enterEmail'] ??
      (_isArabic() ? 'أدخل بريدك الإلكتروني' : 'Enter your email');
  String get createPassword =>
      _localizedValues[locale.languageCode]?['createPassword'] ??
      (_isArabic() ? 'إنشاء كلمة مرور' : 'Create a password');
  String get confirmPassword =>
      _localizedValues[locale.languageCode]?['confirmPassword'] ??
      (_isArabic() ? 'تأكيد كلمة المرور' : 'Confirm your password');
  String get accountCreatedSuccess =>
      _localizedValues[locale.languageCode]?['accountCreatedSuccess'] ??
      (_isArabic()
          ? 'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني لتفعيل الحساب.'
          : 'Account created successfully! Please check your email to verify your account.');
  String get accountCreatedSuccessfully =>
      _localizedValues[locale.languageCode]?['accountCreatedSuccessfully'] ??
      (_isArabic()
          ? 'تم إنشاء الحساب بنجاح!'
          : 'Account created successfully!');
  String get emailVerificationSentTo =>
      _localizedValues[locale.languageCode]?['emailVerificationSentTo'] ??
      (_isArabic() ? 'تم إرسال بريد التحقق إلى' : 'Verification email sent to');
  String get usernameExistsError =>
      _localizedValues[locale.languageCode]?['usernameExistsError'] ??
      (_isArabic()
          ? 'اسم المستخدم هذا مستخدم بالفعل. يرجى تجربة اسم آخر.'
          : 'This username is already in use. Please try another one.');
  String get invalidUsernameError =>
      _localizedValues[locale.languageCode]?['invalidUsernameError'] ??
      (_isArabic()
          ? 'اسم المستخدم غير صالح. يرجى اختيار اسم مستخدم صالح.'
          : 'Invalid username. Please choose a valid username.');
  String get notAuthenticatedError =>
      _localizedValues[locale.languageCode]?['notAuthenticatedError'] ??
      (_isArabic()
          ? 'أنت غير مصرح لك. يرجى تسجيل الدخول.'
          : 'You are not authenticated. Please log in.');

  // Authentication error messages
  String get signupFailed =>
      _localizedValues[locale.languageCode]?['signupFailed'] ??
      (_isArabic()
          ? 'فشل في إنشاء الحساب. يرجى المحاولة مرة أخرى.'
          : 'Failed to create account. Please try again.');
  String get invalidCredentials =>
      _localizedValues[locale.languageCode]?['invalidCredentials'] ??
      (_isArabic()
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
          : 'Invalid email or password.');
  String get invalidEmailError =>
      _localizedValues[locale.languageCode]?['invalidEmailError'] ??
      (_isArabic()
          ? 'يرجى إدخال عنوان بريد إلكتروني صالح.'
          : 'Please enter a valid email address.');
  String get weakPasswordError =>
      _localizedValues[locale.languageCode]?['weakPasswordError'] ??
      (_isArabic()
          ? 'كلمة المرور ضعيفة جداً. يجب أن تكون على الأقل 6 أحرف.'
          : 'Password is too weak. It should be at least 6 characters.');
  String get emailExistsError =>
      _localizedValues[locale.languageCode]?['emailExistsError'] ??
      (_isArabic()
          ? 'هذا البريد الإلكتروني مستخدم بالفعل. يرجى تجربة بريد آخر.'
          : 'This email is already in use. Please try another one.');
  String get wrongPasswordError =>
      _localizedValues[locale.languageCode]?['wrongPasswordError'] ??
      (_isArabic()
          ? 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.'
          : 'Incorrect password. Please try again.');
  String get userNotFoundError =>
      _localizedValues[locale.languageCode]?['userNotFoundError'] ??
      (_isArabic()
          ? 'لا يوجد حساب بهذا البريد الإلكتروني.'
          : 'No account found with this email.');
  String get tooManyRequestsError =>
      _localizedValues[locale.languageCode]?['tooManyRequestsError'] ??
      (_isArabic()
          ? 'عدد المحاولات كبير جداً. يرجى المحاولة لاحقاً.'
          : 'Too many attempts. Please try again later.');
  String get networkError =>
      _localizedValues[locale.languageCode]?['networkError'] ??
      (_isArabic()
          ? 'خطأ في الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت.'
          : 'Network connection error. Please check your internet.');
  String get generalAuthError =>
      _localizedValues[locale.languageCode]?['generalAuthError'] ??
      (_isArabic()
          ? 'خطأ في المصادقة. يرجى المحاولة مرة أخرى.'
          : 'Authentication error. Please try again.');
  String get emailNotVerifiedError =>
      _localizedValues[locale.languageCode]?['emailNotVerifiedError'] ??
      (_isArabic()
          ? 'يرجى التحقق من بريدك الإلكتروني قبل تسجيل الدخول.'
          : 'Please verify your email before logging in.');
  String get databaseError =>
      _localizedValues[locale.languageCode]?['databaseError'] ??
      (_isArabic()
          ? 'خطأ في إنشاء الحساب. يرجى المحاولة مرة أخرى.'
          : 'Error creating account. Please try again.');

  // Form validation
  String get emailRequired =>
      _localizedValues[locale.languageCode]?['emailRequired'] ??
      (_isArabic() ? 'يرجى إدخال بريدك الإلكتروني' : 'Please enter your email');
  String get passwordRequired =>
      _localizedValues[locale.languageCode]?['passwordRequired'] ??
      (_isArabic() ? 'يرجى إدخال كلمة المرور' : 'Please enter your password');
  String get passwordMinLength =>
      _localizedValues[locale.languageCode]?['passwordMinLength'] ??
      (_isArabic()
          ? 'يجب أن تكون كلمة المرور على الأقل 6 أحرف'
          : 'Password must be at least 6 characters');
  String get passwordsDoNotMatch =>
      _localizedValues[locale.languageCode]?['passwordsDoNotMatch'] ??
      (_isArabic() ? 'كلمات المرور غير متطابقة' : 'Passwords do not match');

  // Email verification
  String get emailVerificationTitle =>
      _localizedValues[locale.languageCode]?['emailVerificationTitle'] ??
      (_isArabic() ? 'تحقق من بريدك الإلكتروني' : 'Check your email');
  String get emailVerificationMessage =>
      _localizedValues[locale.languageCode]?['emailVerificationMessage'] ??
      (_isArabic()
          ? 'لقد أرسلنا رسالة تحقق إلى بريدك الإلكتروني. يرجى النقر على الرابط في البريد الإلكتروني لتفعيل حسابك.'
          : 'We have sent a verification message to your email. Please click the link in the email to verify your account.');
  String get emailVerificationInstructions =>
      _localizedValues[locale.languageCode]?['emailVerificationInstructions'] ??
      (_isArabic()
          ? 'إذا لم ترَ البريد الإلكتروني، تحقق من مجلد الرسائل غير المرغوب فيها.'
          : 'If you don\'t see the email, check your spam folder.');
  String get resendEmailButton =>
      _localizedValues[locale.languageCode]?['resendEmailButton'] ??
      (_isArabic() ? 'إعادة إرسال البريد الإلكتروني' : 'Resend Email');
  String get verificationEmailResent =>
      _localizedValues[locale.languageCode]?['verificationEmailResent'] ??
      (_isArabic()
          ? 'تم إعادة إرسال بريد التحقق'
          : 'Verification email resent');
   String get closeApp =>
      locale.languageCode == 'ar' ? 'إغلاق التطبيق' : 'Close App';

  // Loading states
  String get creatingAccount =>
      _localizedValues[locale.languageCode]?['creatingAccount'] ??
      (_isArabic() ? 'جاري إنشاء حسابك...' : 'Creating your account...');
  String get signingIn =>
      _localizedValues[locale.languageCode]?['signingIn'] ??
      (_isArabic() ? 'جاري تسجيل الدخول...' : 'Signing in...');
  String get sendingResetEmail =>
      _localizedValues[locale.languageCode]?['sendingResetEmail'] ??
      (_isArabic()
          ? 'جاري إرسال بريد إعادة التعيين...'
          : 'Sending reset email...');

  // Password reset
  String get resetPasswordEmailSent =>
      _localizedValues[locale.languageCode]?['resetPasswordEmailSent'] ??
      (_isArabic()
          ? 'تم إرسال بريد إعادة تعيين كلمة المرور'
          : 'Password reset email sent');
  String get resetPasswordInstructions =>
      _localizedValues[locale.languageCode]?['resetPasswordInstructions'] ??
      (_isArabic()
          ? 'تحقق من بريدك الإلكتروني للحصول على تعليمات إعادة تعيين كلمة المرور.'
          : 'Check your email for password reset instructions.');

  // Miscellaneous
  String get privacy =>
      _localizedValues[locale.languageCode]?['privacy'] ??
      (_isArabic() ? 'الخصوصية' : 'Privacy');
  String get notifications =>
      _localizedValues[locale.languageCode]?.containsKey('notifications') ==
              true
          ? _localizedValues[locale.languageCode]!['notifications']!
          : (_isArabic() ? 'الإشعارات' : 'Notifications');
  String get noInternetConnection =>
      _localizedValues[locale.languageCode]?['noInternetConnection'] ??
      (_isArabic() ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection');
  String get viewAll =>
      _localizedValues[locale.languageCode]?['viewAll'] ??
      (_isArabic() ? 'عرض الكل' : 'View All');
  String get shareYourAchievement =>
      _localizedValues[locale.languageCode]?['shareYourAchievement'] ??
      (_isArabic() ? 'شارك إنجازك' : 'Share your achievement');
  String get startShareYourThoughts =>
      _localizedValues[locale.languageCode]?['startShareYourThoughts'] ??
      (_isArabic() ? 'ابدأ بمشاركة أفكارك!' : 'Start sharing your thoughts!');
  String get comingSoon =>
      _localizedValues[locale.languageCode]?['comingSoon'] ??
      (_isArabic() ? 'قريباً' : 'Coming soon');

  // Add achievements getter
  String get achievements =>
      _localizedValues[locale.languageCode]?['achievements'] ??
      (_isArabic() ? 'الإنجازات' : 'Achievements');

  // Add missing achievement-related getters
  String get failedToLoadAchievements =>
      _localizedValues[locale.languageCode]?['failedToLoadAchievements'] ??
      (_isArabic() ? 'فشل في تحميل الإنجازات' : 'Failed to load achievements');
  String get privacySettings =>
      _localizedValues[locale.languageCode]?['privacySettings'] ??
      (_isArabic() ? 'إعدادات الخصوصية' : 'Privacy Settings');
  String get newAchievement =>
      _localizedValues[locale.languageCode]?['newAchievement'] ??
      (_isArabic() ? 'إنجاز جديد' : 'New Achievement');
  String get shareYourFirstPost =>
      _localizedValues[locale.languageCode]?['shareYourFirstPost'] ??
      (_isArabic() ? 'شارك أول منشور لك' : 'Share your first post');
  String get noAchievementsYet =>
      _localizedValues[locale.languageCode]?['noAchievementsYet'] ??
      (_isArabic() ? 'لا توجد إنجازات بعد' : 'No achievements yet');
  String get addYourFirstAchievement =>
      _localizedValues[locale.languageCode]?['addYourFirstAchievement'] ??
      (_isArabic() ? 'أضف أول إنجاز لك' : 'Add your first achievement');
  String get editAchievement =>
      _localizedValues[locale.languageCode]?['editAchievement'] ??
      (_isArabic() ? 'تعديل الإنجاز' : 'Edit Achievement');
  String get deleteAchievement =>
      _localizedValues[locale.languageCode]?['deleteAchievement'] ??
      (_isArabic() ? 'حذف الإنجاز' : 'Delete Achievement');
  String get deleteAchievementConfirmation =>
      _localizedValues[locale.languageCode]?['deleteAchievementConfirmation'] ??
      (_isArabic()
          ? 'هل أنت متأكد أنك تريد حذف هذا الإنجاز؟'
          : 'Are you sure you want to delete this achievement?');
  String get achievementDeleted =>
      _localizedValues[locale.languageCode]?['achievementDeleted'] ??
      (_isArabic()
          ? 'تم حذف الإنجاز بنجاح'
          : 'Achievement deleted successfully');
  String get failedToDeleteAchievement =>
      _localizedValues[locale.languageCode]?['failedToDeleteAchievement'] ??
      (_isArabic() ? 'فشل في حذف الإنجاز' : 'Failed to delete achievement');
  String get followToSeeContent =>
      _localizedValues[locale.languageCode]?['followToSeeContent'] ??
      (_isArabic() ? 'تابع لرؤية المحتوى' : 'Follow to see content');

  // Add missing getters for edit_profile_screen.dart
  String get profileUpdateSuccess =>
      _localizedValues[locale.languageCode]?['profileUpdateSuccess'] ??
      (_isArabic()
          ? 'تم تحديث الملف الشخصي بنجاح'
          : 'Profile updated successfully');

  String errorOccurred(String error) =>
      (_localizedValues[locale.languageCode]?['generalError'] ??
          (_isArabic()
              ? 'حدث خطأ. يرجى المحاولة مرة أخرى'
              : 'An error occurred. Please try again')) +
      (error.isNotEmpty ? '\n$error' : '');

  String get enterDisplayName =>
      _localizedValues[locale.languageCode]?['enterDisplayName'] ??
      (_isArabic() ? 'أدخل اسم العرض' : 'Enter display name');

  String get displayNameRequired =>
      _localizedValues[locale.languageCode]?['displayNameRequired'] ??
      (_isArabic() ? 'اسم العرض مطلوب' : 'Display name is required');

  String get enterBio =>
      _localizedValues[locale.languageCode]?['enterBio'] ??
      (_isArabic() ? 'أدخل السيرة الذاتية' : 'Enter bio');

  String get accountType =>
      _localizedValues[locale.languageCode]?['accountType'] ??
      (_isArabic() ? 'نوع الحساب' : 'Account Type');

  String get publicAccountDescription =>
      _localizedValues[locale.languageCode]?['publicAccountDescription'] ??
      (_isArabic()
          ? 'يمكن للجميع رؤية منشوراتك ومتابعتك'
          : 'Anyone can see your posts and follow you');

  String get privateAccountDescription =>
      _localizedValues[locale.languageCode]?['privateAccountDescription'] ??
      (_isArabic()
          ? 'يجب الموافقة على المتابعين ويمكن فقط للمتابعين رؤية منشوراتك'
          : 'Followers must be approved and only they can see your posts');

  String get saveChanges =>
      _localizedValues[locale.languageCode]?['saveChanges'] ??
      (_isArabic() ? 'حفظ التغييرات' : 'Save Changes');

  // Add this getter for "optional"
  String get optional =>
      _localizedValues[locale.languageCode]?['optional'] ??
      (_isArabic() ? 'اختياري' : 'optional');

  // Helper to check Arabic
  bool _isArabic() => locale.languageCode == 'ar';

  String get achievementTitle =>
      _localizedValues[locale.languageCode]?['achievementTitle'] ??
      (_isArabic() ? 'عنوان الإنجاز' : 'Achievement Title');

  String get titleRequired =>
      _localizedValues[locale.languageCode]?['titleRequired'] ??
      (_isArabic() ? 'عنوان الإنجاز مطلوب' : 'Title is required');

  String get descriptionRequired =>
      _localizedValues[locale.languageCode]?['descriptionRequired'] ??
      (_isArabic() ? 'وصف الإنجاز مطلوب' : 'Description is required');

  String get publicAchievement =>
      _localizedValues[locale.languageCode]?['publicAchievement'] ??
      (_isArabic() ? 'إنجاز عام' : 'Public Achievement');

  String get publicAchievementDescription =>
      _localizedValues[locale.languageCode]?['publicAchievementDescription'] ??
      (_isArabic()
          ? 'يمكن للآخرين رؤية هذا الإنجاز'
          : 'Others can see this achievement');

  String get duration =>
      _localizedValues[locale.languageCode]?['duration'] ??
      (_isArabic() ? 'المدة' : 'Duration');

  String get noDuration =>
      _localizedValues[locale.languageCode]?['noDuration'] ??
      (_isArabic() ? 'بدون مدة' : 'No Duration');

  String get oneDay =>
      _localizedValues[locale.languageCode]?['oneDay'] ??
      (_isArabic() ? 'يوم واحد' : 'One Day');

  String get oneWeek =>
      _localizedValues[locale.languageCode]?['oneWeek'] ??
      (_isArabic() ? 'أسبوع' : 'One Week');

  String get oneMonth =>
      _localizedValues[locale.languageCode]?['oneMonth'] ??
      (_isArabic() ? 'شهر' : 'One Month');

  // Add missing translations for achievement screen
  String get description =>
      _localizedValues[locale.languageCode]?['description'] ??
      (_isArabic() ? 'الوصف' : 'Description');

  String get type =>
      _localizedValues[locale.languageCode]?['type'] ??
      (_isArabic() ? 'النوع' : 'Type');
  String get errorLoadingData =>
      _localizedValues[locale.languageCode]?['errorLoadingData'] ??
      (_isArabic()
          ? 'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.'
          : 'Failed to load data. Please try again.');

  String get errorRefreshingData =>
      _localizedValues[locale.languageCode]?['errorRefreshingData'] ??
      (_isArabic()
          ? 'فشل في تحديث البيانات. يرجى المحاولة مرة أخرى.'
          : 'Failed to refresh data. Please try again.');

  String get errorLikingPost =>
      _localizedValues[locale.languageCode]?['errorLikingPost'] ??
      (_isArabic()
          ? 'فشل في تسجيل الإعجاب. يرجى المحاولة مرة أخرى.'
          : 'Failed to like the post. Please try again.');

  String get errorDeletingPost =>
      _localizedValues[locale.languageCode]?['errorDeletingPost'] ??
      (_isArabic()
          ? 'فشل في حذف المنشور. يرجى المحاولة مرة أخرى.'
          : 'Failed to delete the post. Please try again.');

  String get knowledge =>
      _localizedValues[locale.languageCode]?['knowledge'] ??
      (_isArabic() ? 'المعرفة' : 'Knowledge');

  // ===== CREATE POST SCREEN =====

  // App Bar
  String get createPost_appBar_title =>
      isArabic ? 'إنشاء منشور جديد' : 'Create New Post';
  String get createPost_appBar_publishButton => isArabic ? 'نشر' : 'Publish';

  // User Info Section
  String get createPost_userInfo_you => isArabic ? 'أنت' : 'You';
  String get createPost_visibility_public => isArabic ? 'عام' : 'Public';
  String get createPost_visibility_private => isArabic ? 'خاص' : 'Private';

  // Post Types
  String get createPost_postType_title =>
      isArabic ? 'نوع المنشور' : 'Post Type';
  String get createPost_postType_regular => isArabic ? 'عادي' : 'Regular';
  String get createPost_postType_announcement =>
      isArabic ? 'إعلان' : 'Announcement';
  String get createPost_postType_event => isArabic ? 'حدث' : 'Event';
  String get createPost_postType_poll => isArabic ? 'استطلاع' : 'Poll';
  String get createPost_postType_knowledge => isArabic ? 'معرفي' : 'Knowledge';

  // Knowledge Domain
  String get createPost_knowledgeDomain_title =>
      isArabic ? 'مجال المعرفة' : 'Knowledge Domain';
  String get createPost_knowledgeDomain_hint =>
      isArabic
          ? "مثال: علوم الحاسوب، الطب، الهندسة..."
          : "Example: Computer Science, Medicine, Engineering...";
  String get createPost_knowledgeDomain_required => isArabic ? ' *' : ' *';

  // Content Input
  String get createPost_content_hintDefault =>
      isArabic ? "ماذا يدور في ذهنك؟" : "What's on your mind?";
  String get createPost_content_hintKnowledge =>
      isArabic
          ? "شارك معرفتك وخبرتك..."
          : "Share your knowledge and expertise...";

  // Bottom Action Buttons
  String get createPost_action_image => isArabic ? 'صورة' : 'Image';
  String get createPost_action_multipleImages =>
      isArabic ? 'عدة صور' : 'Multiple Images';
  String get createPost_action_video => isArabic ? 'فيديو' : 'Video';

  // ===== ERROR MESSAGES =====

  // Image Related Errors
  String get error_imageSelection =>
      isArabic
          ? 'حدث خطأ أثناء اختيار الصورة'
          : 'Error occurred while selecting image';
  String get error_multipleImageSelection =>
      isArabic
          ? 'حدث خطأ أثناء اختيار الصور'
          : 'Error occurred while selecting images';

  // Post Creation Errors
  String get error_emptyContent =>
      isArabic
          ? 'الرجاء إدخال نص أو إضافة صورة'
          : 'Please enter text or add an image';
  String get error_knowledgeDomainRequired =>
      isArabic
          ? 'الرجاء إدخال مجال المعرفة للمنشور المعرفي'
          : 'Please enter knowledge domain for knowledge post';
  String get error_knowledgeDomainTooShort =>
      isArabic
          ? 'مجال المعرفة يجب أن يكون على الأقل حرفين'
          : 'Knowledge domain must be at least 2 characters';
  String get error_notLoggedIn =>
      isArabic ? 'لم يتم تسجيل الدخول' : 'Not logged in';
  String get error_postCreationFailed =>
      isArabic
          ? 'فشل في إنشاء المنشور. الرجاء المحاولة مرة أخرى.'
          : 'Failed to create post. Please try again.';

  // ===== SUCCESS MESSAGES =====
  String get success_postCreated =>
      isArabic ? 'تم نشر المنشور بنجاح' : 'Post published successfully';

  // ===== ACCESSIBILITY =====
  String get accessibility_closeButton => isArabic ? 'إغلاق' : 'Close';
  String get accessibility_publishButton =>
      isArabic ? 'نشر المنشور' : 'Publish Post';
  String get accessibility_removeImage =>
      isArabic ? 'إزالة الصورة' : 'Remove Image';
  String get accessibility_userAvatar =>
      isArabic ? 'صورة المستخدم' : 'User Avatar';
  String get accessibility_visibilityDropdown =>
      isArabic ? 'اختيار خصوصية المنشور' : 'Select Post Visibility';
  String get accessibility_postTypeDropdown =>
      isArabic ? 'اختيار نوع المنشور' : 'Select Post Type';

  // ===== FORM VALIDATION =====
  String get validation_required =>
      isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
  String get validation_tooShort =>
      isArabic ? 'النص قصير جداً' : 'Text is too short';
  String get validation_tooLong =>
      isArabic ? 'النص طويل جداً' : 'Text is too long';

  // ===== LOADING STATES =====
  String get loading_creatingPost =>
      isArabic ? 'جاري إنشاء المنشور...' : 'Creating post...';
  String get loading_uploadingImages =>
      isArabic ? 'جاري رفع الصور...' : 'Uploading images...';

  // ===== DIALOG MESSAGES =====
  String get dialog_discardPost_title =>
      isArabic ? 'تجاهل المنشور؟' : 'Discard Post?';
  String get dialog_discardPost_message =>
      isArabic
          ? 'سيتم فقدان جميع التغييرات التي أجريتها'
          : 'All your changes will be lost';
  String get dialog_button_discard => isArabic ? 'تجاهل' : 'Discard';
  String get dialog_button_keepEditing =>
      isArabic ? 'متابعة التحرير' : 'Keep Editing';
  String get dialog_button_cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get dialog_button_confirm => isArabic ? 'تأكيد' : 'Confirm';

  // ===== HINTS AND PLACEHOLDERS =====
  String get hint_searchKnowledgeDomain =>
      isArabic ? 'ابحث عن مجال المعرفة...' : 'Search for knowledge domain...';
  String get placeholder_postContent =>
      isArabic ? 'اكتب محتوى منشورك هنا...' : 'Write your post content here...';

  // ===== CHARACTER LIMITS =====
  String characterLimit(int current, int max) =>
      isArabic ? '$current من $max حرف' : '$current of $max characters';

  String charactersRemaining(int remaining) =>
      isArabic ? 'متبقي $remaining حرف' : '$remaining characters remaining';

  // ===== IMAGE COUNTS =====
  String imageCount(int count) {
    if (isArabic) {
      if (count == 1) return 'صورة واحدة';
      if (count == 2) return 'صورتان';
      if (count <= 10) return '$count صور';
      return '$count صورة';
    } else {
      return count == 1 ? '$count image' : '$count images';
    }
  }

  String selectedImagesCount(int count) =>
      isArabic
          ? 'تم اختيار ${imageCount(count)}'
          : '${imageCount(count)} selected';

  // ===== POST TYPES DESCRIPTIONS =====
  String get postTypeDescription_regular =>
      isArabic
          ? 'منشور عادي للمشاركة العامة'
          : 'Regular post for general sharing';
  String get postTypeDescription_announcement =>
      isArabic ? 'إعلان مهم أو إشعار' : 'Important announcement or notice';
  String get postTypeDescription_event =>
      isArabic ? 'حدث أو فعالية قادمة' : 'Upcoming event or activity';
  String get postTypeDescription_poll =>
      isArabic ? 'استطلاع رأي للمجتمع' : 'Community poll or survey';
  String get postTypeDescription_knowledge =>
      isArabic ? 'محتوى تعليمي أو معرفي' : 'Educational or knowledge content';

 
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

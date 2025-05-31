import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum for error types to improve error handling
enum AuthErrorType {
  invalidEmail,
  weakPassword,
  emailAlreadyExists,
  usernameAlreadyExists,
  wrongPassword,
  userNotFound,
  tooManyRequests,
  networkError,
  invalidUsername,
  databaseError,
  unknown,
}

class AuthUtils {
  // Method to classify errors and return appropriate error type
  static AuthErrorType _classifyError(String errorMessage) {
    errorMessage = errorMessage.toLowerCase();

    if (errorMessage.contains('email') && errorMessage.contains('format')) {
      return AuthErrorType.invalidEmail;
    } else if (errorMessage.contains('password') &&
        (errorMessage.contains('weak') || errorMessage.contains('short'))) {
      return AuthErrorType.weakPassword;
    } else if (errorMessage.contains('email') &&
        errorMessage.contains('already') &&
        (errorMessage.contains('use') || errorMessage.contains('exist'))) {
      return AuthErrorType.emailAlreadyExists;
    } else if (errorMessage.contains('username') &&
        errorMessage.contains('already') &&
        (errorMessage.contains('use') || errorMessage.contains('exist'))) {
      return AuthErrorType.usernameAlreadyExists;
    } else if (errorMessage.contains('password') &&
        errorMessage.contains('wrong')) {
      return AuthErrorType.wrongPassword;
    } else if (errorMessage.contains('user') &&
        errorMessage.contains('not found')) {
      return AuthErrorType.userNotFound;
    } else if (errorMessage.contains('too many') &&
        errorMessage.contains('request')) {
      return AuthErrorType.tooManyRequests;
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return AuthErrorType.networkError;
    } else if (errorMessage.contains('username') &&
        (errorMessage.contains('invalid') || errorMessage.contains('length'))) {
      return AuthErrorType.invalidUsername;
    } else if (errorMessage.contains('database') ||
        errorMessage.contains('db') ||
        errorMessage.contains('constraint')) {
      return AuthErrorType.databaseError;
    }

    return AuthErrorType.unknown;
  }

  // Get localized error message
  static String getLocalizedErrorMessage(
    BuildContext context,
    AuthErrorType errorType,
    String originalError,
  ) {
    final loc = AppLocalizations.of(context);

    switch (errorType) {
      case AuthErrorType.invalidEmail:
        return loc.invalidEmailError;
      case AuthErrorType.weakPassword:
        return loc.weakPasswordError;
      case AuthErrorType.emailAlreadyExists:
        return loc.emailExistsError;
      case AuthErrorType.usernameAlreadyExists:
        return loc.usernameExistsError;
      case AuthErrorType.wrongPassword:
        return loc.wrongPasswordError;
      case AuthErrorType.userNotFound:
        return loc.userNotFoundError;
      case AuthErrorType.tooManyRequests:
        return loc.tooManyRequestsError;
      case AuthErrorType.networkError:
        return loc.networkError;
      case AuthErrorType.invalidUsername:
        return loc.invalidUsernameError;
      case AuthErrorType.databaseError:
        return loc.databaseError;
      case AuthErrorType.unknown:
        return kDebugMode ? originalError : loc.generalAuthError;
    }
  }

  // Helper method to hash passwords using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? bio,
    String? profileImageUrl,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Check if username already exists in users table
      final usernameCheck =
          await supabase
              .from('users')
              .select('username')
              .eq('username', username)
              .maybeSingle();

      if (usernameCheck != null) {
        return 'username_already_exists';
      }

      // Step 2: Create user in authentication system
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return 'signup_failed';
      }

      final userId = authResponse.user!.id;

      // Step 3: Insert user data into users table
      await supabase.from('users').insert({
        'id': userId,
        'username': username,
        'email': email,
        'display_name': displayName,
        'bio': bio,
        'profile_image_url': profileImageUrl,
        'password_hash': _hashPassword(password), // Store hashed password
      });

      // Step 4: Create default privacy settings
      // Note: This is handled by the trigger defined in the database schema

      return null; // Success
    } catch (e) {
      if (e.toString().contains('duplicate') &&
          e.toString().contains('username')) {
        return 'username_already_exists';
      } else if (e.toString().contains('duplicate') &&
          e.toString().contains('email')) {
        return 'email_already_exists';
      }
      return e.toString(); // Will be classified later
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Sign in with Supabase authentication
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'invalid_credentials';
      }

      // Step 2: Update user's last activity timestamp
      await supabase
          .from('users')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('id', response.user!.id);

      return null; // Success
    } catch (e) {
      if (e is AuthException) {
        if (e.message.contains('Invalid login credentials')) {
          return 'invalid_credentials';
        }
      }
      return e.toString(); // Will be classified later
    }
  }

  static Future<String?> signInWithUsername({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Get user email from username
      final userRecord =
          await supabase
              .from('users')
              .select('email')
              .eq('username', username)
              .maybeSingle();

      if (userRecord == null) {
        return 'user_not_found';
      }

      // Step 2: Use the email to sign in
      return signIn(
        email: userRecord['email'] as String,
        password: password,
        context: context,
      );
    } catch (e) {
      return e.toString(); // Will be classified later
    }
  }

  static Future<void> signOut() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Update last active before signing out
      try {
        await supabase
            .from('users')
            .update({'last_active': DateTime.now().toIso8601String()})
            .eq('id', user.id);
      } catch (e) {
        // Catch but don't prevent sign out if this fails
        if (kDebugMode) {
          print('Error updating last active: $e');
        }
      }
    }

    await supabase.auth.signOut();
  }

  static Future<String?> resetPassword(
    String email,
    BuildContext context,
  ) async {
    try {
      // Check if email exists in the database
      final userCheck =
          await supabase
              .from('users')
              .select('email')
              .eq('email', email)
              .maybeSingle();

      if (userCheck == null) {
        return 'user_not_found';
      }

      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.socialapp://reset-password/',
      );

      return null; // Success
    } catch (e) {
      return e.toString(); // Will be classified later
    }
  }

  static Future<String?> updatePassword(
    String newPassword,
    BuildContext context,
  ) async {
    try {
      // Update password in auth system
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      // Update password hash in users table
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({
              'password_hash': _hashPassword(newPassword),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
      }

      return null; // Success
    } catch (e) {
      return e.toString(); // Will be classified later
    }
  }

  static Future<String?> updateUserProfile({
    String? displayName,
    String? bio,
    String? profileImageUrl,
    required BuildContext context,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return 'not_authenticated';
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['display_name'] = displayName;
      }

      if (bio != null) {
        updates['bio'] = bio;
      }

      if (profileImageUrl != null) {
        updates['profile_image_url'] = profileImageUrl;
      }

      await supabase.from('users').update(updates).eq('id', user.id);

      return null; // Success
    } catch (e) {
      return e.toString(); // Will be classified later
    }
  }

  static Future<String?> deleteAccount(BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return 'not_authenticated';
      }

      // Delete user from database
      // Note: Row Level Security and database triggers should handle cascading deletion
      await supabase.from('users').delete().eq('id', user.id);

      // Sign out
      await supabase.auth.signOut();

      return null; // Success
    } catch (e) {
      return e.toString(); // Will be classified later
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final userProfile =
          await supabase
              .from('users_with_counts') // Using the view defined in schema
              .select()
              .eq('id', user.id)
              .maybeSingle();

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  // Helper method to handle errors consistently
  static String handleAuthError(BuildContext context, String? error) {
    if (error == null) return '';

    // Check for specific error keys first
    if (error == 'signup_failed') {
      return AppLocalizations.of(context).signupFailed;
    } else if (error == 'invalid_credentials') {
      return AppLocalizations.of(context).invalidCredentials;
    } else if (error == 'username_already_exists') {
      return AppLocalizations.of(context).usernameExistsError;
    } else if (error == 'email_already_exists') {
      return AppLocalizations.of(context).emailExistsError;
    } else if (error == 'user_not_found') {
      return AppLocalizations.of(context).userNotFoundError;
    } else if (error == 'not_authenticated') {
      return AppLocalizations.of(context).notAuthenticatedError;
    }

    // Classify and translate the error
    final errorType = _classifyError(error);
    return getLocalizedErrorMessage(context, errorType, error);
  }
}

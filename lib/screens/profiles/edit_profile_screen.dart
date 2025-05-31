import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/utils/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserService _userService;
  UserModel? _user;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  AccountType _accountType =
      AccountType.public; // Changed from String to AccountType
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  String? _imageUrl;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _userService = UserService(supabase);
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _userService.getUserById(
        widget.userId,
        context,
      );

      setState(() {
        _user = currentUser;
        _displayNameController.text = currentUser.displayName;
        _bioController.text = currentUser.bio ?? '';
        _accountType = currentUser.accountType;
        _imageUrl = currentUser.profileImageUrl;
        _usernameController.text = currentUser.username;
        _emailController.text = currentUser.email;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل بيانات المستخدم: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _hasChanged = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanged) {
      Navigator.of(context).pop();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedUser = await _userService.updateProfile(
        userId: widget.userId,
        context: context,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        accountType: _accountType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
        } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ignore: unused_element
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    });
  }

  void _showErrorSnackBar(String error) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    });
  }

  // Add onChange handler for form fields
  void _onFormChanged() {
    if (!_hasChanged) {
      setState(() => _hasChanged = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.editProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.editProfile)),
        body: Center(child: Text(localizations.failedToLoadUserData)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      localizations.save,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          onChanged: _onFormChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null && _imageUrl!.isNotEmpty
                                      ? NetworkImage(_imageUrl!)
                                      : null)
                                  as ImageProvider<Object>?,
                      child:
                          (_imageFile == null &&
                                  (_imageUrl == null || _imageUrl!.isEmpty))
                              ? const Icon(
                                Icons.person,
                                size: 54,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Username (اختياري لكن يجب أن يكون غير فارغ)
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  hintText: 'اسم المستخدم',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.alternate_email),
                  helperText: 'اسم المستخدم (يجب أن يكون فريدًا)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم المستخدم مطلوب';
                  }
                  if (value.trim().length < 3) {
                    return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (إجباري)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  helperText: 'البريد الإلكتروني الخاص بك',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'صيغة البريد الإلكتروني غير صحيحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Display Name (اختياري)
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: localizations.displayName,
                  hintText: localizations.displayName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  helperText:
                      '${localizations.displayName} (${localizations.optional})',
                ),
                validator: (value) {
                  // ليس إجباريًا
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio (اختياري)
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: localizations.bio,
                  hintText: localizations.bio,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.info_outline),
                  helperText:
                      '${localizations.bio} (${localizations.optional})',
                ),
                maxLines: 3,
                validator: (value) => null,
              ),
              const SizedBox(height: 16),

              // Account Type (اختياري)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.accountType,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'PUBLIC',
                              groupValue: _accountType.name,
                              onChanged:
                                  (v) => setState(() {
                                    _accountType = AccountType.public;
                                    _hasChanged = true;
                                  }),
                            ),
                            Flexible(
                              child: Text(
                                localizations.publicAccount,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'PRIVATE',
                              groupValue: _accountType.name,
                              onChanged:
                                  (v) => setState(() {
                                    _accountType = AccountType.private;
                                    _hasChanged = true;
                                  }),
                            ),
                            Flexible(
                              child: Text(
                                localizations.privateAccount,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            localizations.saveChanges,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

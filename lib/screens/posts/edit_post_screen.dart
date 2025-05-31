import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/post_model.dart';
import 'package:social_app/services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _contentController;
  late bool _isPublic;
  bool _isSubmitting = false;

  // للوسائط الموجودة والمحذوفة
  List<dynamic> _existingMedia = [];
  final List<String> _mediaToDelete = [];

  // للصور الجديدة
  final List<File> _newImages = [];

  final PostService _postService = PostService(supabase);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _isPublic = widget.post.visibility == 'PUBLIC';

    // استرجاع الوسائط الموجودة
    if (widget.post.media != null) {
      _existingMedia = List.from(widget.post.media!);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _newImages.add(File(pickedImage.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء اختيار الصورة');
      debugPrint('Error picking image: $e');
    }
  }

  // دالة لاختيار عدة صور
  Future<void> _pickMultipleImages() async {
    try {
      final pickedImages = await _picker.pickMultiImage(imageQuality: 80);

      if (pickedImages.isNotEmpty) {
        setState(() {
          for (var image in pickedImages) {
            _newImages.add(File(image.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء اختيار الصور');
      debugPrint('Error picking multiple images: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // دالة لإزالة صورة موجودة مسبقاً
  void _removeExistingMedia(int index) {
    final mediaId = _existingMedia[index].id;

    setState(() {
      // إضافة معرف الوسائط إلى قائمة الحذف
      _mediaToDelete.add(mediaId);
      // إزالة من واجهة المستخدم
      _existingMedia.removeAt(index);
    });
  }

  // دالة لإزالة صورة جديدة
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _updatePost() async {
    // التحقق من المحتوى
    if (_contentController.text.trim().isEmpty &&
        _existingMedia.isEmpty &&
        _newImages.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال نص أو إضافة صورة');
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('لم يتم تسجيل الدخول');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // تحديث المنشور الأساسي أولاً
      await _postService.updatePost(
        postId: widget.post.id,
        content: _contentController.text.trim(),
        visibility: _isPublic ? 'PUBLIC' : 'PRIVATE',
      );

      // حذف الوسائط المحددة للحذف
      for (String mediaId in _mediaToDelete) {
        await _postService.deleteMedia(mediaId);
      }

      // إضافة الوسائط الجديدة إن وجدت
      if (_newImages.isNotEmpty) {
        await _postService.addMediaToPost(
          postId: widget.post.id,
          mediaFiles: _newImages,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث المنشور بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );

      Navigator.of(context).pop(true); // عودة بنجاح التحديث
    } catch (e) {
      debugPrint('Detailed error during post update: $e');
      _showErrorSnackBar('فشل في تحديث المنشور. الرجاء المحاولة مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          'تعديل المنشور',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _updatePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'تحديث',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المستخدم
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          widget.post.author?.profileImageUrl != null
                              ? NetworkImage(
                                widget.post.author!.profileImageUrl!,
                              )
                              : null,
                      backgroundColor: theme.primaryColor,
                      child:
                          widget.post.author?.profileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.author?.displayName ??
                                widget.post.author?.username ??
                                'أنت',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                isDense: true,
                                value: _isPublic,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.primaryColor,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: true,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.public,
                                          size: 18,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text('عام'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: false,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          size: 18,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text('خاص'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _isPublic = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // إدخال المحتوى
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: "ماذا يدور في ذهنك؟",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  minLines: 5,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),

              const SizedBox(height: 20),

              // عرض الوسائط الموجودة
              if (_existingMedia.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'الوسائط الحالية',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          _existingMedia.length,
                          (index) => Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      _existingMedia[index].url,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeExistingMedia(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ],

              // عرض الصور الجديدة
              if (_newImages.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'الوسائط الجديدة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          _newImages.length,
                          (index) => Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_newImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureButton(
                icon: Icons.image,
                label: 'صورة',
                onTap: _pickImage,
                color: Colors.green,
              ),
              _buildFeatureButton(
                icon: Icons.collections,
                label: 'عدة صور',
                onTap: _pickMultipleImages,
                color: Colors.purple,
              ),
              _buildFeatureButton(
                icon: Icons.location_on,
                label: 'موقع',
                onTap: () {},
                color: Colors.red,
              ),
              _buildFeatureButton(
                icon: Icons.tag,
                label: 'وسم',
                onTap: () {},
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}

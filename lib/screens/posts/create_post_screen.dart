// lib/screens/create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/services/post_service.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _knowledgeDomainController =
      TextEditingController();
  bool _isPublic = true;
  bool _isSubmitting = false;
  String _selectedPostType = 'REGULAR';

  final List<File> _selectedImages = [];
  final PostService _postService = PostService(supabase);
  final ImagePicker _picker = ImagePicker();

  // Post types mapping
  Map<String, String> get _postTypes {
    final localizations = AppLocalizations.of(context);
    return {
      'REGULAR': localizations.createPost_postType_regular,
      'ANNOUNCEMENT': localizations.createPost_postType_announcement,
      'EVENT': localizations.createPost_postType_event,
      'POLL': localizations.createPost_postType_poll,
      'KNOWLEDGE': localizations.createPost_postType_knowledge,
    };
  }

  Future<void> _pickImage() async {
    final localizations = AppLocalizations.of(context);
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImages.add(File(pickedImage.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar(localizations.error_imageSelection);
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    final localizations = AppLocalizations.of(context);
    try {
      final pickedImages = await _picker.pickMultiImage(imageQuality: 80);

      if (pickedImages.isNotEmpty) {
        setState(() {
          for (var image in pickedImages) {
            _selectedImages.add(File(image.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar(localizations.error_multipleImageSelection);
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _createPost() async {
    final localizations = AppLocalizations.of(context);

    // التحقق من المحتوى
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      _showErrorSnackBar(localizations.error_emptyContent);
      return;
    }

    // التحقق من مجال المعرفة للمنشورات المعرفية
    if (_selectedPostType == 'KNOWLEDGE') {
      if (_knowledgeDomainController.text.trim().isEmpty) {
        _showErrorSnackBar(localizations.error_knowledgeDomainRequired);
        return;
      }
      if (_knowledgeDomainController.text.trim().length < 2) {
        _showErrorSnackBar(localizations.error_knowledgeDomainTooShort);
        return;
      }
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar(localizations.error_notLoggedIn);
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _postService.createPost(
        authorId: currentUser.id,
        content: _contentController.text.trim(),
        visibility: _isPublic ? 'PUBLIC' : 'PRIVATE',
        typeId: _selectedPostType,
        knowledgeDomain:
            _selectedPostType == 'KNOWLEDGE'
                ? _knowledgeDomainController.text.trim()
                : null,
        mediaFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (!mounted) return;

      _showSuccessSnackBar(localizations.success_postCreated);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Detailed error during post creation: $e');
      _showErrorSnackBar(localizations.error_postCreationFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Color _getPostTypeColor(String type) {
    switch (type) {
      case 'REGULAR':
        return Colors.blue;
      case 'ANNOUNCEMENT':
        return Colors.orange;
      case 'EVENT':
        return Colors.purple;
      case 'POLL':
        return Colors.teal;
      case 'KNOWLEDGE':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getPostTypeIcon(String type) {
    switch (type) {
      case 'REGULAR':
        return Icons.text_snippet;
      case 'ANNOUNCEMENT':
        return Icons.campaign;
      case 'EVENT':
        return Icons.event;
      case 'POLL':
        return Icons.poll;
      case 'KNOWLEDGE':
        return Icons.school;
      default:
        return Icons.text_snippet;
    }
  }

  Future<bool> _onWillPop() async {
    final localizations = AppLocalizations.of(context);

    // إذا لم يكن هناك محتوى، السماح بالخروج مباشرة
    if (_contentController.text.trim().isEmpty &&
        _selectedImages.isEmpty &&
        _knowledgeDomainController.text.trim().isEmpty) {
      return true;
    }

    // إظهار تأكيد الخروج
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.dialog_discardPost_title),
            content: Text(localizations.dialog_discardPost_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.dialog_button_keepEditing),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(localizations.dialog_button_discard),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          centerTitle: true,
          title: Text(
            localizations.createPost_appBar_title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.primaryColor),
            tooltip: localizations.accessibility_closeButton,
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createPost,
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
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                            semanticsLabel: localizations.loading_creatingPost,
                          ),
                        )
                        : Text(
                          localizations.createPost_appBar_publishButton,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                _buildUserInfoSection(theme, localizations),
                const SizedBox(height: 20),

                // اختيار نوع المنشور
                _buildPostTypeSection(theme, localizations),
                const SizedBox(height: 20),

                // حقل مجال المعرفة
                if (_selectedPostType == 'KNOWLEDGE') ...[
                  _buildKnowledgeDomainSection(theme, localizations),
                  const SizedBox(height: 20),
                ],

                // إدخال المحتوى
                _buildContentSection(theme, localizations),
                const SizedBox(height: 20),

                // عرض الصور المختارة
                if (_selectedImages.isNotEmpty) ...[
                  _buildSelectedImagesSection(localizations),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomActionBar(theme, localizations),
      ),
    );
  }

  Widget _buildUserInfoSection(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
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
            backgroundColor: theme.primaryColor,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
              semanticLabel: localizations.accessibility_userAvatar,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.createPost_userInfo_you,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
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
                                  Text(
                                    localizations.createPost_visibility_public,
                                  ),
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
                                  Text(
                                    localizations.createPost_visibility_private,
                                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeSection(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.createPost_postType_title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _getPostTypeColor(_selectedPostType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPostTypeColor(_selectedPostType).withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedPostType,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _getPostTypeColor(_selectedPostType),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items:
                    _postTypes.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              _getPostTypeIcon(entry.key),
                              size: 20,
                              color: _getPostTypeColor(entry.key),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              entry.value,
                              style: TextStyle(
                                color: _getPostTypeColor(entry.key),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPostType = newValue;
                      if (newValue != 'KNOWLEDGE') {
                        _knowledgeDomainController.clear();
                      }
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeDomainSection(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.createPost_knowledgeDomain_title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                localizations.createPost_knowledgeDomain_required,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _knowledgeDomainController,
            decoration: InputDecoration(
              hintText: localizations.createPost_knowledgeDomain_hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.indigo),
              ),
              filled: true,
              fillColor: Colors.indigo.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            textDirection:
                localizations.isArabic ? TextDirection.rtl : TextDirection.ltr,
            textAlign:
                localizations.isArabic ? TextAlign.right : TextAlign.left,
            maxLength: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme, AppLocalizations localizations) {
    return Container(
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
        decoration: InputDecoration(
          hintText:
              _selectedPostType == 'KNOWLEDGE'
                  ? localizations.createPost_content_hintKnowledge
                  : localizations.createPost_content_hintDefault,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        maxLines: null,
        minLines: 5,
        textDirection:
            localizations.isArabic ? TextDirection.rtl : TextDirection.ltr,
        textAlign: localizations.isArabic ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildSelectedImagesSection(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectedImagesCount(_selectedImages.length),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _selectedImages.length,
              (index) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                          semanticLabel:
                              localizations.accessibility_removeImage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
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
              label: localizations.createPost_action_image,
              onTap: _pickImage,
              color: Colors.green,
            ),
            _buildFeatureButton(
              icon: Icons.collections,
              label: localizations.createPost_action_multipleImages,
              onTap: _pickMultipleImages,
              color: Colors.purple,
            ),
            _buildFeatureButton(
              icon: Icons.video_call,
              label: localizations.createPost_action_video,
              onTap: () {
                // TODO: Implement video selection
              },
              color: Colors.grey,
            ),
          ],
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
    _knowledgeDomainController.dispose();
    super.dispose();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/constants.dart';
import 'package:social_app/models/achievement_model.dart';
import 'package:social_app/services/achievement_service.dart';

class AddAchievementScreen extends StatefulWidget {
  const AddAchievementScreen({super.key});

  @override
  State<AddAchievementScreen> createState() => _AddAchievementScreenState();
}

class _AddAchievementScreenState extends State<AddAchievementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  AchievementType _selectedType = AchievementType.personal;
  File? _imageFile;
  bool _isPublic = true;
  bool _isSubmitting = false;
  final _achievementService = AchievementService(supabase);
  Duration? _selectedDuration;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submitAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // التحقق من حجم الصورة
        final fileSize = await _imageFile!.length();
        if (fileSize > 5 * 1024 * 1024) {
          // 5MB
          throw Exception('حجم الصورة كبير جداً. الحد الأقصى 5 ميجابايت');
        }

        imageUrl = await _achievementService.uploadAchievementImage(
          await _imageFile!.readAsBytes(),
          'achievement_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final achievement = await _achievementService.createAchievement(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        achievedDate: DateTime.now(),
        type: _selectedType,
        imageUrl: imageUrl,
        isPublic: _isPublic,
        duration: _selectedDuration,
      );

      if (achievement != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الإنجاز بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة الإنجاز: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Achievement'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAchievement,
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الإنجاز
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      image:
                          _imageFile != null
                              ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _imageFile == null
                            ? Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: theme.colorScheme.primary,
                            )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // عنوان الإنجاز
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Achievement Title',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // وصف الإنجاز
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // نوع الإنجاز
              DropdownButtonFormField<AchievementType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: const OutlineInputBorder(),
                ),
                items:
                    AchievementType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // مدة الإنجاز (اختياري)
              DropdownButtonFormField<Duration?>(
                value: _selectedDuration,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('No Duration')),
                  DropdownMenuItem(
                    value: const Duration(days: 1),
                    child: Text('1 Day'),
                  ),
                  DropdownMenuItem(
                    value: const Duration(days: 7),
                    child: Text('1 Week'),
                  ),
                  DropdownMenuItem(
                    value: const Duration(days: 30),
                    child: Text('1 Month'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedDuration = value);
                },
              ),
              const SizedBox(height: 16),

              // خصوصية الإنجاز
              SwitchListTile(
                title: Text('Public Achievement'),
                subtitle: Text('Make this achievement visible to others'),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

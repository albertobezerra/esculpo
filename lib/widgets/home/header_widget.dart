// lib/widgets/home/header_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_image.jpg');
    final file = File(imagePath);
    if (await file.exists()) {
      setState(() => _profileImage = file);
    }
  }

  Future<void> _saveProfileImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_image.jpg');
    await image.copy(imagePath);
    setState(() => _profileImage = File(imagePath));
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _saveProfileImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int hour = now.hour;

    String greeting;
    String emoji;
    if (hour >= 6 && hour < 12) {
      greeting = Localizations.localeOf(context).languageCode == 'pt'
          ? 'Bom dia'
          : 'Good morning';
      emoji = '🔥';
    } else if (hour >= 12 && hour < 18) {
      greeting = Localizations.localeOf(context).languageCode == 'pt'
          ? 'Boa tarde'
          : 'Good afternoon';
      emoji = '☀️';
    } else {
      greeting = Localizations.localeOf(context).languageCode == 'pt'
          ? 'Boa noite'
          : 'Good evening';
      emoji = '🌙';
    }

    final userName = user?.displayName ?? 'User';

    return Row(
      children: [
        GestureDetector(
          onTap: _profileImage == null
              ? _pickImage
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'pt'
                            ? 'Alterar foto'
                            : 'Change photo',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'pt'
                                ? 'Cancelar'
                                : 'Cancel',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'pt'
                                ? 'Alterar'
                                : 'Change',
                          ),
                        ),
                      ],
                    ),
                  );
                },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: _profileImage == null
                  ? const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryPurple],
                    )
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGray,
                    ),
              ),
              Text(
                userName,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textDark,
        ),
      ],
    );
  }
}

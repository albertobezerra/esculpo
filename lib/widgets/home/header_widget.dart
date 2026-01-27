// lib/widgets/home/header_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class HeaderWidget extends ConsumerWidget {
  const HeaderWidget({super.key});

  Future<void> _pickAndCropImage(BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('📸 Iniciando seleção de imagem...');

      // 1. Seleciona a imagem
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ Nenhuma imagem foi selecionada');
        return;
      }

      debugPrint('✅ Imagem selecionada: ${pickedFile.path}');

      // 2. Abre o crop editor
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Foto',
            toolbarColor: AppColors.primaryPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            activeControlsWidgetColor: AppColors.primaryGreen,
            cropFrameColor: AppColors.primaryPurple,
            backgroundColor: Colors.black,
          ),
          IOSUiSettings(
            title: 'Editar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile == null) {
        debugPrint('⚠️ Crop cancelado pelo usuário');
        return;
      }

      debugPrint('✅ Imagem cortada: ${croppedFile.path}');

      // 3. Faz upload da imagem cortada
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Salvando foto...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // ✅ CORREÇÃO: Acessa o service e chama updateImage
      await ref
          .read(profileImageProvider.notifier)
          .updateImage(File(croppedFile.path));

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil atualizada!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Upload concluído com sucesso!');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao selecionar/fazer upload da imagem: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        // Tenta fechar o dialog de loading se estiver aberto
        try {
          Navigator.pop(context);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    final imageState = ref.watch(profileImageProvider);

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
          onTap: () {
            if (imageState.bytes == null && !imageState.isLoading) {
              _pickAndCropImage(context, ref);
            } else if (imageState.bytes != null) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    Localizations.localeOf(context).languageCode == 'pt'
                        ? 'Alterar foto'
                        : 'Change photo',
                  ),
                  content: Text(
                    Localizations.localeOf(context).languageCode == 'pt'
                        ? 'Deseja alterar a sua foto de perfil?'
                        : 'Do you want to change your profile photo?',
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
                        _pickAndCropImage(context, ref);
                      },
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'pt'
                            ? 'Alterar'
                            : 'Change',
                        style: const TextStyle(color: AppColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: imageState.bytes != null
                  ? DecorationImage(
                      image: MemoryImage(imageState.bytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: imageState.bytes == null && !imageState.isLoading
                  ? const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryPurple],
                    )
                  : null,
              color: imageState.isLoading ? Colors.grey[300] : null,
            ),
            child: imageState.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple),
                      ),
                    ),
                  )
                : imageState.bytes == null
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textGray),
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

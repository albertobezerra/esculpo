// lib/servicos/profile_image_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class ProfileImageState {
  final String? url;
  final Uint8List? bytes;
  final bool isLoading;

  ProfileImageState({
    this.url,
    this.bytes,
    this.isLoading = false,
  });

  ProfileImageState copyWith({
    String? url,
    Uint8List? bytes,
    bool? isLoading,
  }) {
    return ProfileImageState(
      url: url ?? this.url,
      bytes: bytes ?? this.bytes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ✅ Use ChangeNotifier ao invés de StateNotifier
class ProfileImageService extends ChangeNotifier {
  ProfileImageState _state = ProfileImageState(isLoading: true);

  ProfileImageState get state => _state;

  ProfileImageService() {
    _loadImage();
  }

  void _updateState(ProfileImageState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _loadImage() async {
    final stopwatch = Stopwatch()..start();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _updateState(ProfileImageState(isLoading: false));
        return;
      }

      debugPrint('🔍 Buscando foto de perfil para userId: $userId');

      // 1. Busca URL do Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      final photoUrl = userDoc.data()?['photoURL'] as String?;

      if (photoUrl == null || photoUrl.isEmpty) {
        debugPrint('⚠️ Nenhuma foto de perfil salva no Firestore');
        _updateState(ProfileImageState(isLoading: false));
        return;
      }

      debugPrint('🔗 URL da foto encontrada: $photoUrl');

      // 2. Verifica cache local primeiro
      final localFile = await _getLocalCacheFile();
      if (await localFile.exists()) {
        final bytes = await localFile.readAsBytes();
        debugPrint(
            '✅ Carregado do cache local (${bytes.length} bytes) em ${stopwatch.elapsedMilliseconds}ms');
        _updateState(ProfileImageState(
          url: photoUrl,
          bytes: bytes,
          isLoading: false,
        ));
        return;
      }

      // 3. Baixa do Firebase Storage e cacheia
      debugPrint('⬇️ Baixando do Firebase Storage...');
      final response = await http.get(Uri.parse(photoUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Salva no cache local
        await localFile.writeAsBytes(bytes);

        debugPrint('✅ Total load time: ${stopwatch.elapsedMilliseconds}ms');
        _updateState(ProfileImageState(
          url: photoUrl,
          bytes: bytes,
          isLoading: false,
        ));
      } else {
        throw Exception('Falha ao baixar imagem: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar imagem: $e');
      _updateState(ProfileImageState(isLoading: false));
    }

    stopwatch.stop();
  }

  Future<File> _getLocalCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'profile_image_cache.jpg'));
  }

  Future<void> updateImage(File newImage) async {
    _updateState(_state.copyWith(isLoading: true));
    final stopwatch = Stopwatch()..start();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado');

      debugPrint('🖼️ Processando imagem...');

      // 1. Comprime a imagem
      final bytes = await newImage.readAsBytes();
      debugPrint(
          '⏱️ Imagem original: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Falha ao decodificar imagem');

      final resized = img.copyResize(
        image,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.linear,
      );

      final compressed = img.encodeJpg(resized, quality: 85);
      debugPrint(
          '⏱️ Imagem comprimida: ${(compressed.length / 1024).toStringAsFixed(2)} KB');

      // 2. Upload para Firebase Storage
      debugPrint('⬆️ Fazendo upload para Firebase Storage...');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      final uploadTask = await storageRef.putData(
        Uint8List.fromList(compressed),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Upload concluído: $downloadUrl');

      // 3. Salva URL no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({'photoURL': downloadUrl});

      debugPrint('✅ URL salva no Firestore');

      // 4. Atualiza cache local
      final cacheFile = await _getLocalCacheFile();
      await cacheFile.writeAsBytes(compressed);

      // 5. Atualiza estado
      _updateState(ProfileImageState(
        url: downloadUrl,
        bytes: Uint8List.fromList(compressed),
        isLoading: false,
      ));

      debugPrint('✅ Processo completo em ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao atualizar imagem: $e');
      debugPrint('Stack trace: $stackTrace');
      _updateState(_state.copyWith(isLoading: false));
      rethrow;
    }

    stopwatch.stop();
  }

  void refresh() => _loadImage();
}

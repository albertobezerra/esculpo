import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FotoProgressoServico {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Tirar foto com a câmera
  Future<XFile?> tirarFotoCamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      return foto;
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      return null;
    }
  }

  // Escolher foto da galeria
  Future<XFile?> escolherFotoGaleria() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return foto;
    } catch (e) {
      debugPrint('Erro ao escolher foto: $e');
      return null;
    }
  }

  // Upload da foto para Firebase Storage
  Future<String?> uploadFoto(XFile foto) async {
    try {
      final String userId = _auth.currentUser!.uid;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName =
          'progresso_${userId}_$timestamp${path.extension(foto.path)}';

      // ✅ CAMINHO CORRETO
      final Reference ref = _storage.ref('fotos_progresso/$userId/$fileName');

      final File file = File(foto.path);

      // ✅ VERIFICAR SE O ARQUIVO EXISTE
      if (!await file.exists()) {
        debugPrint('Arquivo não existe: ${foto.path}');
        return null;
      }

      debugPrint('📤 Iniciando upload: $fileName');

      final UploadTask uploadTask = ref.putFile(file);

      // ✅ MONITORAR PROGRESSO
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload: ${(progress * 100).toStringAsFixed(0)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Upload completo: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da foto: $e');
      return null;
    }
  }

  // Salvar foto de progresso no Firestore
  Future<bool> salvarFotoProgresso({
    required String urlFoto,
    double? peso,
    Map<String, double>? medidas,
    String? observacoes,
  }) async {
    try {
      // ✅ ADICIONAR ESTES LOGS
      debugPrint('🔐 User autenticado: ${_auth.currentUser != null}');
      debugPrint('🔐 User ID: ${_auth.currentUser?.uid}');

      final String userId = _auth.currentUser!.uid;

      debugPrint('💾 Tentando salvar no Firestore...');

      await _firestore.collection('fotosProgresso').add({
        'usuarioId': userId,
        'data': FieldValue.serverTimestamp(),
        'urlFoto': urlFoto,
        'peso': peso,
        'medidas': medidas,
        'observacoes': observacoes,
      });

      debugPrint('✅ Salvo com sucesso no Firestore!');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao salvar foto de progresso: $e');
      return false;
    }
  }

  // Buscar todas as fotos de progresso do usuário
  Stream<List<Map<String, dynamic>>> buscarFotosProgresso() {
    final String userId = _auth.currentUser!.uid;

    return _firestore
        .collection('fotosProgresso')
        .where('usuarioId', isEqualTo: userId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Buscar fotos para comparação (primeira e última)
  Future<Map<String, dynamic>?> buscarFotosComparacao() async {
    try {
      final String userId = _auth.currentUser!.uid;

      final QuerySnapshot fotosSnapshot = await _firestore
          .collection('fotosProgresso')
          .where('usuarioId', isEqualTo: userId)
          .orderBy('data', descending: false)
          .get();

      if (fotosSnapshot.docs.isEmpty) return null;
      if (fotosSnapshot.docs.length == 1) {
        final primeira =
            fotosSnapshot.docs.first.data() as Map<String, dynamic>;
        return {
          'primeira': primeira,
          'ultima': primeira,
          'totalFotos': 1,
        };
      }

      final primeira = fotosSnapshot.docs.first.data() as Map<String, dynamic>;
      final ultima = fotosSnapshot.docs.last.data() as Map<String, dynamic>;

      return {
        'primeira': primeira,
        'ultima': ultima,
        'totalFotos': fotosSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Erro ao buscar fotos para comparação: $e');
      return null;
    }
  }

  // Deletar foto
  Future<bool> deletarFoto(String fotoId, String urlFoto) async {
    try {
      // Deletar do Storage
      final ref = _storage.refFromURL(urlFoto);
      await ref.delete();

      // Deletar do Firestore
      await _firestore.collection('fotosProgresso').doc(fotoId).delete();

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar foto: $e');
      return false;
    }
  }
}

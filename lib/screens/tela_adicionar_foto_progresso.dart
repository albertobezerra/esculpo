import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/providers.dart';
import '../core/theme/app_theme.dart';

class TelaAdicionarFotoProgresso extends ConsumerStatefulWidget {
  const TelaAdicionarFotoProgresso({super.key});

  @override
  ConsumerState<TelaAdicionarFotoProgresso> createState() =>
      _TelaAdicionarFotoProgressoState();
}

class _TelaAdicionarFotoProgressoState
    extends ConsumerState<TelaAdicionarFotoProgresso> {
  XFile? _fotoSelecionada;
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _peitoController = TextEditingController();
  final TextEditingController _bracoController = TextEditingController();
  final TextEditingController _cinturaController = TextEditingController();
  final TextEditingController _pernaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _pesoController.dispose();
    _peitoController.dispose();
    _bracoController.dispose();
    _cinturaController.dispose();
    _pernaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    final fotoServico = ref.read(fotoProgressoServicoProvider);
    final foto = await fotoServico.tirarFotoCamera();

    if (foto != null) {
      setState(() {
        _fotoSelecionada = foto;
      });
    }
  }

  Future<void> _escolherDaGaleria() async {
    final fotoServico = ref.read(fotoProgressoServicoProvider);
    final foto = await fotoServico.escolherFotoGaleria();

    if (foto != null) {
      setState(() {
        _fotoSelecionada = foto;
      });
    }
  }

  Future<void> _salvarFoto() async {
    if (_fotoSelecionada == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione uma foto primeiro'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final fotoServico = ref.read(fotoProgressoServicoProvider);

      // ✅ ADICIONAR TIMEOUT
      final urlFoto = await fotoServico.uploadFoto(_fotoSelecionada!).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tempo esgotado ao fazer upload da foto');
        },
      );

      if (urlFoto == null) {
        throw Exception('Erro ao fazer upload da foto');
      }

      // Preparar medidas
      Map<String, double>? medidas;
      if (_peitoController.text.isNotEmpty ||
          _bracoController.text.isNotEmpty ||
          _cinturaController.text.isNotEmpty ||
          _pernaController.text.isNotEmpty) {
        medidas = {};
        if (_peitoController.text.isNotEmpty) {
          medidas['peito'] = double.tryParse(_peitoController.text) ?? 0;
        }
        if (_bracoController.text.isNotEmpty) {
          medidas['braco'] = double.tryParse(_bracoController.text) ?? 0;
        }
        if (_cinturaController.text.isNotEmpty) {
          medidas['cintura'] = double.tryParse(_cinturaController.text) ?? 0;
        }
        if (_pernaController.text.isNotEmpty) {
          medidas['perna'] = double.tryParse(_pernaController.text) ?? 0;
        }
      }

      // ✅ ADICIONAR TIMEOUT NO FIRESTORE
      final sucesso = await fotoServico
          .salvarFotoProgresso(
        urlFoto: urlFoto,
        peso: _pesoController.text.isNotEmpty
            ? double.tryParse(_pesoController.text)
            : null,
        medidas: medidas,
        observacoes: _observacoesController.text.isNotEmpty
            ? _observacoesController.text
            : null,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Tempo esgotado ao salvar no banco de dados');
        },
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto salva com sucesso! 📸'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Erro ao salvar no banco de dados');
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('⏱️ ${e.message}\nVerifique sua conexão com a internet'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar foto: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nova Foto de Progresso',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_fotoSelecionada != null)
            TextButton(
              onPressed: _salvando ? null : _salvarFoto,
              child: _salvando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : Text(
                      'Salvar',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview da Foto ou Botões de Seleção
            if (_fotoSelecionada == null) ...[
              _buildBotaoSelecao(
                icon: Icons.camera_alt,
                label: 'Tirar Foto',
                cor: AppColors.primaryGreen,
                onTap: _tirarFoto,
              ),
              SizedBox(height: 12),
              _buildBotaoSelecao(
                icon: Icons.photo_library,
                label: 'Escolher da Galeria',
                cor: AppColors.primaryPurple,
                onTap: _escolherDaGaleria,
              ),
            ] else ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_fotoSelecionada!.path),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _fotoSelecionada = null;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    debugPrint('🔐 Usuário: ${user?.uid}');
                    debugPrint('🔐 Email: ${user?.email}');

                    // Tenta escrever um documento de teste
                    await FirebaseFirestore.instance.collection('teste').add({
                      'mensagem': 'teste',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    debugPrint('✅ Firestore funcionando!');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Firestore funcionando!')),
                    );
                  } catch (e) {
                    debugPrint('❌ Erro Firestore: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Erro: $e')),
                    );
                  }
                },
                child: Text('Testar Firestore'),
              ),
              SizedBox(height: 24),

              // Campos de Dados
              Text(
                'Dados Opcionais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 16),

              // Campo de Peso
              _buildCampoNumerico(
                controller: _pesoController,
                label: 'Peso (kg)',
                icon: Icons.monitor_weight,
              ),

              SizedBox(height: 16),

              // Título Medidas
              Text(
                'Medidas (cm)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 12),

              // Campos de Medidas
              Row(
                children: [
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _peitoController,
                      label: 'Peito',
                      icon: Icons.straighten,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _bracoController,
                      label: 'Braço',
                      icon: Icons.straighten,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _cinturaController,
                      label: 'Cintura',
                      icon: Icons.straighten,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _pernaController,
                      label: 'Perna',
                      icon: Icons.straighten,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Campo de Observações
              TextField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Como você está se sentindo?',
                  prefixIcon: Icon(Icons.notes, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSelecao({
    required IconData icon,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor, width: 2),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cor, size: 32),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }
}

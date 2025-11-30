import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guarda_corpo_2024/servicos/foto_progresso_servico.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../core/theme/app_theme.dart';
import 'tela_adicionar_foto_progresso.dart';
import 'tela_comparacao_fotos.dart';
import 'tela_detalhe_foto_progresso.dart';

class TelaFotosProgresso extends ConsumerWidget {
  const TelaFotosProgresso({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fotoServico = ref.watch(fotoProgressoServicoProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fotos de Progresso',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fotoServico.buscarFotosProgresso(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEstadoVazio(context);
          }

          final fotos = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardComparacao(context, fotoServico),
                SizedBox(height: 24),
                _buildEstatisticas(fotos),
                SizedBox(height: 24),
                Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 16),
                ...fotos.map((foto) => _buildCardFoto(context, foto)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TelaAdicionarFotoProgresso()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: Icon(Icons.camera_alt),
        label: Text('Adicionar Foto'),
      ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 80, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'Nenhuma foto ainda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comece a registrar seu progresso tirando sua primeira foto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TelaAdicionarFotoProgresso()),
                );
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Tirar Primeira Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardComparacao(
      BuildContext context, FotoProgressoServico servico) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: servico.buscarFotosComparacao(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox.shrink();
        }

        final dados = snapshot.data!;
        final primeira = dados['primeira'] as Map<String, dynamic>;
        final ultima = dados['ultima'] as Map<String, dynamic>;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TelaComparacaoFotos(
                  fotoAntes: primeira,
                  fotoDepois: ultima,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.accentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.compare_arrows, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Comparação Antes/Depois',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          primeira['urlFoto'],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ultima['urlFoto'],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Toque para ver detalhes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstatisticas(List<Map<String, dynamic>> fotos) {
    final totalFotos = fotos.length;
    final diasDesdeInicio = fotos.isNotEmpty && fotos.last['data'] != null
        ? DateTime.now()
            .difference((fotos.last['data'] as Timestamp).toDate())
            .inDays
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildCardEstatistica(
            icon: Icons.photo_library,
            valor: totalFotos.toString(),
            label: 'Fotos',
            cor: AppColors.primaryGreen,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildCardEstatistica(
            icon: Icons.calendar_today,
            valor: diasDesdeInicio.toString(),
            label: 'Dias',
            cor: AppColors.accentOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildCardEstatistica({
    required IconData icon,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 32),
          SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFoto(BuildContext context, Map<String, dynamic> foto) {
    final data = (foto['data'] as Timestamp?)?.toDate();
    final dataFormatada = data != null
        ? DateFormat('dd/MM/yyyy').format(data)
        : 'Data desconhecida';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalheFotoProgresso(foto: foto),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                foto['urlFoto'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (foto['peso'] != null)
                        Text(
                          '${foto['peso']} kg',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

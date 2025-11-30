import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../core/theme/app_theme.dart';

class TelaDetalheFotoProgresso extends ConsumerWidget {
  final Map<String, dynamic> foto;

  const TelaDetalheFotoProgresso({
    super.key,
    required this.foto,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = (foto['data'] as Timestamp?)?.toDate();
    final dataFormatada = data != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(data)
        : 'Data desconhecida';

    final peso = foto['peso'] as double?;
    final medidas = foto['medidas'] as Map<String, dynamic>?;
    final observacoes = foto['observacoes'] as String?;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar com Imagem
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onPressed: () => _confirmarDelecao(context, ref),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                foto['urlFoto'],
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: AppColors.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Peso
                  if (peso != null) ...[
                    _buildCardInfo(
                      icon: Icons.monitor_weight,
                      titulo: 'Peso',
                      valor: '${peso.toStringAsFixed(1)} kg',
                      cor: AppColors.primaryGreen,
                    ),
                    SizedBox(height: 16),
                  ],

                  // Medidas
                  if (medidas != null && medidas.isNotEmpty) ...[
                    Text(
                      'Medidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
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
                          if (medidas['peito'] != null)
                            _buildLinhaMedida('Peito', medidas['peito']),
                          if (medidas['braco'] != null)
                            _buildLinhaMedida('Braço', medidas['braco']),
                          if (medidas['cintura'] != null)
                            _buildLinhaMedida('Cintura', medidas['cintura']),
                          if (medidas['perna'] != null)
                            _buildLinhaMedida('Perna', medidas['perna']),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Observações
                  if (observacoes != null && observacoes.isNotEmpty) ...[
                    Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
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
                      child: Text(
                        observacoes,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo({
    required IconData icon,
    required String titulo,
    required String valor,
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cor),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaMedida(String label, dynamic valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          Text(
            '${(valor as num).toStringAsFixed(1)} cm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarDelecao(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deletar Foto'),
        content: Text(
            'Tem certeza que deseja deletar esta foto? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Deletar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final fotoServico = ref.read(fotoProgressoServicoProvider);
      final sucesso = await fotoServico.deletarFoto(
        foto['id'],
        foto['urlFoto'],
      );

      if (context.mounted) {
        if (sucesso) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Foto deletada com sucesso'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

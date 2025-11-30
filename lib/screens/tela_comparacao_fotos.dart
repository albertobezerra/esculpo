import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';

class TelaComparacaoFotos extends StatelessWidget {
  final Map<String, dynamic> fotoAntes;
  final Map<String, dynamic> fotoDepois;

  const TelaComparacaoFotos({
    super.key,
    required this.fotoAntes,
    required this.fotoDepois,
  });

  @override
  Widget build(BuildContext context) {
    final dataAntes = (fotoAntes['data'] as Timestamp?)?.toDate();
    final dataDepois = (fotoDepois['data'] as Timestamp?)?.toDate();

    final pesoAntes = fotoAntes['peso'] as double?;
    final pesoDepois = fotoDepois['peso'] as double?;

    final medidasAntes = fotoAntes['medidas'] as Map<String, dynamic>?;
    final medidasDepois = fotoDepois['medidas'] as Map<String, dynamic>?;

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
          'Comparação',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Fotos Lado a Lado
            Row(
              children: [
                Expanded(
                  child: _buildCardFoto(
                    urlFoto: fotoAntes['urlFoto'],
                    data: dataAntes,
                    label: 'Antes',
                    cor: AppColors.accentOrange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCardFoto(
                    urlFoto: fotoDepois['urlFoto'],
                    data: dataDepois,
                    label: 'Depois',
                    cor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Card de Diferenças
            if (pesoAntes != null && pesoDepois != null)
              _buildCardDiferenca(
                icon: Icons.monitor_weight,
                titulo: 'Peso',
                valorAntes: pesoAntes,
                valorDepois: pesoDepois,
                unidade: 'kg',
              ),

            SizedBox(height: 16),

            // Medidas
            if (medidasAntes != null && medidasDepois != null) ...[
              if (medidasAntes['peito'] != null &&
                  medidasDepois['peito'] != null)
                _buildCardDiferenca(
                  icon: Icons.straighten,
                  titulo: 'Peito',
                  valorAntes: (medidasAntes['peito'] as num).toDouble(),
                  valorDepois: (medidasDepois['peito'] as num).toDouble(),
                  unidade: 'cm',
                ),
              SizedBox(height: 12),
              if (medidasAntes['braco'] != null &&
                  medidasDepois['braco'] != null)
                _buildCardDiferenca(
                  icon: Icons.straighten,
                  titulo: 'Braço',
                  valorAntes: (medidasAntes['braco'] as num).toDouble(),
                  valorDepois: (medidasDepois['braco'] as num).toDouble(),
                  unidade: 'cm',
                ),
              SizedBox(height: 12),
              if (medidasAntes['cintura'] != null &&
                  medidasDepois['cintura'] != null)
                _buildCardDiferenca(
                  icon: Icons.straighten,
                  titulo: 'Cintura',
                  valorAntes: (medidasAntes['cintura'] as num).toDouble(),
                  valorDepois: (medidasDepois['cintura'] as num).toDouble(),
                  unidade: 'cm',
                ),
              SizedBox(height: 12),
              if (medidasAntes['perna'] != null &&
                  medidasDepois['perna'] != null)
                _buildCardDiferenca(
                  icon: Icons.straighten,
                  titulo: 'Perna',
                  valorAntes: (medidasAntes['perna'] as num).toDouble(),
                  valorDepois: (medidasDepois['perna'] as num).toDouble(),
                  unidade: 'cm',
                ),
            ],

            SizedBox(height: 24),

            // Mensagem Motivadora
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Continue Assim!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sua dedicação está trazendo resultados visíveis. Mantenha o foco!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFoto({
    required String urlFoto,
    required DateTime? data,
    required String label,
    required Color cor,
  }) {
    final dataFormatada =
        data != null ? DateFormat('dd/MM/yyyy').format(data) : 'N/A';

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            urlFoto,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 8),
        Text(
          dataFormatada,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildCardDiferenca({
    required IconData icon,
    required String titulo,
    required double valorAntes,
    required double valorDepois,
    required String unidade,
  }) {
    final diferenca = valorDepois - valorAntes;
    final percentual = ((diferenca / valorAntes) * 100).abs();

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
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${valorAntes.toStringAsFixed(1)} $unidade',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    Icon(Icons.arrow_forward,
                        size: 16, color: AppColors.textLight),
                    Text(
                      '${valorDepois.toStringAsFixed(1)} $unidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${diferenca >= 0 ? '+' : ''}${diferenca.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: diferenca < 0
                      ? AppColors.primaryGreen
                      : AppColors.accentOrange,
                ),
              ),
              Text(
                '${percentual.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

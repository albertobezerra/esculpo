// lib/screens/tela_medidas.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class TelaMedidas extends StatefulWidget {
  const TelaMedidas({super.key});

  @override
  State<TelaMedidas> createState() => _TelaMedidasState();
}

class _TelaMedidasState extends State<TelaMedidas> {
  final user = FirebaseAuth.instance.currentUser;

  // Controladores para o Modal de Adicionar
  final _pesoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _bicepsCtrl = TextEditingController();
  final _peitoCtrl = TextEditingController();

  // Abre o modal para registrar novas medidas
  void _abrirFormulario() {
    _pesoCtrl.clear();
    _cinturaCtrl.clear();
    _bicepsCtrl.clear();
    _peitoCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Nova Medição",
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildInput("Peso (kg)", _pesoCtrl,
                      icon: Icons.monitor_weight_outlined, isPrincipal: true),
                  const SizedBox(height: 16),
                  const Text("Circunferências (cm)",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 16),
                  _buildInput("Cintura", _cinturaCtrl),
                  const SizedBox(height: 12),
                  _buildInput("Peito", _peitoCtrl),
                  const SizedBox(height: 12),
                  _buildInput("Bíceps", _bicepsCtrl),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarMedidas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SALVAR REGISTRO",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom + 20), // Teclado
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {IconData? icon, bool isPrincipal = false}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
          fontSize: isPrincipal ? 24 : 16,
          fontWeight: isPrincipal ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: AppColors.primaryPurple) : null,
        suffixText: isPrincipal ? 'kg' : 'cm',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _salvarMedidas() async {
    if (user == null) return;

    // Converte inputs
    double? peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    if (peso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Informe pelo menos o peso!")));
      return;
    }

    final data = {
      'data': FieldValue.serverTimestamp(), // Data do servidor
      'dataRegistro':
          DateTime.now().toIso8601String(), // Data local para grafico
      'peso': peso,
      'cintura': double.tryParse(_cinturaCtrl.text.replaceAll(',', '.')),
      'peito': double.tryParse(_peitoCtrl.text.replaceAll(',', '.')),
      'biceps': double.tryParse(_bicepsCtrl.text.replaceAll(',', '.')),
    };

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('medidas')
        .add(data);

    if (mounted) Navigator.pop(context); // Fecha modal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Evolução Corporal",
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Registrar", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .collection('medidas')
            .orderBy('dataRegistro',
                descending: false) // Ordem crescente para o gráfico
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Nenhum registro ainda",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Prepara dados para o gráfico e lista (Lista invertida para mostrar mais recente primeiro)
          final listaInvertida = docs.reversed.toList();
          final spots = _gerarPontosDoGrafico(docs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // GRÁFICO DE PESO
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Peso (kg)",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text(
                            "${docs.last['peso']} kg", // Peso atual
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primaryPurple,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primaryPurple
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Histórico",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),

                // LISTA DE REGISTROS
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listaInvertida.length,
                  itemBuilder: (ctx, idx) {
                    final data =
                        listaInvertida[idx].data() as Map<String, dynamic>;
                    final date =
                        DateTime.tryParse(data['dataRegistro'] ?? '') ??
                            DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.calendar_today,
                              size: 18, color: AppColors.textDark),
                        ),
                        title: Text("${data['peso']} kg",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                            DateFormat('dd/MM/yyyy • HH:mm').format(date),
                            style: const TextStyle(fontSize: 12)),
                        trailing: data['cintura'] != null
                            ? Chip(
                                label: Text("Cintura: ${data['cintura']} cm",
                                    style: const TextStyle(fontSize: 10)))
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Espaço para FAB
              ],
            ),
          );
        },
      ),
    );
  }

  List<FlSpot> _gerarPontosDoGrafico(List<QueryDocumentSnapshot> docs) {
    List<FlSpot> spots = [];
    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      final peso = (data['peso'] as num?)?.toDouble() ?? 0.0;
      if (peso > 0) {
        spots.add(FlSpot(i.toDouble(), peso));
      }
    }
    return spots;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/subscription_service.dart'; // Ajustado

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final isPremium = ref.watch(subscriptionProvider).isPremium(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar perfil'));
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final completedSets = data?['completedSets'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Email: ${FirebaseAuth.instance.currentUser!.email}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                StreamBuilder<bool>(
                  stream: isPremium,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data == true ? 'Premium 🌟' : 'Gratuito',
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('IMC: ${data?['imc']?.toStringAsFixed(1) ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                if (completedSets >= 10)
                  Row(
                    children: [
                      const Text('🏆 10 Séries Concluídas!',
                          style: TextStyle(fontSize: 18, color: Colors.green)),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          Share.share(
                              'Conquistei 10 séries no Esculpo! 💪 #EsculpoApp');
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Sair'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

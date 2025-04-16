import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final subscriptionStatus =
        ref.watch(subscriptionProvider).isPremium(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura')),
      body: StreamBuilder<bool>(
        stream: subscriptionStatus,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final isPremium = snapshot.data ?? false;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isPremium ? 'Você é Premium!' : 'Escolha seu plano!',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                if (!isPremium) ...[
                  Card(
                    child: ListTile(
                      title: const Text('Sem Anúncios'),
                      subtitle: const Text('Treine sem interrupções'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(subscriptionProvider)
                                .buySubscription('no_ads_monthly', 'no_ads');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Assinar'),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Conteúdo Exclusivo'),
                      subtitle: const Text('Vídeos premium, relatórios e mais'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(subscriptionProvider)
                                .buySubscription(
                                    'exclusive_monthly', 'exclusive');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Assinar'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

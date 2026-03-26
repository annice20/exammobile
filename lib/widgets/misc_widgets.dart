import 'package:flutter/material.dart';

class NoElectionCard extends StatelessWidget {
  const NoElectionCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF162032),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: const Column(
      children: [
        Icon(Icons.how_to_vote_outlined, color: Colors.white24, size: 48),
        SizedBox(height: 12),
        Text(
          'Aucune élection active',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFFF7043),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les données',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3A6B),
              foregroundColor: const Color(0xFF4FC3F7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const ActionButtons({super.key, required this.onRetry, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Verifikasi Ulang'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home),
            label: const Text('Kembali ke Beranda'),
          ),
        ),
      ],
    );
  }
}

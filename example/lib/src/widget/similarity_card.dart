import 'package:flutter/material.dart';

class SimilarityCard extends StatelessWidget {
  final double similarity;
  final bool isSame;

  const SimilarityCard({
    super.key,
    required this.similarity,
    required this.isSame,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isSame ? Colors.blue[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSame ? Colors.blue[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Nilai Kemiripan',
            style: TextStyle(
              fontSize: 16,
              color: isSame ? Colors.blue[800] : Colors.red[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${similarity.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isSame ? Colors.blue[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

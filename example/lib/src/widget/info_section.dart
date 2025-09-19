import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  final bool isSame;
  final List<String> messages;

  const InfoSection({super.key, required this.isSame, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSame ? Colors.blue[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSame ? Colors.blue[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isSame ? Colors.blue[700] : Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi:',
                style: TextStyle(
                  color: isSame ? Colors.blue[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...messages.map(
            (msg) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                msg,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

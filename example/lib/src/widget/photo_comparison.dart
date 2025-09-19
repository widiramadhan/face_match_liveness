import 'dart:io';
import 'package:flutter/material.dart';
import 'package:example/src/main_page.dart';

class PhotoComparison extends StatelessWidget {
  final File image1;
  final File image2;
  final ComparisonMode mode;

  const PhotoComparison({
    super.key,
    required this.image1,
    required this.image2,
    required this.mode,
  });

  Widget _buildPhoto(File file, String label) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Perbandingan Foto:',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPhoto(image1, "Foto Pertama")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "VS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildPhoto(
                  image2,
                  mode == ComparisonMode.imageToLiveness
                      ? "Foto Liveness"
                      : "Foto Kedua",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

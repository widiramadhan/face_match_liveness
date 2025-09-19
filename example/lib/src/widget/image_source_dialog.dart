import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceDialog {
  static Future<File?> show(BuildContext context, {String? label}) async {
    return await showModalBottomSheet<File?>(
      context: context,
      builder: (context) => _DialogContent(label: label),
      isScrollControlled: true,
    );
  }
}

class _DialogContent extends StatelessWidget {
  final String? label;
  const _DialogContent({this.label});

  Future<File?> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 80,
    );
    return picked != null ? File(picked.path) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "Pilih Sumber Foto ${label ?? ""}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            Icons.camera_alt,
            "Kamera",
            "Ambil foto baru",
            () async {
              final file = await _pick(ImageSource.camera);
              Navigator.pop(context, file);
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            Icons.photo_library,
            "Galeri",
            "Pilih dari galeri",
            () async {
              final file = await _pick(ImageSource.gallery);
              Navigator.pop(context, file);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

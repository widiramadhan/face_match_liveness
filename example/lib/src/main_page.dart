import 'dart:io';
import 'package:example/src/service/face_service.dart';
import 'package:example/src/widget/action_card.dart';
import 'package:example/src/widget/image_source_dialog.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:face_match_liveness/face_match_liveness.dart';

import 'result_page.dart';

enum ComparisonMode { imageToImage, imageToLiveness }

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final faceService = FaceService();
  bool isLoading = false;

  Future<void> _handleCompare(
    File image1,
    File image2,
    ComparisonMode mode,
  ) async {
    setState(() => isLoading = true);
    try {
      final score = await faceService.compareFaces(image1, image2);
      setState(() => isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imageFile1: image1,
            imageFile2: image2,
            similarity: score,
            mode: mode,
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error compare: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Match & Liveness")),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ActionCard(
                icon: Icons.image,
                title: "Image vs Image",
                description: "Compare two photos from gallery or camera",
                onTap: () async {
                  final img1 = await ImageSourceDialog.show(
                    context,
                    label: "Pertama",
                  );
                  if (img1 == null) return;
                  final img2 = await ImageSourceDialog.show(
                    context,
                    label: "Kedua",
                  );
                  if (img2 == null) return;
                  _handleCompare(img1, img2, ComparisonMode.imageToImage);
                },
              ),
              const SizedBox(height: 20),
              ActionCard(
                icon: Icons.videocam,
                title: "Image vs Liveness",
                description: "Take a live photo and compare with an image",
                onTap: () async {
                  final img1 = await ImageSourceDialog.show(
                    context,
                    label: "Referensi",
                  );
                  if (img1 == null) return;

                  File? liveFile;
                  await FaceLiveness.show(
                    context,
                    onResult: (res) {
                      if (res.status == LivenessResultStatus.success) {
                        liveFile = res.capturedImage;
                      }
                    },
                  );
                  if (liveFile == null) return;
                  _handleCompare(
                    img1,
                    liveFile!,
                    ComparisonMode.imageToLiveness,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

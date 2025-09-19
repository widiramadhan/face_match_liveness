import 'dart:io';
import 'package:face_match_liveness/face_match_liveness.dart';

class FaceService {
  FaceCompare? _faceCompare;

  Future<void> init() async {
    _faceCompare ??= await FaceCompare.create();
  }

  Future<double> compareFaces(File image1, File image2) async {
    await init();
    return await _faceCompare!.compare(image1, image2);
  }
}

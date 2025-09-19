import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceCompare {
  Interpreter? _interpreter;
  late List<int> _outputShape;

  FaceCompare._();

  /// Factory method (async init)
  static Future<FaceCompare> create() async {
    final helper = FaceCompare._();
    helper._interpreter = await Interpreter.fromAsset(
      'packages/face_match_liveness/assets/models/mobilefacenet.tflite',
    );
    helper._outputShape = helper._interpreter!.getOutputTensor(0).shape;
    return helper;
  }

  /// Deteksi wajah dan crop (ambil wajah terbesar + alignment)
  Future<img.Image?> _detectAndCropFace(File imageFile) async {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    );
    final faceDetector = FaceDetector(options: options);

    final inputImage = InputImage.fromFile(imageFile);
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;

    // Ambil wajah terbesar
    faces.sort(
      (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
        a.boundingBox.width * a.boundingBox.height,
      ),
    );

    final face = faces.first;
    final boundingBox = face.boundingBox;

    final rawImage = img.decodeImage(imageFile.readAsBytesSync())!;
    var cropped = img.copyCrop(
      rawImage,
      x: boundingBox.left.toInt().clamp(0, rawImage.width - 1),
      y: boundingBox.top.toInt().clamp(0, rawImage.height - 1),
      width: boundingBox.width.toInt().clamp(1, rawImage.width),
      height: boundingBox.height.toInt().clamp(1, rawImage.height),
    );

    // Alignment berdasarkan mata (supaya wajah sejajar horizontal)
    if (face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]!;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]!;

      final dy = rightEye.position.y - leftEye.position.y;
      final dx = rightEye.position.x - leftEye.position.x;
      final angle = math.atan2(dy, dx);

      cropped = img.copyRotate(cropped, angle: angle * 180 / math.pi);
    }

    // (Opsional) simpan hasil crop buat debug
    await _saveDebugImage(
      cropped,
      "cropped_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    return cropped;
  }

  /// Simpan hasil crop untuk debug
  Future<void> _saveDebugImage(img.Image face, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name");
    await file.writeAsBytes(img.encodeJpg(face));
    print("✅ Cropped face saved at: ${file.path}");
  }

  /// Convert file ke embedding vector
  Future<List<double>> getEmbedding(File imageFile) async {
    if (_interpreter == null) {
      throw StateError(
        'FaceCompareHelper not initialized. Use FaceCompareHelper.create() instead.',
      );
    }

    final cropped = await _detectAndCropFace(imageFile);
    if (cropped == null) {
      print(
        "❌ No face detected in image: ${imageFile.path}. Pastikan wajah jelas, terang, dan menghadap kamera.",
      );
      throw Exception("Pastikan wajah jelas, terang, dan menghadap kamera.");
    }

    // Resize ke 112x112 (standard MobileFaceNet)
    final resized = img.copyResize(cropped, width: 112, height: 112);

    // Convert ke Float32 input [1,112,112,3]
    var input = List.generate(
      1,
      (_) => List.generate(
        112,
        (_) => List.generate(112, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);

        input[0][y][x][0] = (pixel.r - 127.5) / 128.0; // R
        input[0][y][x][1] = (pixel.g - 127.5) / 128.0; // G
        input[0][y][x][2] = (pixel.b - 127.5) / 128.0; // B
      }
    }

    // Output sesuai shape model (bisa [1,128], [1,192], [1,512])
    var output = List.generate(
      _outputShape[0],
      (_) => List.filled(_outputShape[1], 0.0),
    );

    _interpreter!.run(input, output);

    // Normalisasi (L2 norm) → biar lebih stabil
    return _normalize(List<double>.from(output[0]));
  }

  /// L2 normalization
  List<double> _normalize(List<double> vector) {
    final norm = math.sqrt(vector.fold(0.0, (sum, v) => sum + v * v));
    return vector.map((v) => v / norm).toList();
  }

  /// Cosine similarity (0–1)
  double cosineSimilarity(List<double> v1, List<double> v2) {
    double dot = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
    }
    return dot.clamp(-1.0, 1.0);
  }

  /// Compare dua wajah → hasil persen
  Future<double> compare(File img1, File img2) async {
    final emb1 = await getEmbedding(img1);
    final emb2 = await getEmbedding(img2);

    final similarity = cosineSimilarity(emb1, emb2);
    return similarity * 100; // convert ke persen
  }

  /// Helper untuk cek apakah wajah sama (default threshold 60%)
  Future<bool> isSamePerson(
    File img1,
    File img2, {
    double threshold = 50,
  }) async {
    final score = await compare(img1, img2);
    return score >= threshold;
  }

  void dispose() {
    _interpreter?.close();
  }
}

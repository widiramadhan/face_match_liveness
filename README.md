# face_match_liveness

Paket Flutter untuk verifikasi identitas berbasis wajah, termasuk face matching (perbandingan dua wajah) dan liveness detection (deteksi wajah hidup dengan gesture). Cocok untuk aplikasi KYC, login biometrik, dan verifikasi digital.

## Fitur

- **Face Matching**: Bandingkan dua foto wajah, dapatkan skor kemiripan (0-100%).
- **Liveness Detection**: Verifikasi wajah hidup dengan gesture (kedip, buka mulut, geleng kepala, dll).
- **Integrasi Kamera & Galeri**: Ambil foto langsung atau dari galeri.
- **UI Liveness Detection**: Widget siap pakai untuk proses liveness.

## Instalasi

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
	face_match_liveness: ^1.0.0
```

Jalankan:

```sh
flutter pub get
```

## Penggunaan

### Face Matching

```dart
import 'package:face_match_liveness/face_match_liveness.dart';
import 'dart:io';

// Inisialisasi helper
final faceCompare = await FaceCompare.create();

// Bandingkan dua foto
final score = await faceCompare.compare(File('img1.jpg'), File('img2.jpg'));
print('Similarity: $score%');

// Cek apakah sama orangnya (threshold default 50)
final isSame = await faceCompare.isSamePerson(File('img1.jpg'), File('img2.jpg'));
print(isSame ? 'Sama' : 'Berbeda');

faceCompare.dispose();
```

### Liveness Detection (Widget)

```dart
import 'package:face_match_liveness/face_match_liveness.dart';

await FaceLiveness.show(context, onResult: (res) {
    if (res.status == LivenessResultStatus.success) {
        print('Liveness OK, file: ${result.capturedImage?.path}');
    } else {
        print('Liveness Failed');
    }
});
```

### Contoh Integrasi

Lihat folder [`example/`](example/) untuk contoh aplikasi Flutter lengkap.

## FAQ

- **Model tidak terdeteksi?** Pastikan path asset sudah benar dan didaftarkan di pubspec.yaml.
- **Error kamera?** Pastikan permission kamera sudah diberikan di Android/iOS.
- **Gesture tidak terdeteksi?** Pastikan wajah jelas, terang, dan menghadap kamera.

## Kontribusi & Dukungan

Laporkan bug, request fitur, atau kontribusi via [GitHub Issues](https://github.com/widiramadhan/face_match_liveness/issues).

---
by [widiyantoramadhan](https://github.com/widiramadhan)

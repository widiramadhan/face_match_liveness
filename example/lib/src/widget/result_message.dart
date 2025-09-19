import 'package:example/src/main_page.dart';

class ResultMessage {
  static List<String> getMessages({
    required bool isSame,
    required ComparisonMode mode,
  }) {
    if (isSame) {
      if (mode == ComparisonMode.imageToLiveness) {
        return [
          '✓ Foto selfie cocok dengan foto liveness',
          '✓ Liveness detection mendeteksi wajah asli',
          '✓ Semua gerakan berhasil dideteksi',
        ];
      } else {
        return [
          '✓ Wajah pada kedua foto terdeteksi sama',
          '✓ Sistem berhasil melakukan verifikasi wajah',
          '✓ Foto sesuai dengan standar verifikasi',
        ];
      }
    } else {
      if (mode == ComparisonMode.imageToLiveness) {
        return [
          '• Pastikan pencahayaan cukup saat mengambil foto',
          '• Posisikan wajah dengan jelas di tengah frame',
          '• Lakukan semua gerakan dengan jelas',
          '• Coba ulangi proses verifikasi',
        ];
      } else {
        return [
          '• Kedua foto tidak cocok, pastikan menggunakan foto orang yang sama',
          '• Gunakan foto dengan pencahayaan yang baik dan jelas',
          '• Pastikan wajah tidak tertutup (kacamata gelap, masker, dsb)',
          '• Coba ulangi proses verifikasi dengan foto yang lebih jelas',
        ];
      }
    }
  }
}

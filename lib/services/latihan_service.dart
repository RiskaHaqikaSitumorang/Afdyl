import 'quran_stt_service.dart';
import 'dart:async';

/// DEPRECATED: Gunakan QuranSTTService untuk implementasi yang lebih baik
/// Service ini tetap ada untuk backward compatibility
class LatihanService {
  // Delegate ke QuranSTTService untuk implementasi yang lebih baik
  final QuranSTTService _quranSTT = QuranSTTService();

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  Future<void> initialize() async {
    print('[LatihanService] 🚀 Inisialisasi LatihanService...');
    await _quranSTT.initialize();
    print('[LatihanService] ✅ QuranSTTService berhasil diinisialisasi');

    // Forward stream dari QuranSTTService ke LatihanService
    _quranSTT.statusStream.listen((data) {
      print(
        '[LatihanService] 📨 Menerima status dari QuranSTT: ${data['status']}',
      );
      _statusController.add(data);
    });
    print('[LatihanService] 📡 Stream listener terpasang');
  }

  Future<void> startListening() async {
    print('[LatihanService] 🎙️  Mulai listening...');
    await _quranSTT.startListening();
    print('[LatihanService] ✅ Listening dimulai');
  }

  Future<void> stopListening() async {
    print('[LatihanService] 🛑 Stop listening...');
    await _quranSTT.stopListening();
    print('[LatihanService] ✅ Listening dihentikan');
  }

  void dispose() {
    print('[LatihanService] 🔚 Disposing LatihanService...');
    _quranSTT.dispose();
    _statusController.close();
    print('[LatihanService] ✅ LatihanService disposed');
  }
}

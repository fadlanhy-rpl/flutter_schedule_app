import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/secrets.dart';
import '../models/schedule_model.dart';
import 'package:intl/intl.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Secrets.geminiApiKey,
    );
  }

  Future<List<String>> generateActivities(String title) async {
    final prompt =
        '''
Anda adalah asisten produktivitas profesional.
Buatkan rincian kegiatan berdasarkan judul berikut:
$title

Aturan:
- Maksimal 8 poin
- Format bullet list dengan simbol -
- Tanpa penjelasan tambahan
- Langsung ke daftar kegiatan
- Bahasa Indonesia profesional
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) return [];

      // Parse the response into a list
      return text
          .split('\n')
          .where((line) => line.trim().startsWith('-'))
          .map((line) => line.trim().substring(1).trim())
          .toList();
    } catch (e) {
      print('Gemini Error: $e');
      throw Exception('Gagal menghasilkan aktivitas via AI');
    }
  }

  Future<String> generateWeeklyResume(List<Schedule> schedules) async {
    if (schedules.isEmpty) {
      return "Belum ada jadwal yang selesai minggu ini.";
    }

    final scheduleDetails = schedules
        .map((s) {
          return "- ${s.title} (${DateFormat('EEEE, d MMM').format(s.datetime)}): ${s.isCompleted ? 'SELESAI' : 'BELUM SELESAI'}\n  Aktivitas: ${s.activities.join(', ')}";
        })
        .join('\n');

    final prompt =
        '''
Buatkan ringkasan produktivitas mingguan, evaluasi, dan saran dari daftar kegiatan berikut:

$scheduleDetails

Instruksi:
1. Buat Ringkasan Profesional tentang apa yang telah dikerjakan.
2. Berikan Evaluasi Progres (apa yg bagus, apa yg kurang).
3. Berikan 3 Saran Peningkatan konkret.
4. Gunakan Bahasa Indonesia formal dan memotivasi.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Gagal membuat resume.";
    } catch (e) {
      throw Exception('Gagal membuat resume via AI: $e');
    }
  }
}

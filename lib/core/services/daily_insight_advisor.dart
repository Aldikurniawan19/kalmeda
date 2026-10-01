import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';

/// Structured clinical advice item based on recorded menstrual symptoms and lifestyle.
class DailyAdviceItem {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const DailyAdviceItem({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.primary,
  });
}

/// Clinical evaluation and health guidance advisor for daily menstrual records.
class DailyInsightAdvisor {
  static const _flowNames = [
    'Tidak Ada',
    'Flek / Bercak',
    'Darah Ringan',
    'Darah Sedang',
    'Darah Deras',
  ];

  static const _symptomNames = [
    'Kram Perut',
    'Kembung',
    'Kelelahan',
    'Sakit Kepala',
    'Sakit Pinggang',
    'Payudara Nyeri',
    'Jerawat',
    'Nafsu Makan Meningkat',
  ];

  /// Generates dynamic, clinical medical recommendations tailored to user's daily record.
  static List<DailyAdviceItem> generateAdvice({
    required int flowIndex,
    required int moodIndex,
    required Set<int> symptoms,
    required int waterCups,
    required int exerciseIndex,
  }) {
    final adviceList = <DailyAdviceItem>[];

    // 1. Flow Specific Medical Guidance
    if (flowIndex >= 4) {
      adviceList.add(const DailyAdviceItem(
        icon: Icons.water_drop_rounded,
        title: 'Manajemen Aliran Darah Deras',
        description:
            'Ganti pembalut tiap 3–4 jam untuk menjaga kebersihan panggul. Konsumsi makanan kaya zat besi (bayam, daging merah, telur) guna mencegah lemas dan anemia.',
        iconColor: AppColors.primary,
      ));
    } else if (flowIndex == 3) {
      adviceList.add(const DailyAdviceItem(
        icon: Icons.water_drop_outlined,
        title: 'Aliran Darah Sedang',
        description:
            'Pembersihan teratur dengan air bersih dan pakaian dalam berbahan katun longgar sangat disarankan untuk menjaga sirkulasi udara area intim.',
        iconColor: AppColors.primary,
      ));
    }

    // 2. Symptom Specific Medical Guidance (matching SymptomSelectorSection indices)
    if (symptoms.contains(0)) {
      // 0: Kram Perut (Dysmenorrhea)
      adviceList.add(const DailyAdviceItem(
        icon: Icons.healing_rounded,
        title: 'Meredakan Kram Perut (Dismenore)',
        description:
            'Gunakan kompres hangat di perut bawah selama 15–20 menit untuk merelaksasi otot rahim. Minum teh jahe atau chamomile hangat dapat membantu meredakan peradangan.',
        iconColor: Color(0xFFFF6F00),
      ));
    }

    if (symptoms.contains(1)) {
      // 1: Kembung (Bloating)
      adviceList.add(const DailyAdviceItem(
        icon: Icons.bubble_chart_outlined,
        title: 'Mengatasi Kembung & Begah',
        description:
            'Kurangi asupan garam berlebih dan minuman bersoda. Konsumsi makanan kaya kalium (pisang, pepaya, air kelapa) untuk membantu menyeimbangkan cairan tubuh.',
        iconColor: Color(0xFF00897B),
      ));
    }

    if (symptoms.contains(2)) {
      // 2: Kelelahan
      adviceList.add(const DailyAdviceItem(
        icon: Icons.bedtime_outlined,
        title: 'Pemulihan Energi & Kelelahan',
        description:
            'Kadar hormon yang rendah saat menstruasi menguras energi tubuh. Prioritaskan tidur malam 7–8 jam dan hindari aktivitas fisik berintensitas tinggi.',
        iconColor: Color(0xFF5C6BC0),
      ));
    }

    if (symptoms.contains(3)) {
      // 3: Sakit Kepala / Migrain Hormonal
      adviceList.add(const DailyAdviceItem(
        icon: Icons.psychology_outlined,
        title: 'Meredakan Sakit Kepala Hormonal',
        description:
            'Penurunan estrogen mendadak dapat memicu sakit kepala. Istirahat sejenak di ruangan sejuk dengan pencahayaan redup dan cukupi asupan cairan.',
        iconColor: Color(0xFF5E35B1),
      ));
    }

    if (symptoms.contains(4)) {
      // 4: Sakit Pinggang
      adviceList.add(const DailyAdviceItem(
        icon: Icons.accessibility_new_rounded,
        title: 'Relaksasi Otot Punggung & Pinggang',
        description:
            'Lakukan peregangan pose anak (child pose) atau peregangan kucing-sapi (cat-cow pose) selama 5–10 menit untuk melancarkan sirkulasi panggul.',
        iconColor: Color(0xFF43A047),
      ));
    }

    if (symptoms.contains(5)) {
      // 5: Payudara Nyeri (Mastalgia)
      adviceList.add(const DailyAdviceItem(
        icon: Icons.favorite_border_rounded,
        title: 'Mengurangi Nyeri Payudara',
        description:
            'Gunakan bra tanpa kawat (sport bra) yang nyaman dan kurangi konsumsi kafein berlebih untuk meredakan pembengkakan jaringan kelenjar.',
        iconColor: Color(0xFFD81B60),
      ));
    }

    if (symptoms.contains(6)) {
      // 6: Jerawat
      adviceList.add(const DailyAdviceItem(
        icon: Icons.face_rounded,
        title: 'Perawatan Kulit Hormonal',
        description:
            'Lonjakan androgen memicu produksi sebum. Bersihkan wajah dengan pembersih lembut bebas alkohol dan hindari memencet jerawat.',
        iconColor: Color(0xFFE91E63),
      ));
    }

    if (symptoms.contains(7)) {
      // 7: Nafsu Makan
      adviceList.add(const DailyAdviceItem(
        icon: Icons.restaurant_rounded,
        title: 'Pilihan Makanan & Camilan Sehat',
        description:
            'Pilih camilan kaya magnesium dan serat seperti kacang almond, pisang, atau cokelat hitam (dark chocolate) untuk menstabilkan gula darah.',
        iconColor: Color(0xFFFB8C00),
      ));
    }

    // 3. Hydration Guidance
    if (waterCups < 6) {
      adviceList.add(DailyAdviceItem(
        icon: Icons.local_drink_rounded,
        title: 'Asupan Cairan Perlu Ditingkatkan ($waterCups/8 Gelas)',
        description:
            'Konsumsi minimal 8 gelas air putih per hari untuk melancarkan sirkulasi darah, mencegah sakit kepala, dan meredakan retensi cairan pemicu begah.',
        iconColor: const Color(0xFF0288D1),
      ));
    } else {
      adviceList.add(DailyAdviceItem(
        icon: Icons.check_circle_outline_rounded,
        title: 'Hidrasi Sangat Baik ($waterCups Gelas)',
        description:
            'Pertahankan hidrasi optimal ini untuk menjaga stamina dan membantu metabolisme hormonal tubuh bekerja maksimal.',
        iconColor: const Color(0xFF43A047),
      ));
    }

    // 4. Mood Guidance
    if (moodIndex == 1 || moodIndex == 2) {
      adviceList.add(const DailyAdviceItem(
        icon: Icons.self_improvement_rounded,
        title: 'Keseimbangan Emosional & Relaksasi',
        description:
            'Fluktuasi hormonal wajar memicu sensitivitas emosional. Berikan diri waktu untuk istirahat tenang, latihan pernapasan dalam, atau mendengarkan musik santai.',
        iconColor: Color(0xFF8E24AA),
      ));
    }

    // Fallback general guidance
    if (adviceList.length < 2) {
      adviceList.add(const DailyAdviceItem(
        icon: Icons.favorite_rounded,
        title: 'Pola Hidup Sehat & Kebugaran',
        description:
            'Kombinasi nutrisi bergizi seimbang, tidur 7–8 jam di malam hari, dan jalan santai membantu menjaga ritme siklus tetap stabil dan teratur.',
        iconColor: AppColors.primary,
      ));
    }

    return adviceList;
  }

  /// Formats summary title based on flow and selected symptoms.
  static String formatConditionSummary({
    required int flowIndex,
    required Set<int> symptoms,
  }) {
    final flowText = _flowNames[flowIndex.clamp(0, _flowNames.length - 1)];
    if (symptoms.isEmpty) {
      return 'Aliran: $flowText • Kondisi tubuh stabil tanpa keluhan';
    }

    final symptomNames = symptoms
        .where((i) => i >= 0 && i < _symptomNames.length)
        .map((i) => _symptomNames[i])
        .take(3)
        .join(', ');

    return 'Aliran: $flowText • Gejala: $symptomNames';
  }
}

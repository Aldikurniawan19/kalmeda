import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';

/// Clinical phases of the menstrual cycle based on ACOG and WHO gynecological standards.
enum CyclePhase {
  menstrual, // Days 1 to periodDuration
  follicular, // Day periodDuration+1 to ovulationDay-6
  fertileWindow, // Days ovulationDay-5 to ovulationDay-1
  ovulation, // Exact ovulationDay (cycleLength - 14)
  luteal, // Days ovulationDay+1 to cycleLength-7
  pms, // Last 6 days of the cycle before next period
}

/// Probability level of conception for a given cycle day.
enum PregnancyProbability {
  low,
  medium,
  high,
  peak,
}

/// Detailed clinical data and personalized health recommendations for a specific day in the cycle.
class CycleDayInfo {
  final DateTime date;
  final int cycleDay;
  final int totalCycleLength;
  final CyclePhase phase;
  final String phaseName;
  final String phaseShortDescription;
  final String clinicalGuidance;
  final PregnancyProbability pregnancyProbability;
  final String pregnancyProbabilityText;
  final Color phaseColor;
  final bool isPeriodDay;
  final bool isPredictedPeriod;
  final bool isFertileDay;
  final bool isOvulationDay;
  final bool isPmsDay;
  final String nutritionTip;
  final String physicalTip;
  final String moodTip;

  const CycleDayInfo({
    required this.date,
    required this.cycleDay,
    required this.totalCycleLength,
    required this.phase,
    required this.phaseName,
    required this.phaseShortDescription,
    required this.clinicalGuidance,
    required this.pregnancyProbability,
    required this.pregnancyProbabilityText,
    required this.phaseColor,
    required this.isPeriodDay,
    required this.isPredictedPeriod,
    required this.isFertileDay,
    required this.isOvulationDay,
    required this.isPmsDay,
    required this.nutritionTip,
    required this.physicalTip,
    required this.moodTip,
  });
}

/// Overall overview state of the current menstrual cycle.
class CycleOverview {
  final int currentCycleDay;
  final int cycleLength;
  final int periodDuration;
  final int daysUntilNextPeriod;
  final DateTime nextPeriodDate;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final CyclePhase currentPhase;
  final CycleDayInfo currentDayInfo;
  final double progressFraction; // 0.0 to 1.0
  final String countdownTitle;
  final String countdownSubtitle;
  final String trackingGoal;
  final String regularity;

  // Real-time Confirmation and Clinical Health Warnings
  final bool isPeriodStartConfirmationDue; // Due for confirmation around predicted start date
  final bool isPeriodActive; // Currently in menstrual bleeding days
  final bool isPeriodProlonged; // Menstruation duration exceeds predicted duration or >= 8 days
  final int prolongedDays; // How many days it has exceeded
  final String prolongedClinicalAdvice;
  final List<String> prolongedRedFlags;

  const CycleOverview({
    required this.currentCycleDay,
    required this.cycleLength,
    required this.periodDuration,
    required this.daysUntilNextPeriod,
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.currentPhase,
    required this.currentDayInfo,
    required this.progressFraction,
    required this.countdownTitle,
    required this.countdownSubtitle,
    required this.trackingGoal,
    required this.regularity,
    this.isPeriodStartConfirmationDue = false,
    this.isPeriodActive = false,
    this.isPeriodProlonged = false,
    this.prolongedDays = 0,
    this.prolongedClinicalAdvice = '',
    this.prolongedRedFlags = const [],
  });
}

/// Clinical calculation engine for menstrual cycle analysis and projections.
class CycleEngineService {
  static final CycleEngineService _instance = CycleEngineService._internal();
  factory CycleEngineService() => _instance;
  CycleEngineService._internal();

  /// Calculates the complete cycle overview for today or a given reference date.
  CycleOverview calculateOverview({
    required CycleProfileModel profile,
    DateTime? referenceDate,
  }) {
    final today = DateFormatter.dateOnly(referenceDate ?? DateTime.now());
    final lmp = DateFormatter.dateOnly(profile.lastPeriodDate);
    final cycleLength = profile.cycleLength > 0 ? profile.cycleLength : 28;
    final periodDuration = profile.periodDuration > 0 ? profile.periodDuration : 5;

    // Calculate elapsed days since the recorded LMP
    final totalElapsedDays = today.difference(lmp).inDays;

    int currentCycleDay;
    DateTime currentCycleStartDate;

    if (totalElapsedDays >= 0) {
      final cycleCount = totalElapsedDays ~/ cycleLength;
      currentCycleDay = (totalElapsedDays % cycleLength) + 1;
      currentCycleStartDate = lmp.add(Duration(days: cycleCount * cycleLength));
    } else {
      // Reference date is prior to LMP
      final daysBefore = -totalElapsedDays;
      final cycleCount = ((daysBefore - 1) ~/ cycleLength) + 1;
      currentCycleStartDate = lmp.subtract(Duration(days: cycleCount * cycleLength));
      final diff = today.difference(currentCycleStartDate).inDays;
      currentCycleDay = (diff % cycleLength) + 1;
    }

    final nextPeriodDate = currentCycleStartDate.add(Duration(days: cycleLength));
    final daysUntilNextPeriod = nextPeriodDate.difference(today).inDays;

    // Standard medical ovulation occurs 14 days prior to next period
    final ovulationDayNumber = (cycleLength - 14).clamp(1, cycleLength - 1);
    final ovulationDate = currentCycleStartDate.add(Duration(days: ovulationDayNumber - 1));
    final fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDate;

    final currentDayInfo = calculateDayInfo(
      profile: profile,
      targetDate: today,
    );

    // Calculate progress percentage through the cycle
    final progress = (currentCycleDay / cycleLength).clamp(0.0, 1.0);

    String countdownTitle;
    String countdownSubtitle;

    final isPeriodEnded = profile.lastPeriodEndDate != null &&
        !profile.lastPeriodEndDate!.isBefore(lmp) &&
        !today.isBefore(DateFormatter.dateOnly(profile.lastPeriodEndDate!));

    final isPeriodActive = !isPeriodEnded &&
        currentCycleDay <= periodDuration &&
        totalElapsedDays < (cycleLength + 10);
    final isPeriodProlonged = !isPeriodEnded &&
        currentCycleDay > periodDuration &&
        currentCycleDay <= (periodDuration + 3).clamp(7, 9) &&
        totalElapsedDays < 10;
    final prolongedDays = isPeriodProlonged ? (currentCycleDay - periodDuration) : 0;

    // Period confirmation check: within 2 days of predicted date or overdue
    final isPeriodStartConfirmationDue = !isPeriodActive &&
        ((daysUntilNextPeriod <= 2 && daysUntilNextPeriod >= -4) || (totalElapsedDays >= cycleLength));

    if (isPeriodActive) {
      countdownTitle = 'Hari ke-$currentCycleDay';
      countdownSubtitle = 'Masa menstruasi berlangsung';
    } else if (isPeriodProlonged) {
      countdownTitle = 'Hari ke-$currentCycleDay';
      countdownSubtitle = 'Haid +$prolongedDays hari dari target';
    } else if (daysUntilNextPeriod == 1) {
      countdownTitle = '1 hari lagi';
      countdownSubtitle = 'Perkiraan menstruasi berikutnya';
    } else if (daysUntilNextPeriod <= 0) {
      countdownTitle = 'Hari ini';
      countdownSubtitle = 'Perkiraan menstruasi dimulai';
    } else {
      countdownTitle = '$daysUntilNextPeriod hari lagi';
      countdownSubtitle = 'Perkiraan menstruasi berikutnya';
    }

    const prolongedAdvice =
        'Durasi menstruasi normal menurut ACOG adalah 2–7 hari. Jika darah masih keluar melebihi perkiraan atau lebih dari 8 hari, ini dapat dipengaruhi oleh fluktuasi hormon estrogen-progesteron, kelelahan, stres, atau kondisi endometrium. Perbanyak asupan zat besi untuk mencegah anemia dan cukupi istirahat.';

    const redFlags = [
      'Pembalut penuh dalam 1–2 jam berturut-turut selama lebih dari 2 jam',
      'Keluar gumpalan darah berukuran besar (lebih dari koin 500 rupiah)',
      'Pusing hebat, lemas luar biasa, atau sesak napas saat beraktivitas',
      'Pendarahan terus berlanjut tanpa henti lebih dari 8–10 hari',
    ];

    return CycleOverview(
      currentCycleDay: currentCycleDay,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      daysUntilNextPeriod: daysUntilNextPeriod,
      nextPeriodDate: nextPeriodDate,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      currentPhase: currentDayInfo.phase,
      currentDayInfo: currentDayInfo,
      progressFraction: progress,
      countdownTitle: countdownTitle,
      countdownSubtitle: countdownSubtitle,
      trackingGoal: profile.trackingGoal,
      regularity: profile.regularity,
      isPeriodStartConfirmationDue: isPeriodStartConfirmationDue,
      isPeriodActive: isPeriodActive,
      isPeriodProlonged: isPeriodProlonged,
      prolongedDays: prolongedDays,
      prolongedClinicalAdvice: prolongedAdvice,
      prolongedRedFlags: redFlags,
    );
  }

  /// Calculates clinical phase and recommendations for any specific target calendar date.
  CycleDayInfo calculateDayInfo({
    required CycleProfileModel profile,
    required DateTime targetDate,
  }) {
    final target = DateFormatter.dateOnly(targetDate);
    final lmp = DateFormatter.dateOnly(profile.lastPeriodDate);
    final cycleLength = profile.cycleLength > 0 ? profile.cycleLength : 28;
    final periodDuration = profile.periodDuration > 0 ? profile.periodDuration : 5;

    final totalElapsedDays = target.difference(lmp).inDays;

    int cycleDay;
    if (totalElapsedDays >= 0) {
      cycleDay = (totalElapsedDays % cycleLength) + 1;
    } else {
      final daysBefore = -totalElapsedDays;
      final cycleCount = ((daysBefore - 1) ~/ cycleLength) + 1;
      final cycleStart = lmp.subtract(Duration(days: cycleCount * cycleLength));
      cycleDay = (target.difference(cycleStart).inDays % cycleLength) + 1;
    }

    final ovulationDay = (cycleLength - 14).clamp(1, cycleLength - 1);
    final fertileStartDay = (ovulationDay - 5).clamp(1, ovulationDay);
    final pmsStartDay = (cycleLength - 6).clamp(ovulationDay + 1, cycleLength);

    CyclePhase phase;
    String phaseName;
    String phaseShortDescription;
    String clinicalGuidance;
    PregnancyProbability pregnancyProb;
    String pregnancyProbText;
    Color phaseColor;
    bool isPeriod = false;
    bool isFertile = false;
    bool isOvulation = false;
    bool isPms = false;

    String nutritionTip;
    String physicalTip;
    String moodTip;

    final isPeriodEnded = profile.lastPeriodEndDate != null &&
        !profile.lastPeriodEndDate!.isBefore(lmp) &&
        !target.isBefore(DateFormatter.dateOnly(profile.lastPeriodEndDate!));

    if (cycleDay <= periodDuration && !isPeriodEnded) {
      phase = CyclePhase.menstrual;
      phaseName = 'Fase Menstruasi';
      phaseShortDescription = 'Pelepasan dinding rahim dan penurunan hormon estrogen.';
      clinicalGuidance =
          'Kadar hormon berada pada titik terendah. Rahim sedang meluruhkan lapisan endometrium. Jaga kebersihan area intim dan hindari aktivitas berlebih.';
      pregnancyProb = PregnancyProbability.low;
      pregnancyProbText = 'Peluang Kehamilan Sangat Rendah';
      phaseColor = AppColors.periodSolid;
      isPeriod = true;
      nutritionTip = 'Konsumsi makanan kaya zat besi (bayam, daging merah, hati) dan minuman hangat untuk mencegah lemas.';
      physicalTip = 'Peregangan ringan, jalan santai, atau yoga restoratif. Hindari olahraga dengan intensitas berlebih.';
      moodTip = 'Berikan ruang untuk istirahat. Sensitivitas atau rasa lelah adalah respon alami penurunan hormon.';
    } else if (cycleDay < fertileStartDay || (cycleDay <= periodDuration && isPeriodEnded)) {
      phase = CyclePhase.follicular;
      phaseName = 'Fase Folikuler';
      phaseShortDescription = 'Peningkatan hormon estrogen dan pematangan folikel telur.';
      clinicalGuidance =
          'Folikel ovarium sedang berkembang. Hormon estrogen mulai meningkat secara bertahap, meningkatkan energi fisik, fokus, dan mood positif.';
      pregnancyProb = PregnancyProbability.low;
      pregnancyProbText = 'Peluang Kehamilan Rendah';
      phaseColor = const Color(0xFFFFB8CC);
      nutritionTip = 'Penuhi asupan protein berkualitas, sayuran hijau segar, dan makanan fermentasi untuk mendukung metabolisme estrogen.';
      physicalTip = 'Waktu terbaik untuk meningkatkan intensitas olahraga (kardio, latihan beban) karena stamina sedang meningkat.';
      moodTip = 'Energi dan rasa percaya diri cenderung berada di puncak. Bagus untuk menyelesaikan tugas yang membutuhkan konsentrasi tinggi.';
    } else if (cycleDay < ovulationDay) {
      phase = CyclePhase.fertileWindow;
      phaseName = 'Masa Subur';
      phaseShortDescription = 'Jendela kesuburan tinggi menjelang pelepasan sel telur.';
      clinicalGuidance =
          'Kadar estrogen mencapai puncak, memicu lonjakan LH (Luteinizing Hormone). Lendir serviks menjadi lebih jernih, elastis, dan licin.';
      pregnancyProb = PregnancyProbability.high;
      pregnancyProbText = 'Peluang Kehamilan Tinggi';
      phaseColor = AppColors.fertileWindow;
      isFertile = true;
      nutritionTip = 'Konsumsi antioksidan tinggi (buah beri, kacang-kacangan, alpukat) dan hidrasi yang cukup untuk mendukung kualitas lendir serviks.';
      physicalTip = 'Stamina sangat optimal. Latihan kardio, HIIT, atau aktivitas luar ruangan sangat cocok dilakukan.';
      moodTip = 'Daya tarik, energi sosial, dan motivasi diri berada pada fase optimal.';
    } else if (cycleDay == ovulationDay) {
      phase = CyclePhase.ovulation;
      phaseName = 'Hari Ovulasi';
      phaseShortDescription = 'Pelepasan sel telur matang dari ovarium (puncak fertilitas).';
      clinicalGuidance =
          'Sel telur dilepaskan ke tuba fallopi dan bertahan 12–24 jam. Ini adalah hari dengan tingkat fertilitas tertinggi dalam satu siklus.';
      pregnancyProb = PregnancyProbability.peak;
      pregnancyProbText = 'Puncak Masa Subur (Fertilitas Maksimal)';
      phaseColor = AppColors.ovulationSolid;
      isFertile = true;
      isOvulation = true;
      nutritionTip = 'Makanan anti-inflamasi seperti kunyit, salmon, dan sayuran berserat tinggi untuk mendukung ovulasi sehat.';
      physicalTip = 'Pertahankan aktivitas fisik teratur. Beberapa wanita merasakan sedikit sensasi kram ovulasi (mittelschmerz).';
      moodTip = 'Perasaan positif dan energi mencapai puncak siklus.';
    } else if (cycleDay < pmsStartDay) {
      phase = CyclePhase.luteal;
      phaseName = 'Fase Luteal';
      phaseShortDescription = 'Korpus luteum memproduksi hormon progesteron.';
      clinicalGuidance =
          'Progesteron mendominasi untuk mempersiapkan dinding rahim. Suhu basal tubuh sedikit naik dan metabolisme tubuh bekerja lebih cepat.';
      pregnancyProb = PregnancyProbability.low;
      pregnancyProbText = 'Peluang Kehamilan Rendah';
      phaseColor = const Color(0xFFFFD6E3);
      nutritionTip = 'Fokus pada makanan kaya vitamin B6 dan magnesium (pisang, oat, biji labu) untuk menstabilkan kadar gula darah.';
      physicalTip = 'Lakukan olahraga sedang seperti berenang, pilates, atau senam peregangan tubuh.';
      moodTip = 'Mulai terasa perubahan mood santai. Luangkan waktu untuk relaksasi dan kurangi beban stres harian.';
    } else {
      phase = CyclePhase.pms;
      phaseName = 'Fase Pramenstruasi (PMS)';
      phaseShortDescription = 'Penurunan hormon estrogen & progesteron menjelang menstruasi.';
      clinicalGuidance =
          'Lapisan rahim bersiap meluruh jika tidak terjadi pembuahan. Penurunan tajam hormon dapat memicu sedikit kembung, sensitivitas payudara, atau perubahan mood.';
      pregnancyProb = PregnancyProbability.low;
      pregnancyProbText = 'Peluang Kehamilan Sangat Rendah';
      phaseColor = const Color(0xFFFF8FA3);
      isPms = true;
      nutritionTip = 'Kurangi konsumsi garam, kafein berlebih, dan gula rafinasi untuk mencegah kembung dan nyeri payudara.';
      physicalTip = 'Latihan pernapasan dalam, jalan santai, atau peregangan panggul untuk meredakan ketegangan otot tubuh.';
      moodTip = 'Pahami bahwa perubahan suasana hati adalah respon fisiologis hormonal tubuh. Prioritaskan tidur cukup dan istirahat.';
    }

    return CycleDayInfo(
      date: target,
      cycleDay: cycleDay,
      totalCycleLength: cycleLength,
      phase: phase,
      phaseName: phaseName,
      phaseShortDescription: phaseShortDescription,
      clinicalGuidance: clinicalGuidance,
      pregnancyProbability: pregnancyProb,
      pregnancyProbabilityText: pregnancyProbText,
      phaseColor: phaseColor,
      isPeriodDay: isPeriod,
      isPredictedPeriod: isPeriod,
      isFertileDay: isFertile,
      isOvulationDay: isOvulation,
      isPmsDay: isPms,
      nutritionTip: nutritionTip,
      physicalTip: physicalTip,
      moodTip: moodTip,
    );
  }

  /// Returns a set of DateTime objects representing period days in a given month.
  Set<DateTime> getPeriodDatesForMonth({
    required CycleProfileModel profile,
    required int year,
    required int month,
  }) {
    final result = <DateTime>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayInfo = calculateDayInfo(profile: profile, targetDate: date);
      if (dayInfo.isPeriodDay) {
        result.add(DateFormatter.dateOnly(date));
      }
    }
    return result;
  }

  /// Returns a set of DateTime objects representing fertile window days in a given month.
  Set<DateTime> getFertileDatesForMonth({
    required CycleProfileModel profile,
    required int year,
    required int month,
  }) {
    final result = <DateTime>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayInfo = calculateDayInfo(profile: profile, targetDate: date);
      if (dayInfo.isFertileDay) {
        result.add(DateFormatter.dateOnly(date));
      }
    }
    return result;
  }

  /// Returns a set of DateTime objects representing exact ovulation days in a given month.
  Set<DateTime> getOvulationDatesForMonth({
    required CycleProfileModel profile,
    required int year,
    required int month,
  }) {
    final result = <DateTime>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayInfo = calculateDayInfo(profile: profile, targetDate: date);
      if (dayInfo.isOvulationDay) {
        result.add(DateFormatter.dateOnly(date));
      }
    }
    return result;
  }
}

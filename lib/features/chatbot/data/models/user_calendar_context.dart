import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';

/// Real-time clinical calendar and cycle context for the authenticated user,
/// used by Gemini AI and in-app expert synthesizer to provide hyper-personalized responses.
class UserCalendarContext {
  final DateTime lastPeriodDate;
  final int cycleLength;
  final int periodDuration;
  final String regularity;
  final int currentCycleDay;
  final DateTime nextPeriodDate;
  final int daysUntilNextPeriod;
  final bool isLate;
  final int daysLate;
  final CyclePhase currentPhase;
  final String phaseName;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final bool isPeriodActive;
  final HealthProfileModel? healthProfile;
  final int? userAge;
  final String? userName;

  const UserCalendarContext({
    required this.lastPeriodDate,
    required this.cycleLength,
    required this.periodDuration,
    required this.regularity,
    required this.currentCycleDay,
    required this.nextPeriodDate,
    required this.daysUntilNextPeriod,
    required this.isLate,
    required this.daysLate,
    required this.currentPhase,
    required this.phaseName,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.isPeriodActive,
    this.healthProfile,
    this.userAge,
    this.userName,
  });

  /// Derives complete calendar and cycle state from [CycleProfileModel] and optional parameters.
  factory UserCalendarContext.fromCycleProfile({
    required CycleProfileModel cycleProfile,
    HealthProfileModel? healthProfile,
    DateTime? birthDate,
    String? userName,
    DateTime? referenceDate,
  }) {
    final today = DateFormatter.dateOnly(referenceDate ?? DateTime.now());
    final lmp = DateFormatter.dateOnly(cycleProfile.lastPeriodDate);
    final cycleLength = cycleProfile.cycleLength > 0
        ? cycleProfile.cycleLength
        : 28;
    final periodDuration = cycleProfile.periodDuration > 0
        ? cycleProfile.periodDuration
        : 5;

    final totalElapsedDays = today.difference(lmp).inDays;

    // Check if the current cycle has exceeded predicted cycleLength
    final bool isLate = totalElapsedDays >= cycleLength;
    final int daysLate = isLate ? (totalElapsedDays - cycleLength) : 0;

    // Current cycle day position
    final int currentCycleDay = totalElapsedDays >= 0
        ? (totalElapsedDays + 1)
        : 1;

    // Next period prediction
    final DateTime nextPeriodDate = lmp.add(Duration(days: cycleLength));
    final int daysUntilNextPeriod = nextPeriodDate.difference(today).inDays;

    // Ovulation & fertile window calculation (14 days before next period)
    final ovulationDayNumber = (cycleLength - 14).clamp(1, cycleLength - 1);
    final DateTime ovulationDate = lmp.add(
      Duration(days: ovulationDayNumber - 1),
    );
    final DateTime fertileWindowStart = ovulationDate.subtract(
      const Duration(days: 5),
    );
    final DateTime fertileWindowEnd = ovulationDate;

    // Determine current phase from CycleEngineService
    final dayInfo = CycleEngineService().calculateDayInfo(
      profile: cycleProfile,
      targetDate: today,
    );

    final isPeriodActive =
        totalElapsedDays >= 0 &&
        totalElapsedDays < periodDuration &&
        (cycleProfile.lastPeriodEndDate == null ||
            !today.isAfter(cycleProfile.lastPeriodEndDate!));

    final int? userAge = birthDate != null && today.year > birthDate.year
        ? (today.year - birthDate.year)
        : null;

    final cleanName = userName != null && userName.trim().isNotEmpty
        ? userName.trim().split(' ').first
        : null;

    return UserCalendarContext(
      lastPeriodDate: lmp,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      regularity: cycleProfile.regularity,
      currentCycleDay: currentCycleDay,
      nextPeriodDate: nextPeriodDate,
      daysUntilNextPeriod: daysUntilNextPeriod,
      isLate: isLate,
      daysLate: daysLate,
      currentPhase: dayInfo.phase,
      phaseName: dayInfo.phaseName,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      isPeriodActive: isPeriodActive,
      healthProfile: healthProfile,
      userAge: userAge,
      userName: cleanName,
    );
  }

  /// Derives complete calendar and cycle state from [UserProfileData].
  factory UserCalendarContext.fromUserProfile({
    required UserProfileData userProfile,
    DateTime? referenceDate,
  }) {
    return UserCalendarContext.fromCycleProfile(
      cycleProfile: userProfile.cycleProfile,
      healthProfile: userProfile.healthProfile,
      birthDate: userProfile.birthDate,
      userName: userProfile.name,
      referenceDate: referenceDate,
    );
  }

  /// Readable regularity label in Indonesian.
  String get regularityLabel {
    switch (regularity) {
      case 'regular':
        return 'Sangat Teratur';
      case 'sometimes_variable':
        return 'Kadang Bergeser';
      case 'irregular':
        return 'Tidak Teratur';
      default:
        return 'Teratur';
    }
  }

  /// Formats this calendar context into a structured prompt section for AI and engines.
  String toPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('DATA KALENDER & STATUS SIKLUS PENGGUNA TERKINI:');
    if (userName != null) buffer.writeln('- Nama Pengguna: $userName');
    if (userAge != null) buffer.writeln('- Usia: $userAge tahun');
    buffer.writeln(
      '- Tanggal Hari Pertama Haid Terakhir (LMP): ${DateFormatter.format(lastPeriodDate)}',
    );
    buffer.writeln(
      '- Panjang Siklus Rata-rata: $cycleLength hari (Keteraturan: $regularityLabel)',
    );
    buffer.writeln('- Durasi Haid Rata-rata: $periodDuration hari');
    buffer.writeln(
      '- Posisi Siklus Hari Ini: Hari ke-$currentCycleDay ($phaseName)',
    );
    buffer.writeln(
      '- Tanggal Perkiraan Haid Berikutnya: ${DateFormatter.format(nextPeriodDate)}',
    );

    if (isLate) {
      if (daysLate == 0) {
        buffer.writeln(
          '- Status Keterlambatan: HARI INI adalah jadwal prediksi menstruasi dimulai.',
        );
      } else {
        buffer.writeln(
          '- Status Keterlambatan: SUDAH TERLAMBAT $daysLate HARI dari jadwal prediksi (${DateFormatter.format(nextPeriodDate)}).',
        );
      }
    } else {
      buffer.writeln(
        '- Status Keterlambatan: Belum terlambat (masih $daysUntilNextPeriod hari lagi menuju perkiraan haid).',
      );
    }

    buffer.writeln(
      '- Perkiraan Puncak Ovulasi: ${DateFormatter.format(ovulationDate)}',
    );
    buffer.writeln(
      '- Jendela Masa Subur: ${DateFormatter.format(fertileWindowStart)} s/d ${DateFormatter.format(fertileWindowEnd)}',
    );

    if (healthProfile != null) {
      buffer.writeln(
        '- Status Reproduksi: ${healthProfile!.reproductiveStatusLabel}',
      );
      buffer.writeln(
        '- Metode Kontrasepsi: ${healthProfile!.contraceptionLabel}',
      );
      final conditions = healthProfile!.gynecologicalConditions
          .where((c) => c != 'none' && c != 'prefer_not_to_say')
          .map(HealthProfileModel.conditionToLabel)
          .toList();
      if (conditions.isNotEmpty) {
        buffer.writeln('- Riwayat Medis Ginekologis: ${conditions.join(", ")}');
      }
      final family = healthProfile!.familyMedicalHistory
          .where((f) => f != 'none' && f != 'prefer_not_to_say')
          .map(HealthProfileModel.familyConditionToLabel)
          .toList();
      if (family.isNotEmpty) {
        buffer.writeln('- Riwayat Kesehatan Keluarga: ${family.join(", ")}');
      }
    }

    return buffer.toString();
  }
}

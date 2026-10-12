import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/data/services/confirmed_period_storage.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Clinical model representing a discrete menstrual bleeding period episode
/// extracted from direct user confirmations, system cycle predictions, and daily logs.
class PeriodHistoryEpisode {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int? cycleLength; // Cycle length in days compared to the older adjacent period
  final int maxFlowIndex; // 0: None, 1: Spotting, 2: Light, 3: Medium, 4: Heavy
  final int dominantMoodIndex;
  final List<int> symptoms;
  final double averageWaterCups;
  final List<String> notes;
  final List<CycleRecordModel> dailyRecords;
  final bool isOngoing;
  final bool isFromProfileOnly;

  const PeriodHistoryEpisode({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.cycleLength,
    required this.maxFlowIndex,
    required this.dominantMoodIndex,
    required this.symptoms,
    required this.averageWaterCups,
    required this.notes,
    required this.dailyRecords,
    this.isOngoing = false,
    this.isFromProfileOnly = false,
  });

  PeriodHistoryEpisode copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    int? cycleLength,
    int? maxFlowIndex,
    int? dominantMoodIndex,
    List<int>? symptoms,
    double? averageWaterCups,
    List<String>? notes,
    List<CycleRecordModel>? dailyRecords,
    bool? isOngoing,
    bool? isFromProfileOnly,
  }) {
    return PeriodHistoryEpisode(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      cycleLength: cycleLength ?? this.cycleLength,
      maxFlowIndex: maxFlowIndex ?? this.maxFlowIndex,
      dominantMoodIndex: dominantMoodIndex ?? this.dominantMoodIndex,
      symptoms: symptoms ?? this.symptoms,
      averageWaterCups: averageWaterCups ?? this.averageWaterCups,
      notes: notes ?? this.notes,
      dailyRecords: dailyRecords ?? this.dailyRecords,
      isOngoing: isOngoing ?? this.isOngoing,
      isFromProfileOnly: isFromProfileOnly ?? this.isFromProfileOnly,
    );
  }

  /// Extracts chronological period episodes strictly within the last 6 months.
  /// Menstrual timing is determined when the user has already started period
  /// (following direct user confirmation on H-2/H+ prompts, or system prediction).
  /// Daily check-in notes enrich the episode, but are not mandatory for a period to be counted.
  static List<PeriodHistoryEpisode> extractEpisodes({
    required List<CycleRecordModel> records,
    CycleProfileModel? profile,
    List<ConfirmedPeriodEntry>? confirmedPeriods,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateFormatter.dateOnly(now);
    // Strict 6 calendar months cutoff (from 1st of month 5 months ago up to today)
    final cutoffDate = DateTime(now.year, now.month - 5, 1);

    // 1. Gather all period time windows that have started (startDate <= today)
    final List<_PeriodWindow> windows = [];

    // A. Confirmed periods from user confirmations (H-2 / H+ start prompt, H-2 end prompt)
    if (confirmedPeriods != null) {
      for (final cp in confirmedPeriods) {
        final start = DateFormatter.dateOnly(cp.startDate);
        // Only periods that have already started and within the 6-month boundary
        if (!start.isAfter(today) && !start.isBefore(cutoffDate)) {
          final end = DateFormatter.dateOnly(cp.endDate);
          windows.add(_PeriodWindow(
            startDate: start,
            endDate: end,
            durationDays: cp.durationDays,
            isOngoing: cp.isOngoing && !start.isAfter(today),
            isConfirmedStart: cp.isConfirmedStart,
            isConfirmedEnd: cp.isConfirmedEnd,
          ));
        }
      }
    }

    // B. From profile.lastPeriodDate (active / confirmed cycle from profile)
    if (profile != null) {
      final lmp = DateFormatter.dateOnly(profile.lastPeriodDate);
      final cycleLength = profile.cycleLength > 0 ? profile.cycleLength : 28;
      final periodDuration =
          profile.periodDuration > 0 ? profile.periodDuration : 5;

      // Only if period has already started
      if (!lmp.isAfter(today) && !lmp.isBefore(cutoffDate)) {
        final alreadyCovered = windows.any(
          (w) => w.startDate.difference(lmp).inDays.abs() <= 3,
        );
        if (!alreadyCovered) {
          final isEnded = profile.lastPeriodEndDate != null &&
              !profile.lastPeriodEndDate!.isBefore(lmp);
          final lmpEnd = isEnded
              ? DateFormatter.dateOnly(profile.lastPeriodEndDate!)
              : lmp.add(Duration(days: periodDuration - 1));
          final duration = isEnded
              ? (lmpEnd.difference(lmp).inDays + 1)
              : periodDuration;
          final isOngoing = !isEnded &&
              (today.difference(lmp).inDays < duration ||
                  today.difference(lmpEnd).inDays <= 1);

          windows.add(_PeriodWindow(
            startDate: lmp,
            endDate: lmpEnd,
            durationDays: duration,
            isOngoing: isOngoing,
            isConfirmedStart: true,
            isConfirmedEnd: isEnded,
          ));
        }
      }

      // C. Subsequent cycles following system predictions that have already started (startDate <= today)
      var nextStart = lmp.add(Duration(days: cycleLength));
      while (!nextStart.isAfter(today)) {
        if (!nextStart.isBefore(cutoffDate)) {
          final alreadyCovered = windows.any(
            (w) => w.startDate.difference(nextStart).inDays.abs() <= 3,
          );
          if (!alreadyCovered) {
            final nextEnd = nextStart.add(Duration(days: periodDuration - 1));
            final isOngoing =
                today.difference(nextStart).inDays < periodDuration ||
                    today.difference(nextEnd).inDays <= 1;

            windows.add(_PeriodWindow(
              startDate: nextStart,
              endDate: nextEnd,
              durationDays: periodDuration,
              isOngoing: isOngoing,
              isConfirmedStart: false,
              isConfirmedEnd: false,
            ));
          }
        }
        nextStart = nextStart.add(Duration(days: cycleLength));
      }
    }

    // D. Also include any distinct bleeding records in `records` (flowIndex > 0)
    // not falling inside existing period windows
    final bleedingRecords = records.where((r) {
      final date = DateFormatter.dateOnly(r.date);
      return r.flowIndex > 0 &&
          !date.isBefore(cutoffDate) &&
          !date.isAfter(today);
    }).toList();
    bleedingRecords.sort((a, b) => a.date.compareTo(b.date));

    final List<List<CycleRecordModel>> manualGroups = [];
    for (final rec in bleedingRecords) {
      final recDate = DateFormatter.dateOnly(rec.date);
      final coveredByWindow = windows.any(
        (w) => !recDate.isBefore(w.startDate) && !recDate.isAfter(w.endDate),
      );
      if (!coveredByWindow) {
        if (manualGroups.isEmpty) {
          manualGroups.add([rec]);
        } else {
          final lastGroup = manualGroups.last;
          final lastRec = lastGroup.last;
          final dayDiff =
              recDate.difference(DateFormatter.dateOnly(lastRec.date)).inDays;
          if (dayDiff <= 2) {
            lastGroup.add(rec);
          } else {
            manualGroups.add([rec]);
          }
        }
      }
    }

    for (final group in manualGroups) {
      final start = DateFormatter.dateOnly(group.first.date);
      final end = DateFormatter.dateOnly(group.last.date);
      final duration = end.difference(start).inDays + 1;
      windows.add(_PeriodWindow(
        startDate: start,
        endDate: end,
        durationDays: duration,
        isOngoing: today.difference(end).inDays <= 2 && duration < 10,
        isConfirmedStart: true,
        isConfirmedEnd: true,
      ));
    }

    // 2. Build episodes by merging with user daily records (if any)
    final List<PeriodHistoryEpisode> episodes = [];
    for (final window in windows) {
      final start = window.startDate;
      final end = window.endDate;

      // Find daily check-in logs that fall on this period window
      final matchingDaily = records.where((r) {
        final rDate = DateFormatter.dateOnly(r.date);
        return !rDate.isBefore(start) && !rDate.isAfter(end);
      }).toList();
      matchingDaily.sort((a, b) => a.date.compareTo(b.date));

      int maxFlow = 3; // Baseline medium period flow
      final Map<int, int> moodCounts = {};
      final Set<int> symptomsSet = {};
      final List<String> notesList = [];
      int totalWater = 0;

      if (matchingDaily.isNotEmpty) {
        maxFlow = 0;
        for (final r in matchingDaily) {
          if (r.flowIndex > maxFlow) maxFlow = r.flowIndex;
          moodCounts[r.moodIndex] = (moodCounts[r.moodIndex] ?? 0) + 1;
          symptomsSet.addAll(r.symptoms);
          if (r.notes.trim().isNotEmpty) {
            notesList.add(r.notes.trim());
          }
          totalWater += r.waterCups;
        }
        if (maxFlow == 0) maxFlow = 3;
      } else {
        notesList.add(window.isConfirmedStart
            ? 'Periode menstruasi tercatat dari konfirmasi langsung pengguna'
            : 'Periode menstruasi tercatat sesuai perkiraan siklus sistem');
      }

      int dominantMood = 0;
      int maxMoodCount = -1;
      moodCounts.forEach((mood, count) {
        if (count > maxMoodCount) {
          maxMoodCount = count;
          dominantMood = mood;
        }
      });

      episodes.add(PeriodHistoryEpisode(
        id: 'ep_${start.millisecondsSinceEpoch}',
        startDate: start,
        endDate: end,
        durationDays: window.durationDays,
        maxFlowIndex: maxFlow,
        dominantMoodIndex: dominantMood,
        symptoms: symptomsSet.toList()..sort(),
        averageWaterCups: matchingDaily.isNotEmpty
            ? totalWater / matchingDaily.length
            : 8.0,
        notes: notesList,
        dailyRecords: matchingDaily,
        isOngoing: window.isOngoing,
        isFromProfileOnly: matchingDaily.isEmpty,
      ));
    }

    // 3. Sort episodes descending (most recent period first)
    episodes.sort((a, b) => b.startDate.compareTo(a.startDate));

    // 4. Calculate actual cycle length between consecutive recorded periods
    final List<PeriodHistoryEpisode> episodesWithCycle = [];
    for (int i = 0; i < episodes.length; i++) {
      int? cycleLen;
      if (i + 1 < episodes.length) {
        cycleLen = episodes[i]
            .startDate
            .difference(episodes[i + 1].startDate)
            .inDays;
      }
      episodesWithCycle.add(episodes[i].copyWith(cycleLength: cycleLen));
    }

    return episodesWithCycle;
  }
}

class _PeriodWindow {
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final bool isOngoing;
  final bool isConfirmedStart;
  final bool isConfirmedEnd;

  const _PeriodWindow({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.isOngoing,
    required this.isConfirmedStart,
    required this.isConfirmedEnd,
  });
}

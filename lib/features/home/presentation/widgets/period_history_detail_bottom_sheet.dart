import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/data/models/period_history_episode.dart';

/// Modal bottom sheet displaying day-by-day logs and symptoms for a specific menstrual period episode.
/// Built with fully responsive layout avoiding any text overflow across mobile screens.
class PeriodHistoryDetailBottomSheet extends StatelessWidget {
  final PeriodHistoryEpisode episode;

  const PeriodHistoryDetailBottomSheet({
    super.key,
    required this.episode,
  });

  static Future<void> show(
    BuildContext context, {
    required PeriodHistoryEpisode episode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodHistoryDetailBottomSheet(episode: episode),
    );
  }

  static const _flowLabels = [
    'Tidak Ada',
    'Flek / Bercak',
    'Darah Ringan',
    'Darah Sedang',
    'Darah Deras',
  ];

  static const _moodLabels = [
    'Bahagia',
    'Tenang',
    'Sedih',
    'Lelah',
    'Nyeri',
    'Kembung',
  ];

  static const _symptomLabels = [
    'Kram Perut',
    'Kembung',
    'Kelelahan',
    'Sakit Kepala',
    'Sakit Pinggang',
    'Payudara Nyeri',
    'Jerawat',
    'Nafsu Makan',
  ];

  @override
  Widget build(BuildContext context) {
    final daily = episode.dailyRecords;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: AppSizes.space12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5DEE6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.space14),

          // Header Row with Title, Date Range, and Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.space8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian Siklus ${DateFormatter.monthNames[episode.startDate.month - 1]} ${episode.startDate.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormatter.format(episode.startDate)} – ${DateFormatter.format(episode.endDate)} (${episode.durationDays} Hari)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          const Divider(height: 1, color: Color(0xFFF3EEF5)),

          // Body: List of Daily Logs
          Expanded(
            child: daily.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSizes.space24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.space12),
                          const Text(
                            'Informasi Periode Haid',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.space6),
                          Text(
                            'Waktu haid (${DateFormatter.format(episode.startDate)} – ${DateFormatter.format(episode.endDate)}) tercatat aktif berdasarkan ${episode.notes.isNotEmpty ? episode.notes.first.toLowerCase() : 'konfirmasi dan prediksi siklus menstruasi'}. Anda tetap dapat menambahkan catatan kondisi fisik harian kapan saja.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space20,
                      vertical: AppSizes.space14,
                    ),
                    itemCount: daily.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.space12),
                    itemBuilder: (context, index) {
                      final item = daily[index];
                      final dayNumber =
                          item.date.difference(episode.startDate).inDays + 1;
                      final flow = _flowLabels[item.flowIndex.clamp(
                        0,
                        _flowLabels.length - 1,
                      )];
                      final mood = _moodLabels[item.moodIndex.clamp(
                        0,
                        _moodLabels.length - 1,
                      )];

                      return Container(
                        padding: const EdgeInsets.all(AppSizes.space14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFC),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                          border: Border.all(
                            color: const Color(0xFFEEEAF0),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Day Header Row (Fully Responsive, no overflow)
                            Row(
                              children: [
                                // Day Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Hari ke-$dayNumber',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.space8),

                                // Day & Date Name
                                Expanded(
                                  child: Text(
                                    DateFormatter.format(
                                      item.date,
                                      includeDayName: true,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.space8),

                                // Flow Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFD4E2),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.water_drop_rounded,
                                        size: 11,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        flow,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.space10),

                            // 2. Mood & Water Intake Badges Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F0FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.mood_rounded,
                                        size: 12,
                                        color: Color(0xFF8E24AA),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mood,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8E24AA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.space8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F7FA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_drink_rounded,
                                        size: 12,
                                        color: Color(0xFF00838F),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.waterCups} Gelas',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF00838F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 3. Symptoms Tags Wrap (if recorded)
                            if (item.symptoms.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.space8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: item.symptoms.map((sIdx) {
                                  final sName = sIdx >= 0 &&
                                          sIdx < _symptomLabels.length
                                      ? _symptomLabels[sIdx]
                                      : 'Gejala #$sIdx';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          sName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            // 4. Personal Notes Callout Box (if recorded)
                            if (item.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSizes.space10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9FB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFFE5EE),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.notes.trim(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textPrimary,
                                          fontStyle: FontStyle.italic,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSizes.space8),
        ],
      ),
    );
  }
}

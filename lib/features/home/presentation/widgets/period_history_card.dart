import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/data/models/period_history_episode.dart';

/// Interactive card presenting a single verified menstrual period episode.
class PeriodHistoryCard extends StatelessWidget {
  final PeriodHistoryEpisode episode;
  final VoidCallback? onDetailTap;

  const PeriodHistoryCard({
    super.key,
    required this.episode,
    this.onDetailTap,
  });

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
    final start = episode.startDate;
    final end = episode.endDate;
    final isNormalDuration =
        episode.durationDays >= 2 && episode.durationDays <= 7;
    final cycleLen = episode.cycleLength;
    final isNormalCycle =
        cycleLen != null && cycleLen >= 21 && cycleLen <= 35;

    final flowText = _flowLabels[episode.maxFlowIndex.clamp(0, _flowLabels.length - 1)];
    final moodText = _moodLabels[episode.dominantMoodIndex.clamp(0, _moodLabels.length - 1)];

    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: episode.isOngoing
              ? const Color(0xFFFFB8CC)
              : const Color(0xFFF3EDF5),
          width: episode.isOngoing ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: episode.isOngoing
                ? const Color(0xFFFF4D79).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Month Name & Clinical Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.space8),
                    decoration: BoxDecoration(
                      color: episode.isOngoing
                          ? const Color(0xFFFFF0F5)
                          : const Color(0xFFFFF5F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      size: 18,
                      color: episode.isOngoing
                          ? AppColors.primary
                          : const Color(0xFFFF6584),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormatter.monthNames[start.month - 1]} ${start.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        episode.isOngoing
                            ? 'Sedang Berlangsung'
                            : 'Siklus Selesai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: episode.isOngoing
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                  vertical: AppSizes.space4,
                ),
                decoration: BoxDecoration(
                  color: isNormalDuration
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                  border: Border.all(
                    color: isNormalDuration
                        ? const Color(0xFFC8E6C9)
                        : const Color(0xFFFFE0B2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isNormalDuration ? 'Normal' : 'Perlu Dicatat',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isNormalDuration
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),

          // 2. Date Range & Duration Highlight Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space12,
              vertical: AppSizes.space10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F7),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: const Color(0xFFFFDCE6), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rentang Tanggal Haid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          start.month == end.month && start.year == end.year
                              ? '${start.day} – ${DateFormatter.format(end)}'
                              : '${DateFormatter.format(start)} – ${DateFormatter.format(end)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space8,
                    vertical: AppSizes.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${episode.durationDays} Hari',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space10),

          // 3. Cycle Distance to Previous Period (if real adjacent period exists)
          if (cycleLen != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space10,
                vertical: AppSizes.space8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: const Color(0xFFEEEBF2), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.autorenew_rounded,
                    size: 15,
                    color: Color(0xFF8E24AA),
                  ),
                  const SizedBox(width: AppSizes.space8),
                  Expanded(
                    child: Text(
                      'Jarak Siklus dari periode sebelumnya: $cycleLen hari',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isNormalCycle
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isNormalCycle ? '21–35 hr (Normal)' : 'Variatif',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isNormalCycle
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space10),
          ],

          // 4. Clinical Badges Row: Flow Intensity & Mood
          Row(
            children: [
              _BadgePill(
                icon: Icons.water_drop_rounded,
                label: 'Aliran: $flowText',
                color: AppColors.primary,
                bgColor: const Color(0xFFFFF0F4),
              ),
              const SizedBox(width: AppSizes.space8),
              _BadgePill(
                icon: Icons.mood_rounded,
                label: 'Mood: $moodText',
                color: const Color(0xFF8E24AA),
                bgColor: const Color(0xFFF6F0FF),
              ),
            ],
          ),

          // 5. Symptoms Tags (if user recorded symptoms during this period)
          if (episode.symptoms.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: episode.symptoms.map((idx) {
                final label = idx >= 0 && idx < _symptomLabels.length
                    ? _symptomLabels[idx]
                    : 'Gejala #$idx';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        label,
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

          // 6. User Personal Notes (if recorded)
          if (episode.notes.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FA),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: const Color(0xFFEDE8F2), width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.space6),
                  Expanded(
                    child: Text(
                      episode.notes.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 7. Interactive Detail Action Button
          const SizedBox(height: AppSizes.space12),
          InkWell(
            onTap: onDetailTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F9),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: const Color(0xFFEEE8EE), width: 0.8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Rincian Harian',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

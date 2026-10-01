import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Dynamic Agenda section reflecting phase status, clinical health cues, and recorded logs for the selected date.
class CalendarAgendaSection extends StatelessWidget {
  final VoidCallback? onRecordTap;

  const CalendarAgendaSection({
    super.key,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final selectedDate = controller.selectedDate;
        final dayInfo = controller.selectedDayInfo;
        final record = controller.selectedDateRecord;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Formatted Selected Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agenda & Status Siklus',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  DateFormatter.format(selectedDate, includeDayName: true, shortMonth: true),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space14),

            // Item 1: Phase Status Card
            if (dayInfo != null) ...[
              _AgendaCard(
                icon: Icon(
                  dayInfo.isOvulationDay
                      ? Icons.spa_rounded
                      : dayInfo.isFertileDay
                          ? Icons.spa_outlined
                          : Icons.water_drop_rounded,
                  color: dayInfo.isOvulationDay
                      ? AppColors.ovulationSolid
                      : dayInfo.isFertileDay
                          ? AppColors.fertileWindowText
                          : AppColors.primary,
                  size: 24,
                ),
                iconBgColor: dayInfo.isOvulationDay
                    ? AppColors.ovulationSoft
                    : dayInfo.isFertileDay
                        ? AppColors.fertileWindowBg
                        : const Color(0xFFFFF0F4),
                title: '${dayInfo.phaseName} (Hari ke-${dayInfo.cycleDay})',
                subtitle: dayInfo.phaseShortDescription,
                tag: dayInfo.pregnancyProbabilityText,
                tagColor: dayInfo.isOvulationDay
                    ? AppColors.ovulationSolid
                    : dayInfo.isFertileDay
                        ? AppColors.fertileWindowText
                        : AppColors.primary,
                tagBgColor: dayInfo.isOvulationDay
                    ? AppColors.ovulationSoft
                    : dayInfo.isFertileDay
                        ? AppColors.fertileWindowBg
                        : const Color(0xFFFFF0F5),
                time: 'Fase Aktif',
              ),
              const SizedBox(height: AppSizes.space10),

              // Item 2: Physical & Nutrition Focus
              _AgendaCard(
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
                title: 'Panduan Fisik & Aktivitas',
                subtitle: dayInfo.physicalTip,
                time: 'Saran Medis',
              ),
              const SizedBox(height: AppSizes.space10),
            ],

            // Item 3: Logged Records or Call-to-action
            if (record != null) ...[
              _AgendaCard(
                icon: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                title: 'Catatan Harian Tersimpan',
                subtitle: 'Minum: ${record.waterCups} gelas • Aktivitas: ${_getExerciseName(record.exerciseIndex)}',
                tag: record.notes.isNotEmpty ? record.notes : 'Data tercatat',
                time: 'Tercatat',
              ),
            ] else ...[
              InkWell(
                onTap: onRecordTap,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space14,
                    vertical: AppSizes.space12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F9),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    border: Border.all(color: const Color(0xFFFFD4E2), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum Ada Catatan Hari Ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ketuk untuk mencatat darah haid, mood, atau gejala tubuh',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getExerciseName(int index) {
    switch (index) {
      case 0:
        return 'Istirahat';
      case 1:
        return 'Ringan';
      case 2:
        return 'Sedang';
      case 3:
        return 'Intensif';
      default:
        return 'Ringan';
    }
  }
}

class _AgendaCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final String? tag;
  final String time;
  final Color? iconBgColor;
  final Color? tagColor;
  final Color? tagBgColor;

  const _AgendaCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tag,
    required this.time,
    this.iconBgColor,
    this.tagColor,
    this.tagBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space14,
        vertical: AppSizes.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: const Color(0xFFF6F3F8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon Box
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(AppSizes.space8),
            decoration: BoxDecoration(
              color: iconBgColor ?? const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: AppSizes.space12),

          // Center Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (tag != null) ...[
                  const SizedBox(height: AppSizes.space4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space8,
                      vertical: AppSizes.space2,
                    ),
                    decoration: BoxDecoration(
                      color: tagBgColor ?? const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tagColor ?? AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right Status
          const SizedBox(width: AppSizes.space8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/data/models/period_history_episode.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Interactive monthly calendar card displaying actual period bleeding dates
/// and daily log indicators for the selected month within the 6-month history window.
class PeriodHistoryCalendarCard extends StatelessWidget {
  final DateTime displayedMonth;
  final List<PeriodHistoryEpisode> monthEpisodes;
  final List<CycleRecordModel> records;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final bool hasPrevMonth;
  final bool hasNextMonth;

  const PeriodHistoryCalendarCard({
    super.key,
    required this.displayedMonth,
    required this.monthEpisodes,
    required this.records,
    this.selectedDate,
    this.onDateSelected,
    this.onPrevMonth,
    this.onNextMonth,
    this.hasPrevMonth = true,
    this.hasNextMonth = true,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final leadingDays = startingWeekday - 1;
    final prevMonthLastDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      0,
    ).day;
    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    final periodEpisodeCount = monthEpisodes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: const Color(0xFFF3EDF5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Navigation Header Row: < [Bulan Tahun] >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Arrow (Previous Month) with styled background
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevMonth,
                isEnabled: hasPrevMonth,
                tooltip: 'Bulan Sebelumnya',
              ),

              // Center Month & Period Status Title
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormatter.formatMonthYear(displayedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: periodEpisodeCount > 0
                            ? const Color(0xFFFFF0F5)
                            : const Color(0xFFF5F3F6),
                        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                      ),
                      child: Text(
                        periodEpisodeCount > 0
                            ? '$periodEpisodeCount Periode Haid Tercatat'
                            : 'Tidak Ada Data Haid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: periodEpisodeCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Arrow (Next Month) with styled background
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
                isEnabled: hasNextMonth,
                tooltip: 'Bulan Berikutnya',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space14),

          // 2. Weekday Header Row (Sen - Min)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayHeader('Sen'),
              _WeekdayHeader('Sel'),
              _WeekdayHeader('Rab'),
              _WeekdayHeader('Kam'),
              _WeekdayHeader('Jum'),
              _WeekdayHeader('Sab'),
              _WeekdayHeader('Min'),
            ],
          ),
          const SizedBox(height: AppSizes.space8),

          // 3. Month Dates Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              DateTime cellDate;
              bool isOutsideMonth = false;

              if (index < leadingDays) {
                final dayNumber = prevMonthLastDay - (leadingDays - index - 1);
                cellDate = DateTime(
                  displayedMonth.year,
                  displayedMonth.month - 1,
                  dayNumber,
                );
                isOutsideMonth = true;
              } else if (index >= leadingDays + daysInMonth) {
                final dayNumber = index - (leadingDays + daysInMonth) + 1;
                cellDate = DateTime(
                  displayedMonth.year,
                  displayedMonth.month + 1,
                  dayNumber,
                );
                isOutsideMonth = true;
              } else {
                final dayNumber = index - leadingDays + 1;
                cellDate = DateTime(
                  displayedMonth.year,
                  displayedMonth.month,
                  dayNumber,
                );
              }

              final normalizedCell = DateFormatter.dateOnly(cellDate);
              final isToday = DateFormatter.isSameDay(normalizedCell, DateTime.now());
              final isSelected = selectedDate != null &&
                  DateFormatter.isSameDay(normalizedCell, selectedDate);

              // Check if cell is a bleeding period day
              final isPeriodDay = !isOutsideMonth &&
                  monthEpisodes.any((ep) {
                    final start = DateFormatter.dateOnly(ep.startDate);
                    final end = DateFormatter.dateOnly(ep.endDate);
                    return !normalizedCell.isBefore(start) &&
                        !normalizedCell.isAfter(end);
                  });

              // Check if daily record exists with symptoms or notes
              final hasRecordLog = !isOutsideMonth &&
                  records.any((r) {
                    return DateFormatter.isSameDay(r.date, normalizedCell) &&
                        (r.symptoms.isNotEmpty || r.notes.trim().isNotEmpty);
                  });

              return GestureDetector(
                onTap: isOutsideMonth
                    ? null
                    : () => onDateSelected?.call(normalizedCell),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isPeriodDay
                          ? AppColors.primary
                          : (isSelected
                              ? const Color(0xFFFFF0F5)
                              : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday && !isPeriodDay
                          ? Border.all(color: AppColors.primary, width: 1.2)
                          : (isSelected && !isPeriodDay
                              ? Border.all(color: const Color(0xFFFFB8CC), width: 1.0)
                              : null),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${cellDate.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isPeriodDay || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isOutsideMonth
                                ? const Color(0xFFDCD6DE)
                                : (isPeriodDay
                                    ? Colors.white
                                    : (isToday
                                        ? AppColors.primary
                                        : AppColors.textPrimary)),
                          ),
                        ),
                        // Log indicator dot below day number for non-period logs
                        if (hasRecordLog && !isPeriodDay)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E24AA),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.space12),

          // 4. Calendar Legend Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space10,
              vertical: AppSizes.space6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: const Color(0xFFEEEAF0), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.primary,
                  label: 'Hari Menstruasi (Haid)',
                  isCircle: true,
                ),
                const SizedBox(width: AppSizes.space16),
                _LegendItem(
                  color: const Color(0xFF8E24AA),
                  label: 'Catatan Gejala/Kondisi',
                  isDot: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;

  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircle;
  final bool isDot;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isCircle = false,
    this.isDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDot ? 6 : 10,
          height: isDot ? 6 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final String tooltip;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFFFFF0F5)
                  : const Color(0xFFF7F5F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFFFFDCE6)
                    : const Color(0xFFEBE6EE),
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isEnabled
                  ? AppColors.primary
                  : const Color(0xFFC7C2CC),
            ),
          ),
        ),
      ),
    );
  }
}


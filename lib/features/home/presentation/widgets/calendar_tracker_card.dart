import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';

/// Dynamic calendar tracker card calculating period, fertile window, and ovulation per day.
class CalendarTrackerCard extends StatelessWidget {
  final bool isCompact;
  final ValueChanged<DateTime>? onDateSelected;

  const CalendarTrackerCard({
    super.key,
    this.isCompact = false,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final displayedMonth = controller.displayedMonth;
        final selectedDate = controller.selectedDate;

        final profile = controller.userProfile?.cycleProfile ??
            CycleProfileModel(
              trackingGoal: 'predict_period',
              lastPeriodDate: DateTime.now().subtract(const Duration(days: 7)),
              cycleLength: 28,
              periodDuration: 5,
              regularity: 'regular',
              birthDate: DateTime(2000, 1, 1),
            );

        final engine = CycleEngineService();
        final periodDates = engine.getPeriodDatesForMonth(
          profile: profile,
          year: displayedMonth.year,
          month: displayedMonth.month,
        );
        final fertileDates = engine.getFertileDatesForMonth(
          profile: profile,
          year: displayedMonth.year,
          month: displayedMonth.month,
        );
        final ovulationDates = engine.getOvulationDatesForMonth(
          profile: profile,
          year: displayedMonth.year,
          month: displayedMonth.month,
        );

        // Days in month calculation
        final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
        final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
        // Weekday: 1 (Mon) to 7 (Sun)
        final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday

        final prevMonthLastDay = DateTime(displayedMonth.year, displayedMonth.month, 0).day;
        final leadingDays = startingWeekday - 1;

        final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

        return Container(
          padding: const EdgeInsets.all(AppSizes.space20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Month Title & Navigation Arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatMonthYear(displayedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => controller.changeMonth(-1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSizes.space4),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.space4),
                      InkWell(
                        onTap: () => controller.jumpToToday(),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.space8,
                            vertical: AppSizes.space4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          child: const Text(
                            'Hari ini',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.space4),
                      InkWell(
                        onTap: () => controller.changeMonth(1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSizes.space4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space16),

              // Day Names Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _DayHeader('Sen'),
                  _DayHeader('Sel'),
                  _DayHeader('Rab'),
                  _DayHeader('Kam'),
                  _DayHeader('Jum'),
                  _DayHeader('Sab'),
                  _DayHeader('Min'),
                ],
              ),
              const SizedBox(height: AppSizes.space12),

              // Calendar Grid
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
                    cellDate = DateTime(displayedMonth.year, displayedMonth.month - 1, dayNumber);
                    isOutsideMonth = true;
                  } else if (index >= leadingDays + daysInMonth) {
                    final dayNumber = index - (leadingDays + daysInMonth) + 1;
                    cellDate = DateTime(displayedMonth.year, displayedMonth.month + 1, dayNumber);
                    isOutsideMonth = true;
                  } else {
                    final dayNumber = index - leadingDays + 1;
                    cellDate = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
                  }

                  final normalizedDate = DateFormatter.dateOnly(cellDate);
                  final isSelected = DateFormatter.isSameDay(normalizedDate, selectedDate);
                  final isToday = DateFormatter.isSameDay(normalizedDate, DateTime.now());

                  final isPeriod = periodDates.contains(normalizedDate);
                  final isFertile = fertileDates.contains(normalizedDate);
                  final isOvulation = ovulationDates.contains(normalizedDate);

                  return _CalendarDayCell(
                    date: cellDate,
                    isOutsideMonth: isOutsideMonth,
                    isSelected: isSelected,
                    isToday: isToday,
                    isPeriod: isPeriod,
                    isFertile: isFertile,
                    isOvulation: isOvulation,
                    onTap: () {
                      controller.selectDate(cellDate);
                      if (onDateSelected != null) {
                        onDateSelected!(cellDate);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppSizes.space16),

              // Legend
              const Divider(height: 1, color: Color(0xFFF4EFF5)),
              const SizedBox(height: AppSizes.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _LegendItem(color: AppColors.periodSolid, label: 'Menstruasi'),
                  _LegendItem(
                    color: AppColors.fertileWindowBorder,
                    label: 'Masa Subur',
                    isOutline: true,
                  ),
                  _LegendItem(
                    color: AppColors.ovulationSolid,
                    label: 'Ovulasi',
                    hasDot: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.calendarHeader,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isOutsideMonth;
  final bool isSelected;
  final bool isToday;
  final bool isPeriod;
  final bool isFertile;
  final bool isOvulation;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isOutsideMonth,
    required this.isSelected,
    required this.isToday,
    required this.isPeriod,
    required this.isFertile,
    required this.isOvulation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutsideMonth) {
      return Center(
        child: Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD4CFD7),
          ),
        ),
      );
    }

    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    BoxBorder? border;

    if (isPeriod) {
      bgColor = AppColors.periodSolid;
      textColor = AppColors.textWhite;
    } else if (isOvulation) {
      bgColor = AppColors.ovulationSolid;
      textColor = AppColors.textWhite;
    } else if (isFertile) {
      bgColor = AppColors.fertileWindowBg;
      textColor = AppColors.fertileNumberText;
      border = Border.all(color: AppColors.fertileWindowBorder, width: 1.0);
    }

    if (isSelected) {
      if (isPeriod || isOvulation) {
        border = Border.all(color: Colors.white, width: 2.0);
      } else {
        border = Border.all(color: AppColors.primary, width: 2.0);
      }
    } else if (isToday && !isPeriod && !isOvulation) {
      border = Border.all(color: const Color(0xFFC4BCC7), width: 1.2);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
          boxShadow: isSelected && (isPeriod || isOvulation)
              ? [
                  BoxShadow(
                    color: (isPeriod ? AppColors.periodSolid : AppColors.ovulationSolid)
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isPeriod || isOvulation || isSelected || isToday || isFertile)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isOvulation)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasDot;
  final bool isOutline;

  const _LegendItem({
    required this.color,
    required this.label,
    this.hasDot = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: isOutline ? AppColors.fertileWindowBg : color,
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: color, width: 1.2) : null,
          ),
          child: hasDot
              ? Center(
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSizes.space6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

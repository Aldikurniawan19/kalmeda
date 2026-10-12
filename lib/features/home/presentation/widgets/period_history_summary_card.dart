import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/data/models/period_history_episode.dart';

/// Clinical summary card aggregating cycle metrics over the last 6 months.
/// Strictly shows metrics derived from actual user records without simulated cycles.
class PeriodHistorySummaryCard extends StatelessWidget {
  final List<PeriodHistoryEpisode> episodes;
  final int? monthsCount;

  const PeriodHistorySummaryCard({
    super.key,
    required this.episodes,
    this.monthsCount,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate averages based purely on existing data
    final totalPeriods = episodes.length;

    final avgDuration = episodes.map((e) => e.durationDays).reduce((a, b) => a + b) /
        totalPeriods;

    final cyclesWithLength =
        episodes.where((e) => e.cycleLength != null).map((e) => e.cycleLength!).toList();

    final hasCycleLengthData = cyclesWithLength.isNotEmpty;
    final avgCycleLength = hasCycleLengthData
        ? (cyclesWithLength.reduce((a, b) => a + b) / cyclesWithLength.length).round()
        : null;

    final isNormalDuration = avgDuration >= 2 && avgDuration <= 7;
    final isNormalCycle = avgCycleLength != null && avgCycleLength >= 21 && avgCycleLength <= 35;

    final int effectiveMonthsCount;
    if (monthsCount != null && monthsCount! > 0) {
      effectiveMonthsCount = monthsCount!.clamp(1, 6);
    } else {
      final uniqueMonths = <int>{};
      for (final ep in episodes) {
        uniqueMonths.add(ep.startDate.year * 12 + ep.startDate.month);
        uniqueMonths.add(ep.endDate.year * 12 + ep.endDate.month);
      }
      effectiveMonthsCount =
          (uniqueMonths.isNotEmpty ? uniqueMonths.length : 1).clamp(1, 6);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: const Color(0xFFFFE0EC), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9FB), Color(0xFFFFFFFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D79).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Clinical Regularity Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.space6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.space8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ringkasan Siklus $effectiveMonthsCount Bulan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                  vertical: AppSizes.space4,
                ),
                decoration: BoxDecoration(
                  color: isNormalDuration && (avgCycleLength == null || isNormalCycle)
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                  border: Border.all(
                    color: isNormalDuration && (avgCycleLength == null || isNormalCycle)
                        ? const Color(0xFFC8E6C9)
                        : const Color(0xFFFFE0B2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isNormalDuration && (avgCycleLength == null || isNormalCycle)
                      ? 'Siklus Normal'
                      : 'Perlu Dicatat Rutin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isNormalDuration && (avgCycleLength == null || isNormalCycle)
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space14),

          // 3 Dynamic Metrics Row
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  icon: Icons.calendar_month_rounded,
                  value: '$totalPeriods',
                  unit: ' Siklus',
                  label: 'Periode Tercatat',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: _SummaryMetricTile(
                  icon: Icons.water_drop_outlined,
                  value: avgDuration.toStringAsFixed(avgDuration % 1 == 0 ? 0 : 1),
                  unit: ' Hari',
                  label: 'Rata-rata Durasi',
                  color: const Color(0xFF8E24AA),
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: _SummaryMetricTile(
                  icon: Icons.autorenew_rounded,
                  value: avgCycleLength != null ? '$avgCycleLength' : '—',
                  unit: avgCycleLength != null ? ' Hari' : '',
                  label: avgCycleLength != null ? 'Rata-rata Jarak' : 'Perlu 2+ Siklus',
                  color: const Color(0xFF0288D1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),

          // Educational Footnote Box based on WHO / ACOG standard
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space10,
              vertical: AppSizes.space8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FA),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: const Color(0xFFEFEBF2), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.space6),
                Expanded(
                  child: Text(
                    hasCycleLengthData
                        ? 'Rentang medis normal: durasi haid 2–7 hari dengan jarak antar siklus 21–35 hari (ACOG).'
                        : 'Jarak antar siklus dapat dihitung setelah Anda memiliki minimal 2 periode haid tercatat.',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _SummaryMetricTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space6,
        vertical: AppSizes.space10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: AppSizes.space4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

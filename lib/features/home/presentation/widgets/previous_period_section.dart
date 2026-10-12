import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/screens/period_history_screen.dart';

/// Responsive section on the Home Screen displaying previous month's period dates, cycle duration, and clinical history.
class PreviousPeriodSection extends StatelessWidget {
  final VoidCallback? onAddRecordTap;

  const PreviousPeriodSection({super.key, this.onAddRecordTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final profile = controller.userProfile?.cycleProfile;

        if (profile == null) {
          return const SizedBox.shrink();
        }

        final lmp = DateFormatter.dateOnly(profile.lastPeriodDate);
        final cycleLength = profile.cycleLength > 0 ? profile.cycleLength : 28;
        final periodDuration =
            profile.periodDuration > 0 ? profile.periodDuration : 5;

        // Calculate previous cycle dates
        final prevPeriodStart = lmp.subtract(Duration(days: cycleLength));
        final prevPeriodEnd = prevPeriodStart.add(
          Duration(days: periodDuration - 1),
        );

        // Calculate 2 cycles ago dates
        final twoCyclesAgoStart = lmp.subtract(Duration(days: cycleLength * 2));
        final twoCyclesAgoEnd = twoCyclesAgoStart.add(
          Duration(days: periodDuration - 1),
        );

        final isNormalCycle = cycleLength >= 21 && cycleLength <= 35;
        final isNormalDuration = periodDuration >= 2 && periodDuration <= 7;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with Title & Action Button (Responsive)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSizes.space8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Riwayat Haid Sebelumnya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.space8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => PeriodHistoryScreen.open(
                      context,
                      onAddRecord: onAddRecordTap,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.space6,
                        vertical: AppSizes.space4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space12),

            // Primary Highlight Card: Previous Month Menstruation
            Container(
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFFFE0EC), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8FA), Color(0xFFFFFFFF)],
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
                  // Top Row: Month Name & Status Badge (Responsive)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
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
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.space10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${DateFormatter.monthNames[prevPeriodStart.month - 1]} ${prevPeriodStart.year}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Siklus Haid Terakhir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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
                          color: isNormalCycle && isNormalDuration
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusCircular,
                          ),
                          border: Border.all(
                            color: isNormalCycle && isNormalDuration
                                ? const Color(0xFFC8E6C9)
                                : const Color(0xFFFFE0B2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isNormalCycle && isNormalDuration
                              ? 'Normal • Teratur'
                              : 'Perlu Dicatat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isNormalCycle && isNormalDuration
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space14),

                  // Highlighted Date Interval Box (Responsive Scaled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space12,
                      vertical: AppSizes.space10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(
                        color: const Color(0xFFFFD4E2),
                        width: 1.0,
                      ),
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
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${DateFormatter.format(prevPeriodStart)} – ${DateFormatter.format(prevPeriodEnd)}',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.space14),

                  // 3 Key Metrics Row (Durasi, Jarak Siklus, Status) - Fully Responsive
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.water_drop_outlined,
                          title: '$periodDuration Hari',
                          subtitle: 'Lama Haid',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space8),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.autorenew_rounded,
                          title: '$cycleLength Hari',
                          subtitle: 'Jarak Siklus',
                          color: const Color(0xFF8E24AA),
                        ),
                      ),
                      const SizedBox(width: AppSizes.space8),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.verified_outlined,
                          title: isNormalCycle ? 'Teratur' : 'Variatif',
                          subtitle: 'Status Siklus',
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space14),

                  // Comparison with 2 Cycles Ago (Clean 2-line Responsive Row)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space12,
                      vertical: AppSizes.space10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFC),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(
                        color: const Color(0xFFEEEBF2),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.space6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '2 Siklus Sebelumnya',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${DateFormatter.formatDayMonth(twoCyclesAgoStart)} – ${DateFormatter.formatDayMonth(twoCyclesAgoEnd)} ($periodDuration hari)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall,
                            ),
                          ),
                          child: Text(
                            '$cycleLength hr',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: AppSizes.space4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              maxLines: 1,
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

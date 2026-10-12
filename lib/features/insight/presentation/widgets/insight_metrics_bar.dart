import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';

/// Dynamic 4-column overview metrics bar reflecting current cycle profile and logs.
/// Fully responsive with auto-scaling text to prevent single-character line wraps.
class InsightMetricsBar extends StatelessWidget {
  const InsightMetricsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HomeController(),
      builder: (context, _) {
        final controller = HomeController();
        final overview = controller.cycleOverview;

        final duration = overview?.periodDuration.toString() ?? '5';
        final cycleLength = overview?.cycleLength.toString() ?? '28';
        final regularity = _formatRegularity(overview?.regularity ?? 'regular');
        final currentPhase = overview?.currentDayInfo.phaseName ?? 'Normal';

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.space14,
            horizontal: AppSizes.space4,
          ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricItem(
                  iconPath: 'assets/icon/darahIsght.png',
                  bgColor: const Color(0xFFFFF0F3),
                  value: duration,
                  unit: ' hari',
                  label: 'Rata-rata Durasi Haid',
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _MetricItem(
                  iconPath: 'assets/icon/kalenderIsght.png',
                  bgColor: const Color(0xFFF3F0FF),
                  value: cycleLength,
                  unit: ' hari',
                  label: 'Panjang Siklus',
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _MetricItem(
                  iconPath: 'assets/icon/hatiIsght.png',
                  bgColor: const Color(0xFFFFF0F5),
                  value: regularity,
                  label: 'Keteraturan Siklus',
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _MetricItem(
                  iconPath: 'assets/icon/iconNyeri.png',
                  bgColor: const Color(0xFFFFF0F3),
                  value: currentPhase.replaceAll('Fase ', ''),
                  label: 'Status Fase Hari Ini',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRegularity(String key) {
    switch (key) {
      case 'regular':
        return 'Teratur';
      case 'sometimes_variable':
        return 'Bervariasi';
      case 'irregular':
        return 'Tidak Teratur';
      default:
        return 'Teratur';
    }
  }
}

class _MetricItem extends StatelessWidget {
  final String iconPath;
  final Color bgColor;
  final String value;
  final String? unit;
  final String label;

  const _MetricItem({
    required this.iconPath,
    required this.bgColor,
    required this.value,
    this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(AppSizes.space6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSizes.space8),
          // Auto-scaling responsive value to prevent single-character line wraps
          SizedBox(
            height: 20,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: RichText(
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    children: [
                      if (unit != null)
                        TextSpan(
                          text: unit!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space4),
          // Uniform height for labels across all 4 columns
          SizedBox(
            height: 26,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      margin: const EdgeInsets.only(top: 6),
      color: const Color(0xFFF3EEF5),
    );
  }
}

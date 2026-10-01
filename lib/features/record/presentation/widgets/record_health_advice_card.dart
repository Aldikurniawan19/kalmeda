import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/daily_insight_advisor.dart';

/// Real-time health guidance card dynamically updated according to user's daily record selections.
class RecordHealthAdviceCard extends StatelessWidget {
  final int flowIndex;
  final int moodIndex;
  final Set<int> symptoms;
  final int waterCups;
  final int exerciseIndex;

  const RecordHealthAdviceCard({
    super.key,
    required this.flowIndex,
    required this.moodIndex,
    required this.symptoms,
    required this.waterCups,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    final adviceList = DailyInsightAdvisor.generateAdvice(
      flowIndex: flowIndex,
      moodIndex: moodIndex,
      symptoms: symptoms,
      waterCups: waterCups,
      exerciseIndex: exerciseIndex,
    );

    final summaryText = DailyInsightAdvisor.formatConditionSummary(
      flowIndex: flowIndex,
      symptoms: symptoms,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: const Color(0xFFFFDDE6), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7F9),
            Color(0xFFFFFFFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D79).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.space6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.space10),
              const Expanded(
                child: Text(
                  'Saran & Panduan Kesehatan Hari Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),

          // Condition Summary Chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space10,
              vertical: AppSizes.space4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: const Color(0xFFFFD4E2), width: 1.0),
            ),
            child: Text(
              summaryText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space14),

          // Dynamic Advice Items List
          ...adviceList.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.space10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(AppSizes.space4),
                    decoration: BoxDecoration(
                      color: item.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      size: 14,
                      color: item.iconColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

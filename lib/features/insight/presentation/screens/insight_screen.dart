import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/features/insight/presentation/widgets/activity_notes_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/cycle_history_chart_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_banner_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_header.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_metrics_bar.dart';
import 'package:menstracker/features/insight/presentation/widgets/insight_tip_card.dart';
import 'package:menstracker/features/insight/presentation/widgets/mood_condition_chart_card.dart';

/// Insight Screen displaying health trends, cycle statistics, and mood analytics.
class InsightScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTapped;
  final bool showBottomNav;

  const InsightScreen({
    super.key,
    this.onNavTapped,
    this.showBottomNav = false,
  });

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  int _currentNavIndex = 3;

  @override
  void initState() {
    super.initState();
    HomeController().loadData(silent: true);
  }

  void _handleNavTapped(int index) {
    if (widget.onNavTapped != null) {
      widget.onNavTapped!(index);
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space20,
            vertical: AppSizes.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InsightHeader(onBack: () => _handleNavTapped(0)),
              const SizedBox(height: AppSizes.space14),

              // Summary banner
              const InsightBannerCard(),
              const SizedBox(height: AppSizes.space20),

              // Interactive Clinical Chatbot Consultation Card
              _ChatbotConsultationCard(
                onTap: () => ChatbotScreen.open(
                  context,
                  onNavigateTab: widget.onNavTapped,
                ),
              ),
              const SizedBox(height: AppSizes.space20),

              // Dynamic cycle summary metrics bar
              const InsightMetricsBar(),
              const SizedBox(height: AppSizes.space20),

              // Cycle history bar chart
              const CycleHistoryChartCard(),
              const SizedBox(height: AppSizes.space20),

              // Mood & condition distribution donut chart
              const MoodConditionChartCard(),
              const SizedBox(height: AppSizes.space20),

              // Activity & Notes overview
              const ActivityNotesCard(),
              const SizedBox(height: AppSizes.space16),

              // Health tip card
              const InsightTipCard(),
              const SizedBox(height: AppSizes.space32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? HomeBottomNavbar(
              selectedIndex: _currentNavIndex,
              onItemTapped: _handleNavTapped,
            )
          : null,
    );
  }
}

class _ChatbotConsultationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatbotConsultationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: const Color(0xFFFFCCDA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D79).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.space8),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanya Asisten Medis Kalmeda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Punya keluhan nyeri, siklus telat, atau mitos?',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space12),
          const Text(
            'Konsultasikan pertanyaan seputar kesehatan reproduksi secara interaktif dengan panduan klinis terverifikasi (ACOG & Kemenkes RI).',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Ada Pertanyaan? Chat Yuk!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

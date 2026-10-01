import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/calendar/presentation/widgets/calendar_agenda_section.dart';
import 'package:menstracker/features/calendar/presentation/widgets/calendar_header.dart';
import 'package:menstracker/features/calendar/presentation/widgets/calendar_info_card.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/calendar_tracker_card.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';

/// Calendar screen for viewing monthly status, daily agendas, and dynamic cycle predictions.
class CalendarScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTapped;
  final bool showBottomNav;

  const CalendarScreen({
    super.key,
    this.onNavTapped,
    this.showBottomNav = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _currentNavIndex = 1;

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
              // Top Header with Back button & Calendar Action
              CalendarHeader(
                onBack: () => _handleNavTapped(0),
              ),
              const SizedBox(height: AppSizes.space14),

              // Calendar Card with full dynamic dates
              CalendarTrackerCard(
                onDateSelected: (date) {
                  // Instant reactive update handled by HomeController
                },
              ),
              const SizedBox(height: AppSizes.space20),

              // Dynamic Agenda for Selected Date
              CalendarAgendaSection(
                onRecordTap: () => _handleNavTapped(2),
              ),
              const SizedBox(height: AppSizes.space20),

              // Informasi Kalender Card with illustration
              const CalendarInfoCard(),
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

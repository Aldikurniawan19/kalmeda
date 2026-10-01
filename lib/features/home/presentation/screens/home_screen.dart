import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/reminder_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/cycle_history_bottom_sheet.dart';
import 'package:menstracker/features/home/presentation/widgets/cycle_tracker_card.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/features/home/presentation/widgets/home_header.dart';
import 'package:menstracker/features/home/presentation/widgets/mood_condition_section.dart';
import 'package:menstracker/features/home/presentation/widgets/period_active_checkin_card.dart';
import 'package:menstracker/features/home/presentation/widgets/period_start_confirm_card.dart';
import 'package:menstracker/features/home/presentation/widgets/quick_menu_bar.dart';
import 'package:menstracker/features/home/presentation/widgets/quick_mood_bottom_sheet.dart';
import 'package:menstracker/features/home/presentation/widgets/reminder_settings_bottom_sheet.dart';
import 'package:menstracker/features/insight/presentation/screens/insight_screen.dart';
import 'package:menstracker/features/profile/presentation/screens/profile_screen.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:menstracker/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:menstracker/features/record/presentation/controllers/daily_checkin_service.dart';
import 'package:menstracker/features/record/presentation/screens/record_screen.dart';

/// Main Home container with WhatsApp-style instant tab switching (IndexedStack) and static bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load initial data silently
    HomeController().loadData(silent: true);
    ReminderController().loadPreferences().then((_) {
      ReminderController().syncScheduledNotifications();
    });

    // Record app open and schedule inactivity reminder (2-day no-open notification)
    ReminderController().recordAppOpened();

    // Synchronize daily inactivity notification
    DailyCheckinService().syncDailyInactivityNotification();

    // Listen for notification tap payloads (e.g. open_record)
    NotificationService.onNotificationPayload.addListener(_handleNotificationPayload);
    _handleNotificationPayload();

    // Check mandatory daily condition check-in prompt after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyPrompt();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-record app open to reset the 2-day inactivity timer
      ReminderController().recordAppOpened();
      DailyCheckinService().syncDailyInactivityNotification();
      _checkDailyPrompt();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Wajib: Otomatis hapus riwayat chat saat pengguna keluar dari aplikasi demi kerahasiaan medis
      ChatbotController().clearChat();
    }
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.onNotificationPayload.value;
    if (payload == 'open_record') {
      NotificationService.onNotificationPayload.value = null;
      _onNavTapped(2);
    }
  }

  void _checkDailyPrompt() {
    if (!mounted) return;
    DailyCheckinService().checkAndPromptIfNeeded(
      context,
      onNavigateToRecord: () => _onNavTapped(2),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.onNotificationPayload.removeListener(_handleNotificationPayload);
    super.dispose();
  }

  void _onNavTapped(int index) {
    if (_currentNavIndex == index) return;

    setState(() {
      _currentNavIndex = index;
    });

    // Silently refresh in background without resetting state or showing loading spinners
    HomeController().loadData(silent: true);
  }

  Widget _buildHomeTab() {
    return SafeArea(
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
            // Header with greetings & illustration
            const HomeHeader(),
            const SizedBox(height: AppSizes.space12),

            // 1. Period Start Confirmation & Custom Date Adjustment Banner
            const PeriodStartConfirmCard(),

            // 2. Current cycle progress card with countdown & flower
            CycleTrackerCard(
              onRecordTap: () => _onNavTapped(2),
            ),
            const SizedBox(height: AppSizes.space16),

            // 3. Active Period Daily Check-in & Clinical Guidance
            PeriodActiveCheckinCard(
              onRecordTap: () => _onNavTapped(2),
            ),

            // 4. 4-item interactive quick navigation menu
            QuickMenuBar(
              onKalenderTap: () => _onNavTapped(1),
              onRiwayatTap: () => CycleHistoryBottomSheet.show(
                context,
                onAddRecord: () => _onNavTapped(2),
              ),
              onMoodTap: () => QuickMoodBottomSheet.show(
                context,
                onOpenFullRecord: () => _onNavTapped(2),
              ),
              onPengingatTap: () => ReminderSettingsBottomSheet.show(context),
            ),
            const SizedBox(height: AppSizes.space24),

            // 5. Mood and conditions daily chips + clinical health advice
            MoodConditionSection(
              onMoodSelected: (_) => _onNavTapped(2),
            ),
            const SizedBox(height: AppSizes.space32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      // WhatsApp-style tab switching: instant, keeps state alive, no horizontal sliding or reloading
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),
          CalendarScreen(
            onNavTapped: _onNavTapped,
            showBottomNav: false,
          ),
          RecordScreen(
            onNavTapped: _onNavTapped,
            showBottomNav: false,
          ),
          InsightScreen(
            onNavTapped: _onNavTapped,
            showBottomNav: false,
          ),
          ProfileScreen(
            onNavTapped: _onNavTapped,
            showBottomNav: false,
          ),
        ],
      ),
      // Floating Assistant Button for instant clinical consultation
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => ChatbotScreen.open(context, onNavigateTab: _onNavTapped),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 20),
              label: const Text(
                'Tanya Kalmeda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            )
          : null,
      // Fixed static bottom navbar
      bottomNavigationBar: HomeBottomNavbar(
        selectedIndex: _currentNavIndex,
        onItemTapped: _onNavTapped,
      ),
    );
  }
}

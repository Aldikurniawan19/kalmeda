import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:menstracker/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/reminder_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/home_mascot_fab.dart';
import 'package:menstracker/features/home/presentation/widgets/home_mascot_greeting_overlay.dart';
import 'package:menstracker/features/home/presentation/screens/period_history_screen.dart';
import 'package:menstracker/features/home/presentation/widgets/cycle_tracker_card.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/features/home/presentation/widgets/home_header.dart';
import 'package:menstracker/features/home/presentation/widgets/previous_period_section.dart';
import 'package:menstracker/features/home/presentation/widgets/daily_health_guidance_card.dart';
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
  bool _isFabExtended = false;
  bool _showGreetingOverlay = true;
  final GlobalKey _mascotFabKey = GlobalKey();
  Timer? _fabExpandTimer;
  Timer? _fabCollapseTimer;

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
    NotificationService.onNotificationPayload.addListener(
      _handleNotificationPayload,
    );
    _handleNotificationPayload();

    // Check mandatory daily condition check-in prompt after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyPrompt();
      AppUpdateController().checkAndPromptSilently(context);
    });

    // Animate Tanya Kalmeda button: start as circle, expand after 1s, then collapse back after 4s
    _startFabAnimationSequence();
  }

  void _startFabAnimationSequence() {
    _fabExpandTimer?.cancel();
    _fabCollapseTimer?.cancel();

    // 1. Setelah 1 detik, munculkan kata "Tanya Kalmeda"
    _fabExpandTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isFabExtended = true;
        });

        // 2. Tampilkan selama 4 detik, lalu kembalikan menjadi hanya icon
        _fabCollapseTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _isFabExtended = false;
            });
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-record app open to reset the 2-day inactivity timer
      ReminderController().recordAppOpened();
      DailyCheckinService().syncDailyInactivityNotification();
      _checkDailyPrompt();
      AppUpdateController().checkAndPromptSilently(context);
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
    _fabExpandTimer?.cancel();
    _fabCollapseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.onNotificationPayload.removeListener(
      _handleNotificationPayload,
    );
    super.dispose();
  }

  void _openChatbot() {
    Offset? fabPos;
    final renderBox =
        _mascotFabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      fabPos = renderBox.localToGlobal(const Offset(31, 31));
    }
    ChatbotScreen.open(
      context,
      onNavigateTab: _onNavTapped,
      initialFabPosition: fabPos,
    );
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
            CycleTrackerCard(onRecordTap: () => _onNavTapped(2)),
            const SizedBox(height: AppSizes.space16),

            // 3. Active Period Daily Check-in & Clinical Guidance
            PeriodActiveCheckinCard(onRecordTap: () => _onNavTapped(2)),

            // 4. 4-item interactive quick navigation menu
            QuickMenuBar(
              onKalenderTap: () => _onNavTapped(1),
              onRiwayatTap: () => PeriodHistoryScreen.open(
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

            // 5. Previous month's period history & cycle metrics
            PreviousPeriodSection(onAddRecordTap: () => _onNavTapped(2)),
            const SizedBox(height: AppSizes.space24),

            // 6. Clinical food, activity, and relaxation guidance for today
            const DailyHealthGuidanceCard(),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          // WhatsApp-style tab switching: instant, keeps state alive, no horizontal sliding or reloading
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              _buildHomeTab(),
              CalendarScreen(onNavTapped: _onNavTapped, showBottomNav: false),
              RecordScreen(onNavTapped: _onNavTapped, showBottomNav: false),
              InsightScreen(onNavTapped: _onNavTapped, showBottomNav: false),
              ProfileScreen(onNavTapped: _onNavTapped, showBottomNav: false),
            ],
          ),
          // Floating Mascot Assistant Button replacing old chatbot button
          floatingActionButton: _currentNavIndex == 0
              ? HomeMascotFab(
                  fabKey: _mascotFabKey,
                  isExtended: _isFabExtended,
                  isVisible: !_showGreetingOverlay,
                  onTap: _openChatbot,
                )
              : null,
          // Fixed static bottom navbar
          bottomNavigationBar: HomeBottomNavbar(
            selectedIndex: _currentNavIndex,
            onItemTapped: _onNavTapped,
          ),
        ),

        // Centered Greeting Overlay on App Launch that swoops into the Mascot FAB
        if (_showGreetingOverlay)
          HomeMascotGreetingOverlay(
            targetFabGlobalKey: _mascotFabKey,
            onDismissed: () {
              if (mounted) {
                setState(() {
                  _showGreetingOverlay = false;
                });
              }
            },
          ),
      ],
    );
  }
}

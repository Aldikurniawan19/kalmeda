import 'package:flutter/material.dart';
import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/core/theme/app_theme.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:menstracker/features/splash/presentation/screens/splash_screen.dart';
import 'package:menstracker/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('FirebaseService initialization error: $e');
  }

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }

  runApp(const MenstrackerApp());
}

/// Custom scroll behavior disabling elastic overscroll bouncing across all platforms.
class FixedScrollBehavior extends ScrollBehavior {
  const FixedScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// Root widget of the Menstracker application with app lifecycle observer for privacy.
class MenstrackerApp extends StatefulWidget {
  const MenstrackerApp({super.key});

  @override
  State<MenstrackerApp> createState() => _MenstrackerAppState();
}

class _MenstrackerAppState extends State<MenstrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure chat session starts clean on app launch
    ChatbotController().clearChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically wipe medical consultation chat when user exits or backgrounds the app
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ChatbotController().clearChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalmeda',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const FixedScrollBehavior(),
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}


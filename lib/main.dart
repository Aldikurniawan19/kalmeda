import 'dart:async';

import 'package:flutter/material.dart';

import 'package:menstracker/core/services/network_connectivity_service.dart';
import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/core/theme/app_theme.dart';
import 'package:menstracker/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:menstracker/features/network/presentation/screens/no_internet_screen.dart';
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
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Root widget of the Menstracker application with app lifecycle observer for privacy and network enforcement.
class MenstrackerApp extends StatefulWidget {
  const MenstrackerApp({super.key});

  @override
  State<MenstrackerApp> createState() => _MenstrackerAppState();
}

class _MenstrackerAppState extends State<MenstrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure chat session starts clean on app launch
    ChatbotController().clearChat();
    // Start continuous internet connectivity monitoring
    NetworkConnectivityService().startMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NetworkConnectivityService().stopMonitoring();
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

    // Re-verify network reachability immediately upon returning to foreground
    if (state == AppLifecycleState.resumed) {
      NetworkConnectivityService().checkConnection();
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
      builder: (context, child) {
        return NetworkConnectivityGuard(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Global guard widget that blocks all app screens with [NoInternetScreen] whenever the internet connection is lost.
class NetworkConnectivityGuard extends StatefulWidget {
  final Widget child;

  const NetworkConnectivityGuard({
    super.key,
    required this.child,
  });

  @override
  State<NetworkConnectivityGuard> createState() =>
      _NetworkConnectivityGuardState();
}

class _NetworkConnectivityGuardState extends State<NetworkConnectivityGuard> {
  bool _isConnected = true;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _isConnected = NetworkConnectivityService().isConnected;
    _subscription = NetworkConnectivityService()
        .onConnectivityChanged
        .listen((connected) {
      if (mounted && _isConnected != connected) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return NoInternetScreen(
        onConnected: () {
          if (mounted) {
            setState(() {
              _isConnected = true;
            });
          }
        },
      );
    }
    return widget.child;
  }
}

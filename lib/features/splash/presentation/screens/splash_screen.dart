import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/services/network_connectivity_service.dart';
import 'package:menstracker/core/services/notification_service.dart';
import 'package:menstracker/core/utils/app_page_route.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/auth/presentation/screens/login_screen.dart';
import 'package:menstracker/features/home/presentation/screens/home_screen.dart';
import 'package:menstracker/features/network/presentation/screens/no_internet_screen.dart';
import 'package:menstracker/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:menstracker/features/period_setup/presentation/screens/period_setup_screen.dart';

/// Splash screen displaying branding, realistic animated blood droplet with liquid ripples, and loading indicator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  Timer? _navigationTimer;
  Future<void>? _authCheckFuture;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _authCheckFuture = AuthController().checkAuthStatus();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // 1. Prompt official device notification permission gently once splash is visible
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        NotificationService().requestPermissions().catchError((e) {
          debugPrint('Notification permission request error: $e');
          return false;
        });
      }
    });

    // 2. Wait for splash animation minimum display time & auth check
    _navigationTimer = Timer(const Duration(milliseconds: 2400), () {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _navigationTimer?.cancel();

    // 1. Mandatory Internet Connection Verification on Launch
    final hasInternet = await NetworkConnectivityService().checkConnection();
    if (!hasInternet) {
      if (!mounted) return;
      _isNavigating = false;
      Navigator.of(context).pushReplacement(
        AppPageRoute(
          builder: (_) => NoInternetScreen(
            onConnected: () {
              if (mounted) {
                _isNavigating = false;
                _navigateNext();
              }
            },
          ),
        ),
      );
      return;
    }

    // 2. Ensure auth check has resolved
    try {
      if (_authCheckFuture != null) {
        await _authCheckFuture;
      }
    } catch (e) {
      debugPrint('Error awaiting auth check: $e');
    }

    if (!mounted) return;

    final auth = AuthController();
    final Widget targetScreen;

    if (auth.isAuthenticated) {
      final hasCompleted = auth.currentUser?.hasCompletedSetup ?? false;
      targetScreen = hasCompleted ? const HomeScreen() : const PeriodSetupScreen();
    } else {
      bool hasSeenOnboarding = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        hasSeenOnboarding = prefs.getBool('kalmeda_has_seen_onboarding') ?? false;
      } catch (_) {}

      targetScreen = hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => targetScreen,
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: GestureDetector(
        onTap: _navigateNext,
        child: Stack(
          children: [
            // Bottom Cloud & Floral Background
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/Komponen/bgSplashScreen.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Center Logo & Brand Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Realistic Animated Blood Droplet with Concentric Ripples
                      const BloodDropHeroAnimation(),
                      const SizedBox(height: AppSizes.space16),

                      // App Brand Name
                      const Text(
                        'Kalmeda',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.space8),

                      // Tagline
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Flexible(
                            child: Text(
                              'Jaga kesehatanmu,\nkamu hebat!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.space6),
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 16,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(height: AppSizes.space24),

                      // Themed Loading Indicator
                      const _ThemedLoadingIndicator(),
                      const SizedBox(height: 50), // Offset slightly up from bottom
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Blood Droplet Hero Widget with liquid physics, stretch-and-squash impact, and expanding concentric ripples.
class BloodDropHeroAnimation extends StatefulWidget {
  const BloodDropHeroAnimation({super.key});

  @override
  State<BloodDropHeroAnimation> createState() => _BloodDropHeroAnimationState();
}

class _BloodDropHeroAnimationState extends State<BloodDropHeroAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(140, 140),
          painter: _BloodDropPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _BloodDropPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _BloodDropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // --- 1. Concentric Ripple Waves Expanding from Impact Point ---
    // Triggered upon impact starting at progress 0.40
    if (progress >= 0.40) {
      // Wave 1
      final tWave1 = ((progress - 0.40) / 0.55).clamp(0.0, 1.0);
      final radius1 = 14.0 + 52.0 * Curves.easeOutCubic.transform(tWave1);
      final opacity1 = (1.0 - tWave1).clamp(0.0, 1.0) * 0.65;

      final wave1Paint = Paint()
        ..color = const Color(0xFFFF4D79).withValues(alpha: opacity1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1.0 - tWave1 * 0.5);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 20), width: radius1 * 2, height: radius1 * 0.8),
        wave1Paint,
      );

      // Wave 2 (delayed slightly)
      if (progress >= 0.50) {
        final tWave2 = ((progress - 0.50) / 0.48).clamp(0.0, 1.0);
        final radius2 = 10.0 + 40.0 * Curves.easeOutCubic.transform(tWave2);
        final opacity2 = (1.0 - tWave2).clamp(0.0, 1.0) * 0.45;

        final wave2Paint = Paint()
          ..color = const Color(0xFFFF2A6D).withValues(alpha: opacity2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1.0 - tWave2 * 0.5);

        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 20), width: radius2 * 2, height: radius2 * 0.8),
          wave2Paint,
        );
      }
    }

    // --- 2. Blood Droplet Mechanics (Fall, Squash & Rebound) ---
    double dropY;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double dropOpacity = 1.0;

    if (progress < 0.40) {
      // Falling phase
      final tFall = progress / 0.40;
      final curvedFall = Curves.easeInQuad.transform(tFall);
      dropY = (cy - 65) + (65 * curvedFall);

      // Stretch elongation during free fall
      scaleY = 1.0 + 0.35 * curvedFall;
      scaleX = 1.0 - 0.18 * curvedFall;
      dropOpacity = (tFall / 0.15).clamp(0.0, 1.0);
    } else if (progress < 0.58) {
      // Impact & Squash phase
      final tImpact = (progress - 0.40) / 0.18;
      dropY = cy;

      final squash = math.sin(tImpact * math.pi);
      scaleX = 1.0 + 0.38 * squash;
      scaleY = 1.0 - 0.32 * squash;
    } else {
      // Rebound / Resting bounce phase
      final tSettle = (progress - 0.58) / 0.42;
      final bounce = math.sin(tSettle * math.pi * 2) * math.exp(-tSettle * 3.5);
      dropY = cy - 8 * bounce.abs();
      scaleX = 1.0 - 0.10 * bounce;
      scaleY = 1.0 + 0.12 * bounce;

      // Soft fade out at the very end to loop seamlessly
      if (progress > 0.92) {
        dropOpacity = ((1.0 - progress) / 0.08).clamp(0.0, 1.0);
      }
    }

    // Draw Droplet with transformation matrix
    canvas.save();
    canvas.translate(cx, dropY);
    canvas.scale(scaleX, scaleY);

    const double dropW = 56.0;
    const double dropH = 74.0;
    final dropletPath = _createRealisticDropletPath(dropW, dropH);

    // 1. Droplet Ambient Shadow / Soft Crimson Radiance
    final shadowPaint = Paint()
      ..color = const Color(0xFFFF1A53).withValues(alpha: 0.32 * dropOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(dropletPath, shadowPaint);

    // 2. Realistic Liquid Arterial Blood Gradient (Top translucency to deep viscous core)
    final dropletPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF4D79), // Light-catching translucent apex
          Color(0xFFDC0038), // Vibrant mid-body arterial crimson
          Color(0xFF80001D), // Dense, deep deoxygenated blood core at base
        ],
        stops: [0.0, 0.46, 1.0],
      ).createShader(Rect.fromLTWH(-dropW / 2, -dropH / 2, dropW, dropH))
      ..color = Colors.white.withValues(alpha: dropOpacity);
    canvas.drawPath(dropletPath, dropletPaint);

    // 3. Subsurface Scattering / Caustic Inner Glow in lower bulb
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.05, 0.35),
        radius: 0.65,
        colors: [
          const Color(0xFFFF3366).withValues(alpha: 0.55 * dropOpacity),
          const Color(0xFFFF1A53).withValues(alpha: 0.18 * dropOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(-dropW * 0.35, -dropH * 0.05, dropW * 0.70, dropH * 0.45))
      ..blendMode = BlendMode.screen;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, dropH * 0.12),
        width: dropW * 0.65,
        height: dropH * 0.38,
      ),
      innerGlowPaint,
    );

    // 4. Curved Glass Specular Highlight along left organic contour
    final highlightPath = Path();
    highlightPath.moveTo(-dropW * 0.06, -dropH * 0.50 + dropH * 0.15);
    highlightPath.cubicTo(
      -dropW * 0.20, -dropH * 0.50 + dropH * 0.32,
      -dropW * 0.40, dropH * 0.05,
      -dropW * 0.35, dropH * 0.25,
    );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78 * dropOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);

    // 5. Intense Specular Glint Dot
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * dropOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(-dropW * 0.14, -dropH * 0.50 + dropH * 0.22),
      2.4,
      glintPaint,
    );

    // 6. Secondary Fresnel Rim Highlight (Lower-right bounce reflection for 3D sphere volume)
    final rimPath = Path();
    rimPath.moveTo(dropW * 0.18, dropH * 0.50 - dropH * 0.04);
    rimPath.cubicTo(
      dropW * 0.36, dropH * 0.50 - dropH * 0.10,
      dropW * 0.44, dropH * 0.22,
      dropW * 0.42, dropH * 0.10,
    );
    final rimPaint = Paint()
      ..color = const Color(0xFFFF94B0).withValues(alpha: 0.42 * dropOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(rimPath, rimPaint);

    canvas.restore();
  }

  /// Builds a fluid-dynamic, organic teardrop silhouette with natural surface tension curves.
  Path _createRealisticDropletPath(double w, double h) {
    final path = Path();
    final topY = -h * 0.50;
    final bottomY = h * 0.50;

    path.moveTo(0, topY);

    // 1. Apex to right widest point (silky convex-concave transition)
    path.cubicTo(
      w * 0.05, topY + h * 0.20,
      w * 0.48, topY + h * 0.45,
      w * 0.50, h * 0.14,
    );

    // 2. Right widest point around the weighted bottom bulb to bottom center
    path.cubicTo(
      w * 0.50, h * 0.14 + h * 0.18,
      w * 0.32, bottomY,
      0, bottomY,
    );

    // 3. Bottom center around the left bulb to left widest point
    path.cubicTo(
      -w * 0.32, bottomY,
      -w * 0.50, h * 0.14 + h * 0.18,
      -w * 0.50, h * 0.14,
    );

    // 4. Left widest point smoothly back to apex
    path.cubicTo(
      -w * 0.48, topY + h * 0.45,
      -w * 0.05, topY + h * 0.20,
      0, topY,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BloodDropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Themed pulse dot loading indicator with staggered wave motion.
class _ThemedLoadingIndicator extends StatefulWidget {
  const _ThemedLoadingIndicator();

  @override
  State<_ThemedLoadingIndicator> createState() => _ThemedLoadingIndicatorState();
}

class _ThemedLoadingIndicatorState extends State<_ThemedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Calculate wave progress for each dot
            final offset = index * 0.22;
            final progress = (_controller.value + offset) % 1.0;
            // Sine curve for smooth bounce & scale
            final sinVal = (progress * 3.1415926535 * 2);
            final scale = 0.75 + 0.35 * (0.5 + 0.5 * (sinVal < 3.1415926535 ? 1.0 : -1.0) * (sinVal.abs() % 3.1415926535) / 3.1415926535);
            final opacity = (0.35 + 0.65 * (0.5 + 0.5 * ((progress * 2 - 1).abs()))).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: opacity * 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

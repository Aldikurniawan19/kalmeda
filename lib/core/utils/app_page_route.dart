import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';

/// Unified custom page route delivering consistent WhatsApp-style smooth horizontal shared-axis transitions across all screens.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final SharedAxisTransitionType transitionType;

  AppPageRoute({
    required this.builder,
    this.transitionType = SharedAxisTransitionType.horizontal,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              fillColor: AppColors.scaffoldBackground,
              child: child,
            );
          },
        );
}

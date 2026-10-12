import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';

/// Ultra-smooth animated floating assistant button for Kalmeda.
/// Features a fluid cubic bezier transition from an extended pill into a compact circle,
/// with generous text width to ensure "Tanya Kalmeda" is completely visible without clipping.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class AnimatedAssistantFab extends StatefulWidget {
  final bool isExtended;
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const AnimatedAssistantFab({
    super.key,
    required this.isExtended,
    required this.onTap,
    this.label = 'Tanya Kalmeda',
    this.icon = Icons.support_agent_rounded,
  });

  @override
  State<AnimatedAssistantFab> createState() => _AnimatedAssistantFabState();
}

class _AnimatedAssistantFabState extends State<AnimatedAssistantFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // 176dp when extended (pill with full text), 52dp when collapsed (circle)
    final buttonWidth = widget.isExtended ? 176.0 : 52.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          width: buttonWidth,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(26),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              splashColor: Colors.white.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Persistent Assistant Icon
                    Icon(widget.icon, size: 22, color: AppColors.textWhite),

                    // Collapsing Label Container with ample width for full visibility
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeInOutCubic,
                      width: widget.isExtended ? 116 : 0,
                      child: AnimatedOpacity(
                        duration: Duration(
                          milliseconds: widget.isExtended ? 450 : 250,
                        ),
                        curve: Curves.easeInOut,
                        opacity: widget.isExtended ? 1.0 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';

/// 100% Authentic WhatsApp-style chat input bar for Kalmeda.
///
/// Matches exact WhatsApp screenshot design adapted to Kalmeda theme colors:
/// 1. Layout: Left pill container (transforms into sleek dark recording capsule) + Right circular mic button.
/// 2. Push-to-Talk: Tap and hold right circular microphone button to record.
/// 3. Exact WhatsApp Mic Button:
///    - Enlarges to huge circular button (~88px) popping out above the bar with `Curves.easeOutBack`.
///    - Kalmeda primary brand color (`AppColors.primary` `#FF4D79`).
///    - Large bold microphone icon (`Icons.mic_rounded`, ~36px).
///    - Smooth color shift to Crimson Red (`#EF4444`) when dragging left past cancel threshold.
/// 4. Exact WhatsApp Recording Pill Track:
///    - Sleek dark capsule background (`#1E293B`).
///    - Monospace timer (`0.01`, `0.02`, `0.04`...) on the left.
///    - `< Geser untuk membatalkan` that slides left with finger drag.
/// 5. Release to Send: Immediately sends voice note upon pointer release.
/// 6. Tap Hint: Short tap prompts user to hold for voice recording.
///
/// Strictly adheres to `aturan-desain.md` and `aturan-penulisan-code.md`.
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onVoiceRecordStart;
  final ValueChanged<double>? onVoiceRecordDrag;
  final ValueChanged<bool>? onVoiceRecordEnd;
  final VoidCallback? onVoiceNoteTapHint;
  final bool isGenerating;
  final bool isRecordingVoice;
  final bool isCancelThresholdMet;
  final String hintText;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onVoiceRecordStart,
    this.onVoiceRecordDrag,
    this.onVoiceRecordEnd,
    this.onVoiceNoteTapHint,
    this.isGenerating = false,
    this.isRecordingVoice = false,
    this.isCancelThresholdMet = false,
    this.hintText = 'Tanyakan keluhan atau topik kesehatan...',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with TickerProviderStateMixin {
  bool _hasFocus = false;
  bool _hasText = false;
  Offset? _pointerStartPosition;
  double _currentDeltaX = 0.0;
  DateTime? _pointerDownTime;

  Timer? _recordStopwatch;
  int _recordSeconds = 0;

  late final AnimationController _shimmerController;
  late final AnimationController _micScaleController;
  late final Animation<double> _micScaleAnimation;

  @override
  void initState() {
    super.initState();
    _hasFocus = widget.focusNode.hasFocus;
    _hasText = widget.controller.text.trim().isNotEmpty;

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _micScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _micScaleAnimation = CurvedAnimation(
      parent: _micScaleController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.isRecordingVoice) {
      _micScaleController.value = 1.0;
    }

    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
      _hasFocus = widget.focusNode.hasFocus;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _hasText = widget.controller.text.trim().isNotEmpty;
    }

    if (!oldWidget.isRecordingVoice && widget.isRecordingVoice) {
      _micScaleController.forward();
      _startStopwatch();
    } else if (oldWidget.isRecordingVoice && !widget.isRecordingVoice) {
      _micScaleController.reverse();
      _stopStopwatch();
    }
  }

  void _startStopwatch() {
    _recordSeconds = 0;
    _recordStopwatch?.cancel();
    _recordStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordSeconds++;
        });
      }
    });
  }

  void _stopStopwatch() {
    _recordStopwatch?.cancel();
    _recordSeconds = 0;
  }

  @override
  void dispose() {
    _recordStopwatch?.cancel();
    _shimmerController.dispose();
    _micScaleController.dispose();
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _hasFocus != widget.focusNode.hasFocus) {
      setState(() {
        _hasFocus = widget.focusNode.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (mounted && _hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerStartPosition = event.position;
    _currentDeltaX = 0.0;
    _pointerDownTime = DateTime.now();
    _micScaleController.forward();
    widget.onVoiceRecordStart?.call();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pointerStartPosition == null) return;
    _currentDeltaX = event.position.dx - _pointerStartPosition!.dx;
    widget.onVoiceRecordDrag?.call(_currentDeltaX);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pointerStartPosition == null) return;
    final duration = DateTime.now().difference(_pointerDownTime ?? DateTime.now());
    final isCancelled = _currentDeltaX < -65;

    _pointerStartPosition = null;
    _currentDeltaX = 0.0;

    if (duration.inMilliseconds < 280 && !isCancelled) {
      // Short tap instead of hold
      _micScaleController.reverse();
      widget.onVoiceRecordEnd?.call(true);
      widget.onVoiceNoteTapHint?.call();
    } else {
      // Released after holding
      _micScaleController.reverse();
      widget.onVoiceRecordEnd?.call(isCancelled);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerStartPosition = null;
    _currentDeltaX = 0.0;
    _micScaleController.reverse();
    widget.onVoiceRecordEnd?.call(true);
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes.$seconds'; // WhatsApp dot format 0.02
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.isGenerating;
    final isRecording = widget.isRecordingVoice;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exact WhatsApp Two-Component Bottom Bar Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 1. Left Pill Container (Clean White matching Kalmeda Theme, dynamically expands)
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 42),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isRecording
                            ? _buildWhatsAppRecordingTrack()
                            : _buildWhatsAppInputField(canSend),
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // 2. Right Separate Circular Action / Mic Button
                  _buildWhatsAppRightActionButton(canSend, isRecording),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Right WhatsApp Circular Floating Button (Normal Send OR Push-to-Talk Mic)
  Widget _buildWhatsAppRightActionButton(bool canSend, bool isRecording) {
    if (widget.isGenerating) {
      return Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (canSend) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onSend,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // Exact WhatsApp Voice Recording Microphone Button adapted to Kalmeda colors
    final isCancelling = widget.isCancelThresholdMet;
    final dragDx = (_currentDeltaX * 0.28).clamp(-40.0, 0.0);

    final activeColor = isCancelling
        ? const Color(0xFFEF4444)
        : AppColors.primary;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _micScaleAnimation,
              builder: (context, _) {
                final scaleVal = _micScaleAnimation.value;
                // Expands smoothly and pops slightly upward like WhatsApp
                final buttonScale = isRecording ? (1.0 + 0.65 * scaleVal) : 1.0;
                final iconSize = isRecording ? (22.0 + 8.0 * scaleVal) : 22.0;
                final verticalPop = isRecording ? (-6.0 * scaleVal) : 0.0;

                return Transform.translate(
                  offset: Offset(dragDx, verticalPop),
                  child: Transform.scale(
                    scale: buttonScale,
                    alignment: Alignment.center,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: isRecording ? 0.45 : 0.25),
                            blurRadius: isRecording ? 14 : 5,
                            spreadRadius: isRecording ? 2 : 0,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mic_rounded,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Clean Text Input Field inside the White Pill (Without emoji, clip, or photo icons, dynamically expanding)
  Widget _buildWhatsAppInputField(bool canSend) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        minLines: 1,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF111B21),
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontSize: 14.0,
            color: Color(0xFF8696A0),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onSubmitted: (_) {
          if (canSend) {
            widget.onSend();
          }
        },
      ),
    );
  }

  /// 100% Authentic WhatsApp Recording Track matching reference screenshot in Kalmeda white theme
  Widget _buildWhatsAppRecordingTrack() {
    final isCancelling = widget.isCancelThresholdMet;
    final slideOffset = (_currentDeltaX * 0.70).clamp(-140.0, 0.0);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerVal = _shimmerController.value;
        final chevronAlpha = (0.35 + 0.65 * math.sin(shimmerVal * math.pi)).clamp(0.2, 1.0);

        return Padding(
          padding: const EdgeInsets.only(left: 18, right: 12),
          child: Row(
            key: const ValueKey<String>('whatsapp_recording_track'),
            children: [
              // 1. Monospace Recording Timer (0.02 / 0.04)
              Text(
                _formatTimer(_recordSeconds),
                style: TextStyle(
                  fontSize: 16.5,
                  color: isCancelling ? const Color(0xFFEF4444) : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(width: 8),

              // 2. Shimmering "< Slide to cancel" / "< Geser untuk membatalkan" Slider
              Expanded(
                child: ClipRect(
                  child: Transform.translate(
                    offset: Offset(slideOffset, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: isCancelling
                              ? const Color(0xFFEF4444)
                              : AppColors.textMuted.withValues(alpha: chevronAlpha),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            isCancelling
                                ? 'Lepas untuk membatalkan'
                                : 'Geser untuk membatalkan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isCancelling
                                  ? const Color(0xFFEF4444)
                                  : AppColors.textSecondary,
                              fontWeight: isCancelling
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Clean animated typing indicator simulating clinical assistant thought and formulation.
/// Dynamically updates contextual status messages when deep clinical analysis requires additional time.
/// Adheres strictly to `aturan-desain.md` (no emojis, consistent typography, and tokens).
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _elapsedTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _getStatusText() {
    if (_secondsElapsed < 4) {
      return 'Konsultan sedang mengetik...';
    } else if (_secondsElapsed < 12) {
      return 'Menelaah panduan klinis Sp.OG...';
    } else if (_secondsElapsed < 25) {
      return 'Menganalisis keluhan, mohon tunggu sebentar...';
    } else {
      return 'Sedang menyusun rekomendasi medis terlengkap...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText();

    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSizes.space12,
        left: AppSizes.space16,
        right: AppSizes.space16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space14,
        vertical: AppSizes.space10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ChatMascot(size: 28, mood: ChatMascotMood.thinking),
          const SizedBox(width: AppSizes.space8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay) % 1.0;
                  final scale = (value < 0.5) ? (0.5 + value) : (1.5 - value);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: scale.clamp(0.3, 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: AppSizes.space10),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                statusText,
                key: ValueKey<String>(statusText),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

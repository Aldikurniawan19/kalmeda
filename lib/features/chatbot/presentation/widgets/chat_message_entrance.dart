import 'dart:async';

import 'package:flutter/material.dart';

/// Springy pop-in for a freshly added chat bubble: it grows from its
/// sender's corner while sliding up and fading in. Plays only once.
class ChatMessageEntrance extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 460);

  final Widget child;
  final bool animate;
  final bool fromRight;

  const ChatMessageEntrance({
    super.key,
    required this.child,
    required this.animate,
    this.fromRight = false,
  });

  @override
  State<ChatMessageEntrance> createState() => _ChatMessageEntranceState();
}

class _ChatMessageEntranceState extends State<ChatMessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ChatMessageEntrance.duration,
      value: widget.animate ? 0 : 1,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
      begin: Offset(widget.fromRight ? 0.06 : -0.06, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment: widget.fromRight
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Staggered pop for items inside a new bubble (e.g. suggestion chips),
/// so they appear one after another instead of all at once.
class StaggeredPopIn extends StatefulWidget {
  static const Duration baseDelay = Duration(milliseconds: 260);
  static const Duration stepDelay = Duration(milliseconds: 70);
  static const Duration duration = Duration(milliseconds: 360);

  final Widget child;
  final int index;
  final bool animate;

  const StaggeredPopIn({
    super.key,
    required this.child,
    required this.index,
    required this.animate,
  });

  @override
  State<StaggeredPopIn> createState() => _StaggeredPopInState();
}

class _StaggeredPopInState extends State<StaggeredPopIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: StaggeredPopIn.duration,
      value: widget.animate ? 0 : 1,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    if (widget.animate) {
      final delay =
          StaggeredPopIn.baseDelay + StaggeredPopIn.stepDelay * widget.index;
      _delayTimer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.centerLeft,
        child: widget.child,
      ),
    );
  }
}

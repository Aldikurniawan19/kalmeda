import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:menstracker/features/chatbot/presentation/widgets/chat_mascot.dart';

/// Derives the consultant mascot mood from chat UI signals
/// (initial screen opening, input focus, typed text, AI generation, working analysis, and completed answers).
///
/// Priority: greeting > celebrating/finished > working > thinking > question > listening > idle.
class ChatMascotController extends ChangeNotifier {
  static const Duration greetingDuration = Duration(milliseconds: 2400);
  static const Duration celebrationDuration = Duration(milliseconds: 1400);
  static const Duration angryDuration = Duration(milliseconds: 3600);

  /// Approximate characters per input line, used to map caret position to gaze.
  static const int _charsPerLine = 34;

  ChatMascotMood _mood = ChatMascotMood.greeting;
  double _gazeX = 0;
  bool _isGenerating = false;
  bool _isWorking = false;
  bool _isQuestion = false;
  bool _hasFocus = false;
  int _textLength = 0;
  bool _isCelebrating = false;
  bool _isGreeting = false;
  bool _isAnticipating = false;
  bool _isAngry = false;
  int _consecutiveTaps = 0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _celebrationTimer;
  Timer? _greetingTimer;
  Timer? _angryTimer;

  ChatMascotMood get mood => _mood;
  double get gazeX => _gazeX;
  bool get isAnticipating => _isAnticipating;
  bool get isAngry => _isAngry;

  String get statusLabel {
    if (_isAngry) {
      return 'Sedang kesal • Jangan dicolek terus ya!';
    }
    if (_isAnticipating) {
      return 'Ingin bertanya sesuatu? • Menghampiri...';
    }
    switch (_mood) {
      case ChatMascotMood.angry:
        return 'Sedang kesal • Jangan dicolek terus ya!';
      case ChatMascotMood.greeting:
        return 'Halo! Senang bertemu Anda';
      case ChatMascotMood.listening:
        return 'Mendengarkan keluhan Anda...';
      case ChatMascotMood.thinking:
        return 'Sedang menelaah panduan klinis...';
      case ChatMascotMood.working:
        return 'Sedang menyusun sintesis medis...';
      case ChatMascotMood.finished:
      case ChatMascotMood.dance:
      case ChatMascotMood.happy:
        return 'Jawaban siap • Analisis selesai';
      case ChatMascotMood.question:
        return 'Ada pertanyaan lain seputar haid?';
      case ChatMascotMood.dizzy:
        return 'Sedang memulihkan diri...';
      case ChatMascotMood.idle:
        return 'Online • Terverifikasi Sp.OG & Kemenkes';
    }
  }

  /// Registers consecutive taps. If tapped > 3 times within 1.4 seconds, triggers angry mood.
  void registerTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 1400) {
      _consecutiveTaps++;
    } else {
      _consecutiveTaps = 1;
    }
    _lastTapTime = now;

    if (_consecutiveTaps > 3) {
      triggerAngry();
    }
  }

  /// Triggers the angry expression for the given duration before returning to normal mood.
  void triggerAngry([Duration duration = angryDuration]) {
    _angryTimer?.cancel();
    _isAngry = true;
    _resolve();
    _angryTimer = Timer(duration, () {
      _isAngry = false;
      _consecutiveTaps = 0;
      _resolve();
    });
  }

  /// Plays the Coucou-inspired drop-in bounce & hand wave greeting animation on launch.
  void greet() {
    _greetingTimer?.cancel();
    _isGreeting = true;
    _resolve();
    _greetingTimer = Timer(greetingDuration, () {
      _isGreeting = false;
      _resolve();
    });
  }

  /// Plays a triumphant celebration jump when a new answer is delivered.
  void celebrateAnswer() => _celebrate(celebrationDuration);

  void setAnticipating(bool isAnticipating) {
    if (_isAnticipating == isAnticipating) return;
    _isAnticipating = isAnticipating;
    _resolve();
  }

  void updateInput({required bool hasFocus, required String text}) {
    _hasFocus = hasFocus;
    _textLength = text.trim().isEmpty ? 0 : text.length;
    _isQuestion = text.trim().endsWith('?');
    _resolve();
  }

  void setGenerating(bool isGenerating) {
    if (_isGenerating == isGenerating) return;
    _isGenerating = isGenerating;
    _resolve();
  }

  void setWorking(bool isWorking) {
    if (_isWorking == isWorking) return;
    _isWorking = isWorking;
    _resolve();
  }

  void setMood(ChatMascotMood mood) {
    if (_mood == mood) return;
    _mood = mood;
    notifyListeners();
  }

  void _celebrate(Duration duration) {
    _celebrationTimer?.cancel();
    _isCelebrating = true;
    _resolve();
    _celebrationTimer = Timer(duration, () {
      _isCelebrating = false;
      _resolve();
    });
  }

  void _resolve() {
    final nextMood = _isAngry
        ? ChatMascotMood.angry
        : _isGreeting
        ? ChatMascotMood.greeting
        : _isAnticipating
        ? ChatMascotMood.question
        : _isCelebrating
        ? ChatMascotMood.finished
        : _isWorking
        ? ChatMascotMood.working
        : _isGenerating
        ? ChatMascotMood.thinking
        : _isQuestion
        ? ChatMascotMood.question
        : _hasFocus
        ? ChatMascotMood.listening
        : ChatMascotMood.idle;

    // Eyes travel left to right with the caret, then wrap on a new line.
    final caretProgress = _textLength == 0
        ? 0.0
        : (_textLength % _charsPerLine) / _charsPerLine;
    final nextGaze = _isAngry
        ? 0.0
        : _isAnticipating
        ? 0.75
        : _textLength == 0
        ? -0.2
        : -0.8 + 1.6 * caretProgress;

    if (nextMood == _mood && nextGaze == _gazeX) return;
    _mood = nextMood;
    _gazeX = nextGaze;
    notifyListeners();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _celebrationTimer?.cancel();
    _angryTimer?.cancel();
    super.dispose();
  }
}

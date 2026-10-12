import 'package:flutter/material.dart';

/// Central color token system for the application.
/// Strictly follows `aturan-penulisan-code.md` and `aturan-desain.md`.
abstract class AppColors {
  // Base backgrounds
  static const Color scaffoldBackground = Color(0xFFFAF7F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFF1EDF2);

  // Primary & Accents
  static const Color primary = Color(0xFFFF4D79);
  static const Color primaryLight = Color(0xFFFF85A6);
  static const Color primarySoft = Color(0xFFFFE6ED);
  static const Color primaryCardStart = Color(0xFFFFF2F6);
  static const Color primaryCardEnd = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E24);
  static const Color textSecondary = Color(0xFF757588);
  static const Color textMuted = Color(0xFFA0A0B2);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPink = Color(0xFFFF4D79);

  // Quick Menu Backgrounds
  static const Color menuKalenderBg = Color(0xFFFFF0F4);
  static const Color menuRiwayatBg = Color(0xFFF2F0FF);
  static const Color menuMoodBg = Color(0xFFFFF0F5);
  static const Color menuPengingatBg = Color(0xFFFFF0F3);
  static const Color menuLainnyaBg = Color(0xFFFFF0F5);

  // Calendar Tokens
  static const Color periodSolid = Color(0xFFFF4D79);
  static const Color periodPrediction = Color(0xFFFFDEE7);
  static const Color periodPredictionText = Color(0xFFFF4D79);
  static const Color fertileWindow = Color(0xFFA855F7);
  static const Color fertileWindowBg = Color(0xFFF5EEFD);
  static const Color fertileWindowBorder = Color(0xFFD8B4FE);
  static const Color fertileWindowText = Color(0xFF6D28D9);
  static const Color fertileNumberText = Color(0xFFE53935);
  static const Color ovulationSolid = Color(0xFF7C3AED);
  static const Color ovulationSoft = Color(0xFFEDE9FE);
  static const Color calendarHeader = Color(0xFF8E8EA0);
  static const Color calendarInactive = Color(0xFFC7C7D4);

  // Mood Card Backgrounds
  static const Color moodBahagiaBg = Color(0xFFFEF6DB);
  static const Color moodTenangBg = Color(0xFFDFF6F3);
  static const Color moodSedihBg = Color(0xFFE2F1FE);
  static const Color moodLelahBg = Color(0xFFEFE6FD);
  static const Color moodNyeriBg = Color(0xFFFEE4ED);
  static const Color moodKembungBg = Color(0xFFFEEEDA);

  // Navigation & Icons
  static const Color navActive = Color(0xFFFF4D79);
  static const Color navInactive = Color(0xFFA5A5B8);
  static const Color iconButtonBg = Color(0xFFFFFFFF);
  static const Color notificationDot = Color(0xFFFF4D79);

  // Forms & Inputs & Alerts
  static const Color inputBackground = Color(0xFFF9F6F8);
  static const Color inputBorder = Color(0xFFEEE8EE);
  static const Color inputBorderFocused = Color(0xFFFF4D79);
  static const Color success = Color(0xFF2563EB);
  static const Color error = Color(0xFFE53935);
  static const Color divider = Color(0xFFEEEAF0);
  static const Color socialButtonBorder = Color(0xFFE8E2EC);
  static const Color socialButtonBg = Color(0xFFFFFFFF);

  // Chat & Consultation Tokens (Kalmeda Theme)
  static const Color chatScaffoldBackground = Color(0xFFFAF7F9);
  static const Color chatAppBarBackground = Color(0xFFFFFFFF);
  static const Color chatUserBubble = Color(0xFFFFEEF3);
  static const Color chatUserBubbleBorder = Color(0xFFFFD6E2);
  static const Color chatBotBubble = Color(0xFFFFFFFF);
  static const Color chatBotBubbleBorder = Color(0xFFF1EDF2);
  static const Color chatNoticeBackground = Color(0xFFFFF0F5);
  static const Color chatNoticeBorder = Color(0xFFFFD5E2);
  static const Color chatNoticeTitle = Color(0xFFC02652);
  static const Color chatNoticeText = Color(0xFF7A2941);
  static const Color chatExpertCardBg = Color(0xFFFFF6F8);
  static const Color chatExpertCardBorder = Color(0xFFFFE0E8);
  static const Color chatExpertCardTitle = Color(0xFFC02652);
  static const Color chatExpertCardText = Color(0xFF6B2136);
  static const Color chatOnlineIndicator = Color(0xFF10B981);
  static const Color chatChipBackground = Color(0xFFF9F6F8);
  static const Color chatChipBorder = Color(0xFFEEE8EE);

  // Chat Mascot Tokens (animated consultant character)
  static const Color chatMascotBody = Color(0xFFFF4D79);
  static const Color chatMascotBodyHighlight = Color(0xFFFF85A6);
  static const Color chatMascotEye = Color(0xFFFFFFFF);
  static const Color chatMascotPupil = Color(0xFF1E1E24);
  static const Color chatMascotCheek = Color(0xFFFFB8CA);
  static const Color chatMascotShadow = Color(0x1F1E1E24);
}

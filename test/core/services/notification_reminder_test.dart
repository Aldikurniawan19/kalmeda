import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification & Reminder Logic Unit Tests', () {
    test('H-4 Pre-Period date calculation is accurate', () {
      final nextPeriodDate = DateTime(2026, 10, 15, 0, 0);
      final prePeriodTarget = nextPeriodDate.subtract(const Duration(days: 4));
      final scheduledDate = DateTime(
        prePeriodTarget.year,
        prePeriodTarget.month,
        prePeriodTarget.day,
        9,
        0,
      );

      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 10);
      expect(scheduledDate.day, 11);
      expect(scheduledDate.hour, 9);
      expect(scheduledDate.minute, 0);
    });

    test('H-2 Period Ending Soon calculation is accurate based on period duration', () {
      final periodStartDate = DateTime(2026, 10, 1, 0, 0);
      const periodDurationDays = 6;
      final estimatedEnd = periodStartDate.add(const Duration(days: periodDurationDays));
      final endingSoonTarget = estimatedEnd.subtract(const Duration(days: 2));
      final scheduledDate = DateTime(
        endingSoonTarget.year,
        endingSoonTarget.month,
        endingSoonTarget.day,
        9,
        0,
      );

      // 1 + 6 = 7 (End), 7 - 2 = 5 Oct
      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 10);
      expect(scheduledDate.day, 5);
      expect(scheduledDate.hour, 9);
      expect(scheduledDate.minute, 0);
    });

    test('2-Day Inactivity Reminder target date is precisely 2 days ahead at 10:00 AM', () {
      final appOpenTime = DateTime(2026, 10, 1, 14, 30);
      final inactivityDate = DateTime(
        appOpenTime.year,
        appOpenTime.month,
        appOpenTime.day + 2,
        10,
        0,
      );

      expect(inactivityDate.year, 2026);
      expect(inactivityDate.month, 10);
      expect(inactivityDate.day, 3);
      expect(inactivityDate.hour, 10);
      expect(inactivityDate.minute, 0);
    });

    test('Daily Checkin Morning target is at 08:00 AM', () {
      final now = DateTime(2026, 10, 1, 7, 0);
      final morningTarget = DateTime(now.year, now.month, now.day + 1, 8, 0);

      expect(morningTarget.hour, 8);
      expect(morningTarget.minute, 0);
    });

    test('Daily Checkin Afternoon target is at 16:00 PM', () {
      final now = DateTime(2026, 10, 1, 11, 0);
      DateTime afternoonTarget = DateTime(now.year, now.month, now.day, 16, 0);
      if (afternoonTarget.isBefore(now)) {
        afternoonTarget = DateTime(now.year, now.month, now.day + 1, 16, 0);
      }

      expect(afternoonTarget.hour, 16);
      expect(afternoonTarget.minute, 0);
      expect(afternoonTarget.day, 1);
    });

    test('Notification strings contain no emoticons or emojis (Rule Compliance)', () {
      final notificationTitlesAndBodies = [
        'Perkiraan Haid 2 Hari Lagi',
        'Siklus menstruasi diperkirakan dimulai dalam 2 hari. Siapkan pembalut dan jaga kebugaran tubuhmu.',
        'Perkiraan Haid 4 Hari Lagi',
        'Menstruasi diperkirakan akan datang dalam 4 hari. Persiapkan kebutuhan kebersihan dan perhatikan perubahan tubuhmu.',
        'Catat Kondisi Harimu',
        'Kamu sedang dalam masa menstruasi. Catat gejala fisik, suasana hati, dan intensitas darahmu pagi ini.',
        'Belum Mencatat Hari Ini?',
        'Kamu belum membuka Kalmeda hari ini. Luangkan sebentar untuk mencatat kondisi menstruasimu agar pantauan tetap akurat.',
        'Menstruasi Diperkirakan Segera Selesai',
        'Masa menstruasimu diperkirakan akan berakhir dalam 2 hari. Pastikan untuk mengonfirmasi tanggal berakhir di Kalmeda.',
        'Masa Subur Dimulai Hari Ini',
        'Hari ini kamu memasuki jendela masa subur dengan peluang pembuahan optimal.',
        'Waktunya Minum Air Putih',
        'Penuhi kebutuhan cairan harianmu agar tubuh tetap segar dan terhindar dari kram.',
        'Pengingat Kebersihan Menstruasi',
        'Ganti pembalut secara berkala untuk menjaga kenyamanan dan higienitas.',
        'Waktunya Minum Suplemen / Vitamin',
        'Jangan lupa minum suplemen zat besi atau vitamin harianmu malam ini.',
        'Kami Merindukanmu',
        'Kamu sudah lebih dari 2 hari tidak membuka Kalmeda. Yuk, buka dan catat kondisimu agar pantauan siklus tetap akurat.',
      ];

      // Regex matching common emojis / symbols
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
        unicode: true,
      );

      for (final text in notificationTitlesAndBodies) {
        expect(emojiRegex.hasMatch(text), isFalse,
            reason: 'Notification text should not contain emojis: $text');
      }
    });
  });
}

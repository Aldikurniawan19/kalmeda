import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/core/services/cycle_engine_service.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';

void main() {
  group('CycleEngineService - Period Start Confirmation Logic', () {
    late CycleEngineService engine;

    setUp(() {
      engine = CycleEngineService();
    });

    final baseProfile = CycleProfileModel(
      trackingGoal: 'predict_period',
      lastPeriodDate: DateTime(2026, 10, 1),
      cycleLength: 28,
      periodDuration: 5,
      regularity: 'regular',
      birthDate: DateTime(2000, 1, 1),
    );

    // Predicted next period date: 2026-10-01 + 28 days = 2026-10-29

    test('During active bleeding (Days 1 to 5), confirmation card should NOT appear', () {
      final overviewDay1 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 1),
      );
      expect(overviewDay1.currentCycleDay, 1);
      expect(overviewDay1.isPeriodActive, isTrue);
      expect(overviewDay1.isPeriodStartConfirmationDue, isFalse);

      final overviewDay5 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 5),
      );
      expect(overviewDay5.currentCycleDay, 5);
      expect(overviewDay5.isPeriodActive, isTrue);
      expect(overviewDay5.isPeriodStartConfirmationDue, isFalse);
    });

    test('During mid cycle (H-14, H-5, H-3), confirmation card should NOT appear', () {
      // Day 15 (Mid cycle)
      final overviewMid = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 15),
      );
      expect(overviewMid.currentCycleDay, 15);
      expect(overviewMid.daysUntilNextPeriod, 14);
      expect(overviewMid.isPeriodStartConfirmationDue, isFalse);

      // 2026-10-26 is H-3 (3 days until next period: 29 - 26 = 3)
      final overviewH3 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 26),
      );
      expect(overviewH3.currentCycleDay, 26);
      expect(overviewH3.daysUntilNextPeriod, 3);
      expect(overviewH3.isPeriodStartConfirmationDue, isFalse);
    });

    test('At H-2 (2 days before predicted date), confirmation card MUST appear', () {
      // 2026-10-27 is H-2 (daysUntilNextPeriod = 2)
      final overviewH2 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 27),
      );
      expect(overviewH2.currentCycleDay, 27);
      expect(overviewH2.daysUntilNextPeriod, 2);
      expect(overviewH2.isPeriodStartConfirmationDue, isTrue);
      expect(overviewH2.countdownTitle, '2 hari lagi');
    });

    test('At H-1 (1 day before predicted date), confirmation card MUST appear', () {
      // 2026-10-28 is H-1 (daysUntilNextPeriod = 1)
      final overviewH1 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 28),
      );
      expect(overviewH1.currentCycleDay, 28);
      expect(overviewH1.daysUntilNextPeriod, 1);
      expect(overviewH1.isPeriodStartConfirmationDue, isTrue);
      expect(overviewH1.countdownTitle, '1 hari lagi');
    });

    test('At predicted date (Hari H, 0 days until next period), confirmation card MUST appear', () {
      // 2026-10-29 is Hari H (daysUntilNextPeriod = 0)
      final overviewH0 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 29),
      );
      expect(overviewH0.currentCycleDay, 29);
      expect(overviewH0.daysUntilNextPeriod, 0);
      expect(overviewH0.isPeriodStartConfirmationDue, isTrue);
      expect(overviewH0.countdownTitle, 'Hari ini');
    });

    test('When late / overdue (Telat 1 hari, 5 hari), confirmation card MUST still appear', () {
      // 2026-10-30 is 1 day overdue (daysUntilNextPeriod = -1)
      final overviewLate1 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 10, 30),
      );
      expect(overviewLate1.currentCycleDay, 30);
      expect(overviewLate1.daysUntilNextPeriod, -1);
      expect(overviewLate1.isPeriodStartConfirmationDue, isTrue);
      expect(overviewLate1.countdownTitle, 'Terlambat 1 hari');

      // 2026-11-03 is 5 days overdue (daysUntilNextPeriod = -5)
      final overviewLate5 = engine.calculateOverview(
        profile: baseProfile,
        referenceDate: DateTime(2026, 11, 3),
      );
      expect(overviewLate5.currentCycleDay, 34);
      expect(overviewLate5.daysUntilNextPeriod, -5);
      expect(overviewLate5.isPeriodStartConfirmationDue, isTrue);
      expect(overviewLate5.countdownTitle, 'Terlambat 5 hari');
    });

    test('When user confirms "Sudah" on early or late date, new cycle resets accurately', () {
      // Early start: user started on 2026-10-28 (H-1) and tapped "Sudah"
      final earlyProfile = baseProfile.copyWith(
        lastPeriodDate: DateTime(2026, 10, 28),
        clearLastPeriodEndDate: true,
      );
      final earlyOverview = engine.calculateOverview(
        profile: earlyProfile,
        referenceDate: DateTime(2026, 10, 28),
      );
      expect(earlyOverview.currentCycleDay, 1);
      expect(earlyOverview.isPeriodActive, isTrue);
      expect(earlyOverview.isPeriodStartConfirmationDue, isFalse);
      expect(earlyOverview.nextPeriodDate, DateTime(2026, 11, 25));

      // Late start: user started on 2026-11-02 (4 days late) and tapped "Sudah"
      final lateProfile = baseProfile.copyWith(
        lastPeriodDate: DateTime(2026, 11, 2),
        clearLastPeriodEndDate: true,
      );
      final lateOverview = engine.calculateOverview(
        profile: lateProfile,
        referenceDate: DateTime(2026, 11, 2),
      );
      expect(lateOverview.currentCycleDay, 1);
      expect(lateOverview.isPeriodActive, isTrue);
      expect(lateOverview.isPeriodStartConfirmationDue, isFalse);
      expect(lateOverview.nextPeriodDate, DateTime(2026, 11, 30));
    });
  });
}

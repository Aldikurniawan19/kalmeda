import 'package:flutter_test/flutter_test.dart';

import 'package:menstracker/main.dart';

void main() {
  testWidgets('Menstracker full smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MenstrackerApp());

    // Verify Splash screen elements
    expect(find.text('Dinda'), findsOneWidget);

    // Wait for Splash screen timer to navigate to Onboarding
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify Onboarding Page 1
    expect(find.text('Kenali Siklusmu'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    // Skip to Final Onboarding Step
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    // Verify Final Onboarding Step
    expect(find.text('Siap Jaga Dirimu?'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);

    // Click "Mulai Sekarang" to go to HomeScreen
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();

    // Verify key titles on Home screen
    expect(find.text('Halo, Dinda'), findsOneWidget);
    expect(find.text('Siklus Saat Ini'), findsOneWidget);
    expect(find.text('5 hari lagi'), findsOneWidget);

    // Tap Kalender tab on navigation bar
    await tester.tap(find.text('Kalender').last);
    await tester.pumpAndSettle();
    expect(find.text('Agenda Hari Ini'), findsOneWidget);

    // Tap Catat tab on navigation bar
    await tester.tap(find.text('Catat').last);
    await tester.pumpAndSettle();
    expect(find.text('Aliran Menstruasi'), findsOneWidget);

    // Tap Insight tab on navigation bar
    await tester.tap(find.text('Insight').last);
    await tester.pumpAndSettle();
    expect(find.text('Yuk, pahami tubuhmu lebih baik'), findsOneWidget);

    // Tap Profil tab on navigation bar
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Dinda Aulia'), findsOneWidget);
  });
}

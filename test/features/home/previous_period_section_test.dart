import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/home/presentation/widgets/previous_period_section.dart';

void main() {
  group('PreviousPeriodSection Widget Tests', () {
    testWidgets('Renders previous period section cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreviousPeriodSection(),
            ),
          ),
        ),
      );

      // Section title
      expect(find.text('Riwayat Haid Sebelumnya'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);
    });
  });
}

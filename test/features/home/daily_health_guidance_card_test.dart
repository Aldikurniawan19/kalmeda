import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/home/presentation/widgets/daily_health_guidance_card.dart';

void main() {
  group('DailyHealthGuidanceCard Widget Tests', () {
    testWidgets('Renders daily health guidance card cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyHealthGuidanceCard(),
            ),
          ),
        ),
      );

      // Section title
      expect(find.text('Rekomendasi Hari Ini'), findsOneWidget);
    });
  });
}

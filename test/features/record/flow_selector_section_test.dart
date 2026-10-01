import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/record/presentation/widgets/flow_selector_section.dart';

void main() {
  group('FlowSelectorSection Period Configuration Tests', () {
    testWidgets(
      'When isPeriod is false, only "Tidak Ada / Bersih" option appears and other flow options are omitted',
      (WidgetTester tester) async {
        int? selectedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlowSelectorSection(
                isPeriod: false,
                selectedFlowIndex: 0,
                onFlowSelected: (idx) => selectedIndex = idx,
              ),
            ),
          ),
        );

        // Header and standard subtitle should appear
        expect(find.text('Aliran Menstruasi'), findsOneWidget);
        expect(find.text('Pilih intensitas aliran darah hari ini'), findsOneWidget);

        // Non-period guidance notes must not appear
        expect(find.text('Saat tidak sedang masa haid, darah haid otomatis bersih'), findsNothing);
        expect(find.text('Di luar masa haid, pilihan intensitas darah haid dinonaktifkan.'), findsNothing);

        // "Tidak Ada" and "Bersih" MUST be present
        expect(find.text('Tidak Ada'), findsOneWidget);
        expect(find.text('Bersih'), findsOneWidget);

        // Options other than "Tidak Ada" MUST NOT appear
        expect(find.text('Flek'), findsNothing);
        expect(find.text('Bercak ringan'), findsNothing);
        expect(find.text('Ringan'), findsNothing);
        expect(find.text('Aliran sedikit'), findsNothing);
        expect(find.text('Sedang'), findsNothing);
        expect(find.text('Aliran normal'), findsNothing);
        expect(find.text('Deras'), findsNothing);
        expect(find.text('Aliran banyak'), findsNothing);

        // Tapping the single option should return index 0
        await tester.tap(find.text('Tidak Ada'));
        expect(selectedIndex, 0);
      },
    );

    testWidgets(
      'When isPeriod is true, all 5 flow options are displayed',
      (WidgetTester tester) async {
        int? selectedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlowSelectorSection(
                isPeriod: true,
                selectedFlowIndex: 3,
                onFlowSelected: (idx) => selectedIndex = idx,
              ),
            ),
          ),
        );

        // Header and standard subtitle should appear
        expect(find.text('Aliran Menstruasi'), findsOneWidget);
        expect(find.text('Pilih intensitas aliran darah hari ini'), findsOneWidget);

        // Non-period guidance note should NOT be shown
        expect(find.text('Di luar masa haid, pilihan intensitas darah haid dinonaktifkan.'), findsNothing);

        // All 5 flow options should be present
        expect(find.text('Tidak Ada'), findsOneWidget);
        expect(find.text('Bersih'), findsOneWidget);
        expect(find.text('Flek'), findsOneWidget);
        expect(find.text('Bercak ringan'), findsOneWidget);
        expect(find.text('Ringan'), findsOneWidget);
        expect(find.text('Aliran sedikit'), findsOneWidget);
        expect(find.text('Sedang'), findsOneWidget);
        expect(find.text('Aliran normal'), findsOneWidget);
        expect(find.text('Deras'), findsOneWidget);
        expect(find.text('Aliran banyak'), findsOneWidget);

        // Tapping another option (e.g. Ringan = index 2)
        await tester.tap(find.text('Ringan'));
        expect(selectedIndex, 2);
      },
    );
  });
}

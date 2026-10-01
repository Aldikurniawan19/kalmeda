import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/record/presentation/screens/record_screen.dart';
import 'package:menstracker/features/record/presentation/widgets/record_stepper_header.dart';

void main() {
  testWidgets('RecordScreen renders stepper and navigates across 3 steps correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RecordScreen(),
      ),
    );

    // Initial check: Stepper Header is rendered
    expect(find.byType(RecordStepperHeader), findsOneWidget);
    expect(find.text('Siklus & Mood'), findsOneWidget);
    expect(find.text('Gejala & Fisik'), findsOneWidget);
    expect(find.text('Catatan & Saran'), findsOneWidget);

    // Step 0: Flow & Mood
    expect(find.text('Aliran Menstruasi'), findsOneWidget);
    expect(find.text('Suasana Hati (Mood)'), findsOneWidget);
    expect(find.text('Lanjut ke Gejala'), findsOneWidget);
    expect(find.text('Kembali'), findsNothing);

    // Navigate to Step 1: Gejala & Fisik
    await tester.tap(find.text('Lanjut ke Gejala'));
    await tester.pumpAndSettle();

    expect(find.text('Gejala Fisik'), findsOneWidget);
    expect(find.text('Pola Hidup Sehat'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut ke Catatan'), findsOneWidget);

    // Navigate to Step 2: Catatan & Saran
    await tester.tap(find.text('Lanjut ke Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan Tambahan'), findsOneWidget);
    expect(find.text('Analisis & Panduan Kesehatan Klinis'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Simpan Catatan'), findsOneWidget);

    // Test Back button navigation from Step 2 to Step 1
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Gejala Fisik'), findsOneWidget);

    // Test direct tap on Step Header (jump to Step 0)
    await tester.tap(find.text('Siklus & Mood'));
    await tester.pumpAndSettle();

    expect(find.text('Aliran Menstruasi'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_contraception_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_health_conditions_step.dart';
import 'package:menstracker/features/period_setup/presentation/widgets/setup_reproductive_status_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Period Setup Step Widgets Tests', () {
    testWidgets('SetupReproductiveStatusStep renders correctly and allows selection', (tester) async {
      String status = 'single';
      int? menarcheAge = 12;
      String activityLevel = 'moderate';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: SetupReproductiveStatusStep(
                    selectedStatus: status,
                    selectedMenarcheAge: menarcheAge,
                    selectedActivityLevel: activityLevel,
                    onStatusSelected: (val) => setState(() => status = val),
                    onMenarcheAgeChanged: (val) => setState(() => menarcheAge = val),
                    onActivityLevelChanged: (val) => setState(() => activityLevel = val),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Status Reproduksi & Gaya Hidup'), findsOneWidget);
      expect(find.text('Merencanakan Kehamilan (Promil)'), findsOneWidget);
      expect(find.text('Tidak Ingin Menjawab'), findsOneWidget);
      expect(find.text('12 th'), findsOneWidget);

      // Tap on Promil
      await tester.tap(find.text('Merencanakan Kehamilan (Promil)'));
      await tester.pumpAndSettle();
      expect(status, 'planning_pregnancy');

      // Tap on privacy skip option
      await tester.tap(find.text('Tidak Ingin Menjawab'));
      await tester.pumpAndSettle();
      expect(status, 'prefer_not_to_say');
    });

    testWidgets('SetupContraceptionStep renders clinical warning and privacy option', (tester) async {
      String contraception = 'none';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: SetupContraceptionStep(
                    selectedContraception: contraception,
                    onContraceptionSelected: (val) => setState(() => contraception = val),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Penggunaan Kontrasepsi'), findsOneWidget);
      expect(find.text('Pil KB Hormonal'), findsOneWidget);
      expect(find.text('IUD Hormonal (Mirena / Kyleena)'), findsOneWidget);
      expect(find.text('Tidak Ingin Menjawab'), findsOneWidget);

      // Select Pil KB
      await tester.tap(find.text('Pil KB Hormonal'));
      await tester.pumpAndSettle();
      expect(contraception, 'pill');
    });

    testWidgets('SetupHealthConditionsStep handles multi-select and exclusive options', (tester) async {
      List<String> conditions = ['none'];
      List<String> familyHistory = ['none'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: SetupHealthConditionsStep(
                    selectedConditions: conditions,
                    selectedFamilyHistory: familyHistory,
                    onConditionsChanged: (val) => setState(() => conditions = val),
                    onFamilyHistoryChanged: (val) => setState(() => familyHistory = val),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Riwayat Kesehatan & Keluarga'), findsOneWidget);
      expect(find.text('Privasi & Kerahasiaan Medis Terjamin'), findsOneWidget);
      expect(find.text('PCOS (Sindrom Ovarium Polikistik)'), findsOneWidget);
      expect(find.text('Endometriosis'), findsOneWidget);

      // Select PCOS
      await tester.tap(find.text('PCOS (Sindrom Ovarium Polikistik)'));
      await tester.pumpAndSettle();
      expect(conditions, contains('pcos'));
      expect(conditions, isNot(contains('none')));

      // Select Endometriosis
      await tester.tap(find.text('Endometriosis'));
      await tester.pumpAndSettle();
      expect(conditions, contains('pcos'));
      expect(conditions, contains('endometriosis'));

      // Select "Tidak Ingin Menjawab" -> should clear other selections for privacy
      await tester.ensureVisible(find.text('Tidak Ingin Menjawab').first);
      await tester.tap(find.text('Tidak Ingin Menjawab').first);
      await tester.pumpAndSettle();
      expect(conditions, ['prefer_not_to_say']);
    });
  });
}

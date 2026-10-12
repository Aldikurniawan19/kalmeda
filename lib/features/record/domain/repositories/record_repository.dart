import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Contract interface for cycle records repository managing daily symptoms, mood, and flow.
abstract class RecordRepository {
  Future<void> saveRecord(CycleRecordModel record);
  Future<CycleRecordModel?> getRecordByDate(DateTime date);
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month);
  Future<List<CycleRecordModel>> getAllRecords();
  Future<void> syncAllFromCloud();
  Stream<List<CycleRecordModel>> getRecordsStream();
}

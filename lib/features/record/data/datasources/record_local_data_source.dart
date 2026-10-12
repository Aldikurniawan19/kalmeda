import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Contract interface for local offline storage of cycle records.
abstract class RecordLocalDataSource {
  Future<void> saveRecord(CycleRecordModel record);
  Future<CycleRecordModel?> getRecordByDate(String userId, DateTime date);
  Future<List<CycleRecordModel>> getRecordsByMonth(String userId, int year, int month);
  Future<List<CycleRecordModel>> getAllRecords(String userId);
  Future<void> saveAllRecords(String userId, List<CycleRecordModel> records);
  Stream<List<CycleRecordModel>> watchRecords(String userId);
}

/// SharedPreferences implementation of [RecordLocalDataSource] providing instant offline persistence.
class RecordLocalDataSourceImpl implements RecordLocalDataSource {
  static final RecordLocalDataSourceImpl _instance = RecordLocalDataSourceImpl._internal();
  factory RecordLocalDataSourceImpl() => _instance;
  RecordLocalDataSourceImpl._internal();

  static const String _prefPrefix = 'kalmeda_user_records_';
  final StreamController<String> _recordsChangeController = StreamController<String>.broadcast();

  String _userKey(String userId) {
    final cleanUid = userId.trim().isEmpty ? 'guest' : userId.trim();
    return '$_prefPrefix$cleanUid';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveRecord(CycleRecordModel record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(record.userId);
      final rawMap = _loadStoredMap(prefs, key);

      final dateKey = _dateKey(record.date);
      rawMap[dateKey] = jsonEncode(record.toLocalMap());

      await prefs.setString(key, jsonEncode(rawMap));
      _recordsChangeController.add(record.userId);
    } catch (e) {
      debugPrint('Error saving record to local storage: $e');
    }
  }

  @override
  Future<CycleRecordModel?> getRecordByDate(String userId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId);
      final rawMap = _loadStoredMap(prefs, key);

      final dateKey = _dateKey(date);
      final recordJson = rawMap[dateKey];
      if (recordJson == null) return null;

      final decoded = jsonDecode(recordJson) as Map<String, dynamic>;
      return CycleRecordModel.fromJson(decoded, id: dateKey, userId: userId);
    } catch (e) {
      debugPrint('Error reading local record by date: $e');
      return null;
    }
  }

  @override
  Future<List<CycleRecordModel>> getRecordsByMonth(String userId, int year, int month) async {
    try {
      final all = await getAllRecords(userId);
      return all.where((r) => r.date.year == year && r.date.month == month).toList();
    } catch (e) {
      debugPrint('Error reading monthly local records: $e');
      return [];
    }
  }

  @override
  Future<List<CycleRecordModel>> getAllRecords(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId);
      final rawMap = _loadStoredMap(prefs, key);

      final List<CycleRecordModel> results = [];
      for (final entry in rawMap.entries) {
        try {
          final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
          results.add(CycleRecordModel.fromJson(decoded, id: entry.key, userId: userId));
        } catch (_) {}
      }

      results.sort((a, b) => b.date.compareTo(a.date));
      return results;
    } catch (e) {
      debugPrint('Error reading all local records: $e');
      return [];
    }
  }

  @override
  Future<void> saveAllRecords(String userId, List<CycleRecordModel> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId);
      final rawMap = _loadStoredMap(prefs, key);

      for (final record in records) {
        final dateKey = _dateKey(record.date);
        rawMap[dateKey] = jsonEncode(record.toLocalMap());
      }

      await prefs.setString(key, jsonEncode(rawMap));
      _recordsChangeController.add(userId);
    } catch (e) {
      debugPrint('Error saving all records to local storage: $e');
    }
  }

  @override
  Stream<List<CycleRecordModel>> watchRecords(String userId) async* {
    yield await getAllRecords(userId);

    await for (final changedUserId in _recordsChangeController.stream) {
      if (changedUserId == userId || changedUserId.isEmpty || userId.isEmpty) {
        yield await getAllRecords(userId);
      }
    }
  }

  Map<String, String> _loadStoredMap(SharedPreferences prefs, String key) {
    final rawString = prefs.getString(key);
    if (rawString == null || rawString.isEmpty) {
      return <String, String>{};
    }

    try {
      final dynamic decoded = jsonDecode(rawString);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return <String, String>{};
  }
}

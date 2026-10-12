import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/record/data/datasources/record_local_data_source.dart';
import 'package:menstracker/features/record/data/datasources/record_remote_data_source.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/domain/repositories/record_repository.dart';

/// Implementation of [RecordRepository] providing offline-first persistence with seamless cloud synchronization.
class RecordRepositoryImpl implements RecordRepository, RecordRemoteDataSource {
  final RecordLocalDataSource _localDataSource;
  final RecordRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  RecordRepositoryImpl({
    RecordLocalDataSource? localDataSource,
    RecordRemoteDataSource? remoteDataSource,
    FirebaseAuth? auth,
  })  : _localDataSource = localDataSource ?? RecordLocalDataSourceImpl(),
        _remoteDataSource = remoteDataSource ?? RecordRemoteDataSourceImpl(),
        _auth = auth ?? FirebaseAuth.instance;

  String _resolveUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    try {
      final authUser = AuthController().currentUser;
      if (authUser != null && authUser.uid.isNotEmpty) return authUser.uid;
    } catch (_) {}
    return 'guest';
  }

  String _dateDocId(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveRecord(CycleRecordModel record) async {
    final uid = record.userId.isNotEmpty ? record.userId : _resolveUserId();
    final docId = _dateDocId(record.date);

    final normalizedRecord = record.copyWith(
      userId: uid,
      id: record.id.isNotEmpty ? record.id : docId,
      createdAt: record.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Save to local storage first to guarantee offline reliability
    await _localDataSource.saveRecord(normalizedRecord);

    // 2. Sync to cloud Firestore in background
    try {
      await _remoteDataSource.saveRecord(normalizedRecord);
    } catch (e) {
      debugPrint('Cloud sync skipped or restricted: $e. Data is safely stored locally.');
      // Keep local save valid so users do not experience data loss
    }
  }

  @override
  Future<CycleRecordModel?> getRecordByDate(DateTime date) async {
    final uid = _resolveUserId();
    final localRecord = await _localDataSource.getRecordByDate(uid, date);

    try {
      final remoteRecord = await _remoteDataSource.getRecordByDate(date);
      if (remoteRecord != null) {
        await _localDataSource.saveRecord(remoteRecord);
        return remoteRecord;
      }
    } catch (_) {}

    return localRecord;
  }

  @override
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month) async {
    final uid = _resolveUserId();
    final localRecords = await _localDataSource.getRecordsByMonth(uid, year, month);

    try {
      final remoteRecords = await _remoteDataSource.getRecordsByMonth(year, month);
      if (remoteRecords.isNotEmpty) {
        await _localDataSource.saveAllRecords(uid, remoteRecords);
        // Re-read merged local records
        return await _localDataSource.getRecordsByMonth(uid, year, month);
      }
    } catch (_) {}

    return localRecords;
  }

  @override
  Future<List<CycleRecordModel>> getAllRecords() async {
    final uid = _resolveUserId();
    return await _localDataSource.getAllRecords(uid);
  }

  @override
  Future<List<CycleRecordModel>> getAllRemoteRecords() async {
    return await _remoteDataSource.getAllRemoteRecords();
  }

  @override
  Future<void> syncAllFromCloud() async {
    final uid = _resolveUserId();
    if (uid == 'guest' || uid.isEmpty) return;

    try {
      final remoteRecords = await _remoteDataSource.getAllRemoteRecords();
      if (remoteRecords.isNotEmpty) {
        await _localDataSource.saveAllRecords(uid, remoteRecords);
        debugPrint('Successfully synchronized ${remoteRecords.length} records from cloud to local storage.');
      }
    } catch (e) {
      debugPrint('Sync all from cloud skipped or encountered error: $e');
    }
  }

  @override
  Stream<List<CycleRecordModel>> getRecordsStream() {
    final uid = _resolveUserId();
    return _localDataSource.watchRecords(uid);
  }
}

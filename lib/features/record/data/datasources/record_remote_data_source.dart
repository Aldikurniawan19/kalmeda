import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:menstracker/core/error/exceptions.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Contract interface for remote record data operations per user.
abstract class RecordRemoteDataSource {
  Future<void> saveRecord(CycleRecordModel record);
  Future<CycleRecordModel?> getRecordByDate(DateTime date);
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month);
  Future<List<CycleRecordModel>> getAllRemoteRecords();
  Stream<List<CycleRecordModel>> getRecordsStream();
}

/// Firestore implementation enforcing per-user data isolation under `users/{uid}/records`.
class RecordRemoteDataSourceImpl implements RecordRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RecordRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> _resolveUserId() async {
    User? user = _auth.currentUser;
    if (user == null) {
      try {
        user = await _auth.authStateChanges().first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => _auth.currentUser,
        );
      } catch (_) {
        user = _auth.currentUser;
      }
    }

    if (user != null && user.uid.isNotEmpty) return user.uid;

    try {
      final authUser = AuthController().currentUser;
      if (authUser != null && authUser.uid.isNotEmpty) {
        return authUser.uid;
      }
    } catch (_) {}

    return null;
  }

  CollectionReference<Map<String, dynamic>>? _getUserRecordsCollection(String uid) {
    if (uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('records');
  }

  String _dateDocId(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveRecord(CycleRecordModel record) async {
    final uid = await _resolveUserId();
    if (uid == null) {
      throw const AuthException('Pengguna belum masuk.');
    }

    final collection = _getUserRecordsCollection(uid);
    if (collection == null) {
      throw const ServerException('Referensi koleksi pengguna tidak valid.');
    }

    final docId = _dateDocId(record.date);
    final docRef = collection.doc(docId);

    try {
      final payload = record.toJson();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('Firestore saveRecord error [${e.code}]: ${e.message}');
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Izin akses database cloud tidak diizinkan. Periksa aturan keamanan Firestore.'
            : (e.message ?? 'Gagal menyimpan catatan ke server cloud.'),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Gagal menyimpan catatan ke server cloud: $e');
    }
  }

  @override
  Future<CycleRecordModel?> getRecordByDate(DateTime date) async {
    final uid = await _resolveUserId();
    if (uid == null) return null;

    final collection = _getUserRecordsCollection(uid);
    if (collection == null) return null;

    try {
      final docId = _dateDocId(date);
      final snapshot = await collection.doc(docId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;

      return CycleRecordModel.fromJson(
        snapshot.data()!,
        id: snapshot.id,
        userId: uid,
      );
    } catch (e) {
      debugPrint('Firestore getRecordByDate error: $e');
      return null;
    }
  }

  @override
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month) async {
    final uid = await _resolveUserId();
    if (uid == null) return [];

    final collection = _getUserRecordsCollection(uid);
    if (collection == null) return [];

    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs.map((doc) {
        return CycleRecordModel.fromJson(
          doc.data(),
          id: doc.id,
          userId: uid,
        );
      }).toList();
    } catch (e) {
      debugPrint('Firestore getRecordsByMonth error: $e');
      return [];
    }
  }

  @override
  Future<List<CycleRecordModel>> getAllRemoteRecords() async {
    final uid = await _resolveUserId();
    if (uid == null) return [];

    final collection = _getUserRecordsCollection(uid);
    if (collection == null) return [];

    try {
      final snapshot = await collection.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) {
        return CycleRecordModel.fromJson(
          doc.data(),
          id: doc.id,
          userId: uid,
        );
      }).toList();
    } catch (e) {
      debugPrint('Firestore getAllRemoteRecords error: $e');
      return [];
    }
  }

  @override
  Stream<List<CycleRecordModel>> getRecordsStream() async* {
    final uid = await _resolveUserId();
    if (uid == null) {
      yield [];
      return;
    }

    final collection = _getUserRecordsCollection(uid);
    if (collection == null) {
      yield [];
      return;
    }

    yield* collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CycleRecordModel.fromJson(
          doc.data(),
          id: doc.id,
          userId: uid,
        );
      }).toList();
    }).handleError((error) {
      debugPrint('Firestore getRecordsStream error: $error');
      return <CycleRecordModel>[];
    });
  }
}

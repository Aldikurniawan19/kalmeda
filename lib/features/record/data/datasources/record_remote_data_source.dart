import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:menstracker/features/record/data/models/cycle_record_model.dart';

/// Contract interface for remote record data operations per user.
abstract class RecordRemoteDataSource {
  Future<void> saveRecord(CycleRecordModel record);
  Future<CycleRecordModel?> getRecordByDate(DateTime date);
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month);
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

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _getUserRecordsCollection() {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('records');
  }

  String _dateDocId(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveRecord(CycleRecordModel record) async {
    final collection = _getUserRecordsCollection();
    if (collection == null) {
      throw Exception('Pengguna belum masuk.');
    }

    final docId = _dateDocId(record.date);
    final docRef = collection.doc(docId);
    final existingSnapshot = await docRef.get();

    if (existingSnapshot.exists && existingSnapshot.data() != null) {
      // Jika masih di hari yang sama: mengganti catatan sebelumnya (overwrite/replace penuh)
      final existingData = existingSnapshot.data()!;
      final originalCreatedAt = existingData['createdAt'];

      final updatedData = record.toJson();
      if (originalCreatedAt != null) {
        updatedData['createdAt'] = originalCreatedAt;
      }
      updatedData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(updatedData);
    } else {
      // Jika di hari yang berbeda: membuat catatan data baru
      await docRef.set(record.toJson());
    }
  }

  @override
  Future<CycleRecordModel?> getRecordByDate(DateTime date) async {
    final collection = _getUserRecordsCollection();
    if (collection == null) return null;

    final docId = _dateDocId(date);
    final snapshot = await collection.doc(docId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;

    return CycleRecordModel.fromJson(
      snapshot.data()!,
      id: snapshot.id,
      userId: _currentUserId ?? '',
    );
  }

  @override
  Future<List<CycleRecordModel>> getRecordsByMonth(int year, int month) async {
    final collection = _getUserRecordsCollection();
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
          userId: _currentUserId ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<CycleRecordModel>> getRecordsStream() {
    final collection = _getUserRecordsCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CycleRecordModel.fromJson(
          doc.data(),
          id: doc.id,
          userId: _currentUserId ?? '',
        );
      }).toList();
    });
  }
}

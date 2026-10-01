import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a daily period and symptom log for a user.
class CycleRecordModel {
  final String id;
  final String userId;
  final DateTime date;
  final int flowIndex; // 0: None, 1: Spotting, 2: Light, 3: Medium, 4: Heavy
  final int moodIndex; // 0: Happy, 1: Sensitive, 2: Moody, 3: Tired, 4: Painful
  final List<int> symptoms;
  final int waterCups;
  final int exerciseIndex;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CycleRecordModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.flowIndex,
    required this.moodIndex,
    required this.symptoms,
    required this.waterCups,
    required this.exerciseIndex,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CycleRecordModel.fromJson(Map<String, dynamic> json, {required String id, required String userId}) {
    DateTime parsedDate = DateTime.now();
    final dateRaw = json['date'];
    if (dateRaw is Timestamp) {
      parsedDate = dateRaw.toDate();
    } else if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    }

    DateTime? parsedCreatedAt;
    final createdRaw = json['createdAt'];
    if (createdRaw is Timestamp) {
      parsedCreatedAt = createdRaw.toDate();
    }

    DateTime? parsedUpdatedAt;
    final updatedRaw = json['updatedAt'];
    if (updatedRaw is Timestamp) {
      parsedUpdatedAt = updatedRaw.toDate();
    }

    final symptomsList = (json['symptoms'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        <int>[];

    return CycleRecordModel(
      id: id,
      userId: userId,
      date: parsedDate,
      flowIndex: (json['flowIndex'] as num?)?.toInt() ?? 3,
      moodIndex: (json['moodIndex'] as num?)?.toInt() ?? 0,
      symptoms: symptomsList,
      waterCups: (json['waterCups'] as num?)?.toInt() ?? 8,
      exerciseIndex: (json['exerciseIndex'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'flowIndex': flowIndex,
      'moodIndex': moodIndex,
      'symptoms': symptoms,
      'waterCups': waterCups,
      'exerciseIndex': exerciseIndex,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

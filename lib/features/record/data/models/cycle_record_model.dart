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

  CycleRecordModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? flowIndex,
    int? moodIndex,
    List<int>? symptoms,
    int? waterCups,
    int? exerciseIndex,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      flowIndex: flowIndex ?? this.flowIndex,
      moodIndex: moodIndex ?? this.moodIndex,
      symptoms: symptoms ?? this.symptoms,
      waterCups: waterCups ?? this.waterCups,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CycleRecordModel.fromJson(
    Map<String, dynamic> json, {
    String id = '',
    String userId = '',
  }) {
    DateTime parsedDate = DateTime.now();
    final dateRaw = json['date'];
    if (dateRaw is Timestamp) {
      parsedDate = dateRaw.toDate();
    } else if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else if (dateRaw is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateRaw);
    }

    DateTime? parsedCreatedAt;
    final createdRaw = json['createdAt'];
    if (createdRaw is Timestamp) {
      parsedCreatedAt = createdRaw.toDate();
    } else if (createdRaw is String) {
      parsedCreatedAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    }

    DateTime? parsedUpdatedAt;
    final updatedRaw = json['updatedAt'];
    if (updatedRaw is Timestamp) {
      parsedUpdatedAt = updatedRaw.toDate();
    } else if (updatedRaw is String) {
      parsedUpdatedAt = DateTime.tryParse(updatedRaw);
    } else if (updatedRaw is int) {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(updatedRaw);
    }

    final symptomsList = (json['symptoms'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        <int>[];

    final finalUserId = userId.isNotEmpty ? userId : (json['userId'] as String? ?? '');
    final finalId = id.isNotEmpty ? id : (json['id'] as String? ?? '');

    return CycleRecordModel(
      id: finalId,
      userId: finalUserId,
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

  /// Converts this model into a Firestore-compatible JSON map with Timestamps.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

  /// Converts this model into standard JSON-serializable Map for local SharedPreferences cache.
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'flowIndex': flowIndex,
      'moodIndex': moodIndex,
      'symptoms': symptoms,
      'waterCups': waterCups,
      'exerciseIndex': exerciseIndex,
      'notes': notes,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

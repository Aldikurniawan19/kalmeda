import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinical baseline menstrual cycle profile model.
class CycleProfileModel {
  final String trackingGoal; // 'predict_period', 'fertility_ovulation', 'symptom_health'
  final DateTime lastPeriodDate;
  final DateTime? lastPeriodEndDate;
  final int cycleLength; // 21 - 45 days (median standard: 28)
  final int periodDuration; // 2 - 10 days (median standard: 5)
  final String regularity; // 'regular', 'sometimes_variable', 'irregular'
  final DateTime birthDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CycleProfileModel({
    required this.trackingGoal,
    required this.lastPeriodDate,
    this.lastPeriodEndDate,
    required this.cycleLength,
    required this.periodDuration,
    required this.regularity,
    required this.birthDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed birth year property derived from birthDate.
  int get birthYear => birthDate.year;

  factory CycleProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedLastPeriod = DateTime.now();
    final lmpRaw = json['lastPeriodDate'];
    if (lmpRaw is Timestamp) {
      parsedLastPeriod = lmpRaw.toDate();
    } else if (lmpRaw is String) {
      parsedLastPeriod = DateTime.tryParse(lmpRaw) ?? DateTime.now();
    }

    DateTime? parsedLastPeriodEnd;
    final lmpEndRaw = json['lastPeriodEndDate'];
    if (lmpEndRaw is Timestamp) {
      parsedLastPeriodEnd = lmpEndRaw.toDate();
    } else if (lmpEndRaw is String) {
      parsedLastPeriodEnd = DateTime.tryParse(lmpEndRaw);
    }

    DateTime parsedBirthDate = DateTime(2000, 1, 1);
    final birthDateRaw = json['birthDate'];
    if (birthDateRaw is Timestamp) {
      parsedBirthDate = birthDateRaw.toDate();
    } else if (birthDateRaw is String) {
      parsedBirthDate = DateTime.tryParse(birthDateRaw) ?? DateTime(2000, 1, 1);
    } else if (json['birthYear'] is num) {
      parsedBirthDate = DateTime((json['birthYear'] as num).toInt(), 1, 1);
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

    return CycleProfileModel(
      trackingGoal: json['trackingGoal'] as String? ?? 'predict_period',
      lastPeriodDate: parsedLastPeriod,
      lastPeriodEndDate: parsedLastPeriodEnd,
      cycleLength: (json['cycleLength'] as num?)?.toInt() ?? 28,
      periodDuration: (json['periodDuration'] as num?)?.toInt() ?? 5,
      regularity: json['regularity'] as String? ?? 'regular',
      birthDate: parsedBirthDate,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingGoal': trackingGoal,
      'lastPeriodDate': Timestamp.fromDate(lastPeriodDate),
      'lastPeriodEndDate': lastPeriodEndDate != null ? Timestamp.fromDate(lastPeriodEndDate!) : null,
      'cycleLength': cycleLength,
      'periodDuration': periodDuration,
      'regularity': regularity,
      'birthDate': Timestamp.fromDate(birthDate),
      'birthYear': birthYear,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copies this instance with optional updated fields.
  CycleProfileModel copyWith({
    String? trackingGoal,
    DateTime? lastPeriodDate,
    DateTime? lastPeriodEndDate,
    bool clearLastPeriodEndDate = false,
    int? cycleLength,
    int? periodDuration,
    String? regularity,
    DateTime? birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleProfileModel(
      trackingGoal: trackingGoal ?? this.trackingGoal,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      lastPeriodEndDate: clearLastPeriodEndDate ? null : (lastPeriodEndDate ?? this.lastPeriodEndDate),
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      regularity: regularity ?? this.regularity,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

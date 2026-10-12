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

  /// Helper to safely parse dates from Timestamp, ISO String, or epoch milliseconds.
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    if (raw is num) {
      final intVal = raw.toInt();
      // If it looks like milliseconds since epoch (> 10^10)
      if (intVal > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal);
      }
      // If it looks like seconds since epoch (> 10^7)
      if (intVal > 10000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      }
      // If it looks like a year (e.g. 1990 - 2030)
      if (intVal >= 1900 && intVal <= 2100) {
        return DateTime(intVal, 1, 1);
      }
    }
    return null;
  }

  factory CycleProfileModel.fromJson(Map<String, dynamic> json) {
    final lmpRaw = json['lastPeriodDate'] ??
        json['last_period_date'] ??
        json['lastPeriod'] ??
        json['lmp'];
    final parsedLastPeriod = _parseDate(lmpRaw) ?? DateTime.now().subtract(const Duration(days: 7));

    final lmpEndRaw = json['lastPeriodEndDate'] ??
        json['last_period_end_date'] ??
        json['lastPeriodEnd'];
    final parsedLastPeriodEnd = _parseDate(lmpEndRaw);

    final birthRaw = json['birthDate'] ??
        json['birth_date'] ??
        json['dateOfBirth'] ??
        json['date_of_birth'] ??
        json['birthYear'] ??
        json['birth_year'];
    final parsedBirthDate = _parseDate(birthRaw) ?? DateTime(2000, 1, 1);

    final parsedCreatedAt = _parseDate(json['createdAt'] ?? json['created_at']);
    final parsedUpdatedAt = _parseDate(json['updatedAt'] ?? json['updated_at']);

    final rawGoal = json['trackingGoal'] ?? json['tracking_goal'];
    final rawCycleLength = json['cycleLength'] ?? json['cycle_length'];
    final rawPeriodDuration = json['periodDuration'] ?? json['period_duration'];
    final rawRegularity = json['regularity'];

    return CycleProfileModel(
      trackingGoal: rawGoal is String && rawGoal.isNotEmpty ? rawGoal : 'predict_period',
      lastPeriodDate: parsedLastPeriod,
      lastPeriodEndDate: parsedLastPeriodEnd,
      cycleLength: (rawCycleLength as num?)?.toInt() ?? 28,
      periodDuration: (rawPeriodDuration as num?)?.toInt() ?? 5,
      regularity: rawRegularity is String && rawRegularity.isNotEmpty ? rawRegularity : 'regular',
      birthDate: parsedBirthDate,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts this model into a Firestore-compatible JSON map.
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

  /// Converts this model into a standard JSON-serializable Map for local SharedPreferences cache.
  Map<String, dynamic> toLocalMap() {
    return {
      'trackingGoal': trackingGoal,
      'lastPeriodDate': lastPeriodDate.toIso8601String(),
      'lastPeriodEndDate': lastPeriodEndDate?.toIso8601String(),
      'cycleLength': cycleLength,
      'periodDuration': periodDuration,
      'regularity': regularity,
      'birthDate': birthDate.toIso8601String(),
      'birthYear': birthYear,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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

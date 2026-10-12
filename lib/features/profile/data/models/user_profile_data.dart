import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';

/// Comprehensive domain-data model combining account details, menstrual cycle configuration, and health profile.
class UserProfileData {
  final String uid;
  final String name;
  final String email;
  final DateTime birthDate;
  final CycleProfileModel cycleProfile;
  final HealthProfileModel? healthProfile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileData({
    required this.uid,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.cycleProfile,
    this.healthProfile,
    this.createdAt,
    this.updatedAt,
  });

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
      if (intVal > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal);
      }
      if (intVal > 10000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      }
      if (intVal >= 1900 && intVal <= 2100) {
        return DateTime(intVal, 1, 1);
      }
    }
    return null;
  }

  /// Factory to construct [UserProfileData] from Firestore document map or local JSON map.
  factory UserProfileData.fromJson(Map<String, dynamic> json, {required String uid, String? fallbackEmail}) {
    final birthDateRaw = json['birthDate'] ??
        json['birth_date'] ??
        json['dateOfBirth'] ??
        json['date_of_birth'] ??
        json['birthYear'] ??
        json['birth_year'];
    DateTime parsedBirthDate = _parseDate(birthDateRaw) ?? DateTime(2000, 1, 1);

    CycleProfileModel cycleProfile;
    final cycleRaw = json['cycleProfile'] ?? json['cycle_profile'];
    if (cycleRaw is Map<String, dynamic>) {
      cycleProfile = CycleProfileModel.fromJson(cycleRaw);
      // Synchronize birth date if one was provided in cycle profile and not at root
      if (parsedBirthDate == DateTime(2000, 1, 1) && cycleProfile.birthDate != DateTime(2000, 1, 1)) {
        parsedBirthDate = cycleProfile.birthDate;
      } else if (parsedBirthDate != DateTime(2000, 1, 1) && cycleProfile.birthDate == DateTime(2000, 1, 1)) {
        cycleProfile = cycleProfile.copyWith(birthDate: parsedBirthDate);
      }
    } else {
      cycleProfile = CycleProfileModel(
        trackingGoal: 'predict_period',
        lastPeriodDate: DateTime.now().subtract(const Duration(days: 7)),
        cycleLength: 28,
        periodDuration: 5,
        regularity: 'regular',
        birthDate: parsedBirthDate,
      );
    }

    HealthProfileModel? healthProfile;
    final healthRaw = json['healthProfile'] ?? json['health_profile'];
    if (healthRaw is Map<String, dynamic>) {
      healthProfile = HealthProfileModel.fromJson(healthRaw);
    }

    final parsedCreatedAt = _parseDate(json['createdAt'] ?? json['created_at']);
    final parsedUpdatedAt = _parseDate(json['updatedAt'] ?? json['updated_at']);

    return UserProfileData(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? fallbackEmail ?? '',
      birthDate: parsedBirthDate,
      cycleProfile: cycleProfile,
      healthProfile: healthProfile,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts this model into a standard JSON-serializable Map for local SharedPreferences cache.
  Map<String, dynamic> toLocalMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'birthDate': birthDate.toIso8601String(),
      'birthYear': birthDate.year,
      'cycleProfile': cycleProfile.toLocalMap(),
      'healthProfile': healthProfile?.toLocalMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copies this instance with optional updated fields.
  UserProfileData copyWith({
    String? name,
    String? email,
    DateTime? birthDate,
    CycleProfileModel? cycleProfile,
    HealthProfileModel? healthProfile,
    DateTime? updatedAt,
  }) {
    return UserProfileData(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      cycleProfile: cycleProfile ?? this.cycleProfile,
      healthProfile: healthProfile ?? this.healthProfile,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

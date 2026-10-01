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

  /// Factory to construct [UserProfileData] from Firestore document map.
  factory UserProfileData.fromJson(Map<String, dynamic> json, {required String uid, String? fallbackEmail}) {
    DateTime parsedBirthDate = DateTime(2000, 1, 1);
    final birthDateRaw = json['birthDate'];
    if (birthDateRaw is Timestamp) {
      parsedBirthDate = birthDateRaw.toDate();
    } else if (birthDateRaw is String) {
      parsedBirthDate = DateTime.tryParse(birthDateRaw) ?? DateTime(2000, 1, 1);
    }

    CycleProfileModel cycleProfile;
    if (json['cycleProfile'] is Map<String, dynamic>) {
      cycleProfile = CycleProfileModel.fromJson(json['cycleProfile'] as Map<String, dynamic>);
      if (birthDateRaw == null && json['cycleProfile']['birthDate'] != null) {
        parsedBirthDate = cycleProfile.birthDate;
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
    if (json['healthProfile'] is Map<String, dynamic>) {
      healthProfile = HealthProfileModel.fromJson(json['healthProfile'] as Map<String, dynamic>);
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

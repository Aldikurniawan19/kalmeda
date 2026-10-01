import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:menstracker/features/auth/domain/entities/user_entity.dart';

/// Data Transfer Object (DTO) for User model, extending [UserEntity].
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.hasCompletedSetup = false,
    super.createdAt,
  });

  /// Factory constructor to create a [UserModel] from a Firestore Map document.
  factory UserModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime? parsedCreatedAt;
    final createdAtRaw = json['createdAt'];
    if (createdAtRaw is Timestamp) {
      parsedCreatedAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      parsedCreatedAt = DateTime.tryParse(createdAtRaw);
    }

    return UserModel(
      uid: docId ?? (json['uid'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hasCompletedSetup: json['hasCompletedSetup'] as bool? ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  /// Converts this [UserModel] instance into a Firestore JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'hasCompletedSetup': hasCompletedSetup,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Factory constructor to convert from [UserEntity] to [UserModel].
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      hasCompletedSetup: entity.hasCompletedSetup,
      createdAt: entity.createdAt,
    );
  }
}

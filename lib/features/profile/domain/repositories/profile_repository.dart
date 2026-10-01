import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';

/// Contract interface for Profile business operations.
abstract class ProfileRepository {
  /// Fetches current user profile and cycle setup details.
  Future<UserProfileData> getUserProfile();

  /// Updates personal details, cycle parameters, and health profile.
  Future<void> updateUserProfile({
    required String name,
    required DateTime birthDate,
    required CycleProfileModel cycleProfile,
    HealthProfileModel? healthProfile,
  });
}


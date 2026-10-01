import 'package:menstracker/features/period_setup/data/models/cycle_profile_model.dart';
import 'package:menstracker/features/period_setup/data/models/health_profile_model.dart';
import 'package:menstracker/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:menstracker/features/profile/data/models/user_profile_data.dart';
import 'package:menstracker/features/profile/domain/repositories/profile_repository.dart';

/// Concrete repository implementation for user profile management.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({
    ProfileRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl();

  @override
  Future<UserProfileData> getUserProfile() async {
    return await _remoteDataSource.getUserProfile();
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required DateTime birthDate,
    required CycleProfileModel cycleProfile,
    HealthProfileModel? healthProfile,
  }) async {
    return await _remoteDataSource.updateUserProfile(
      name: name,
      birthDate: birthDate,
      cycleProfile: cycleProfile,
      healthProfile: healthProfile,
    );
  }
}


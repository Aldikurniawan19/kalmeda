import 'package:shared_preferences/shared_preferences.dart';

import 'package:menstracker/features/auth/data/models/user_model.dart';

/// Contract interface for local persistent authentication session cache.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUserCache();
  Future<void> setSetupCompleted(bool completed);
  Future<void> updateUserName(String name);
  Future<bool> isLoggedIn();
}

/// SharedPreferences implementation of [AuthLocalDataSource] for fast offline session persistence.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _keyUid = 'kalmeda_auth_uid';
  static const String _keyName = 'kalmeda_auth_name';
  static const String _keyEmail = 'kalmeda_auth_email';
  static const String _keyHasSetup = 'kalmeda_auth_has_setup';
  static const String _keyCreatedAt = 'kalmeda_auth_created_at';
  static const String _keyIsLoggedIn = 'kalmeda_auth_is_logged_in';

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUid, user.uid);
      await prefs.setString(_keyName, user.name);
      await prefs.setString(_keyEmail, user.email);
      await prefs.setBool(_keyHasSetup, user.hasCompletedSetup);
      await prefs.setBool(_keyIsLoggedIn, true);
      if (user.createdAt != null) {
        await prefs.setString(_keyCreatedAt, user.createdAt!.toIso8601String());
      }
    } catch (_) {}
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_keyUid);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? (uid != null && uid.isNotEmpty);
      if (uid == null || uid.isEmpty || !isLoggedIn) return null;

      final name = prefs.getString(_keyName) ?? 'Pengguna';
      final email = prefs.getString(_keyEmail) ?? '';
      final hasCompletedSetup = prefs.getBool(_keyHasSetup) ?? false;
      final createdAtRaw = prefs.getString(_keyCreatedAt);
      final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

      return UserModel(
        uid: uid,
        name: name,
        email: email,
        hasCompletedSetup: hasCompletedSetup,
        createdAt: createdAt,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUid);
      await prefs.remove(_keyName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyHasSetup);
      await prefs.remove(_keyCreatedAt);
      await prefs.setBool(_keyIsLoggedIn, false);
    } catch (_) {}
  }

  @override
  Future<void> setSetupCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasSetup, completed);
    } catch (_) {}
  }

  @override
  Future<void> updateUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, name);
    } catch (_) {}
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_keyUid);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn);
      if (isLoggedIn != null) return isLoggedIn;
      return uid != null && uid.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}


import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_info.dart';
import 'package:menstracker/features/app_update/data/models/app_update_info.dart';
import 'package:menstracker/features/app_update/data/services/app_update_service.dart';
import 'package:menstracker/features/app_update/presentation/widgets/app_update_modal.dart';

/// Controller coordinating GitHub update checks and modal presentation.
class AppUpdateController extends ChangeNotifier {
  static final AppUpdateController _instance = AppUpdateController._internal();
  factory AppUpdateController() => _instance;
  AppUpdateController._internal();

  bool _isChecking = false;
  bool _isModalShowing = false;
  AppUpdateInfo? _availableUpdate;

  bool get isChecking => _isChecking;
  bool get isModalShowing => _isModalShowing;
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  /// Checks for GitHub Action releases silently in the background and prompts if a new version is detected.
  Future<bool> checkAndPromptSilently(BuildContext context) async {
    if (_isChecking || _isModalShowing) return false;

    // Check throttle interval
    final shouldCheck = await AppUpdateService.shouldCheckAutomatically();
    if (!shouldCheck) return false;

    _isChecking = true;
    try {
      final update = await AppUpdateService.checkLatestRelease();
      await AppUpdateService.recordLastCheckedTime();
      _availableUpdate = update;

      if (update != null && context.mounted) {
        final isDismissed =
            await AppUpdateService.isVersionDismissed(update.versionName);
        if (!isDismissed) {
          _isModalShowing = true;
          await AppUpdateModal.show(
            context,
            updateInfo: update,
            onDismissed: () {
              _isModalShowing = false;
            },
          );
          _isModalShowing = false;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Manually checks for updates (e.g. from Profile / About screen) with immediate UI feedback.
  Future<void> checkUpdateManually(BuildContext context) async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      final update = await AppUpdateService.checkLatestRelease();
      await AppUpdateService.recordLastCheckedTime();
      _availableUpdate = update;

      if (!context.mounted) return;

      if (update != null) {
        _isModalShowing = true;
        await AppUpdateModal.show(
          context,
          updateInfo: update,
          onDismissed: () {
            _isModalShowing = false;
          },
        );
        _isModalShowing = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aplikasi Kalmeda sudah dalam versi terbaru (v${AppInfo.appVersion}).',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memeriksa pembaruan. Pastikan perangkat terhubung ke internet.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}

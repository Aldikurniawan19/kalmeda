import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_info.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/app_update/data/models/app_update_info.dart';
import 'package:menstracker/features/app_update/data/services/app_update_service.dart';

/// Modal bottom sheet presenting a new app version release notification from GitHub Actions.
/// Strictly follows `aturan-desain.md` with clean clinical aesthetics and zero emojis.
class AppUpdateModal extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onDismissed;

  const AppUpdateModal({
    super.key,
    required this.updateInfo,
    this.onDismissed,
  });

  /// Displays the update modal as a responsive bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    VoidCallback? onDismissed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !updateInfo.isMandatory,
      enableDrag: !updateInfo.isMandatory,
      builder: (context) => AppUpdateModal(
        updateInfo: updateInfo,
        onDismissed: onDismissed,
      ),
    );
  }

  void _handleUpdateNow(BuildContext context) async {
    Navigator.of(context).pop();
    final url = updateInfo.apkDownloadUrl.isNotEmpty
        ? updateInfo.apkDownloadUrl
        : updateInfo.releaseUrl;
    await AppUpdateService.launchUpdateUrl(url);
  }

  void _handleLater(BuildContext context) async {
    await AppUpdateService.saveDismissedVersion(updateInfo.versionName);
    if (context.mounted) {
      Navigator.of(context).pop();
      onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space20,
            vertical: AppSizes.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.space16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DEE6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header: Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.space10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFD4E2),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Tersedia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Versi baru Kalmeda telah dirilis di GitHub',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space16),

              // 3. Version Comparison Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space14,
                  vertical: AppSizes.space12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: const Color(0xFFEEEAF0),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Versi Saat Ini
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Versi Saat Ini',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'v${AppInfo.appVersion}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(AppSizes.space6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),

                    // Versi Baru
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Versi Terbaru',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${updateInfo.versionName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space12),

              // 4. Release Metadata Badges (File size & date)
              Row(
                children: [
                  if (updateInfo.formattedSize.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.file_download_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            updateInfo.formattedSize,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.space8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.format(updateInfo.publishedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space14),

              // 5. Changelog / Release Notes Box
              const Text(
                'Catatan Pembaruan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.space6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(AppSizes.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBFD),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: const Color(0xFFFFEBF2),
                    width: 1.0,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    updateInfo.changelog,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space20),

              // 6. Action Buttons Row
              Row(
                children: [
                  if (!updateInfo.isMandatory) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleLater(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: Color(0xFFE5DEE6)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.space12),
                  ],
                  Expanded(
                    flex: updateInfo.isMandatory ? 1 : 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleUpdateNow(context),
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      label: Text(
                        updateInfo.hasDirectApk
                            ? 'Unduh APK'
                            : 'Perbarui Sekarang',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space8),
            ],
          ),
        ),
      ),
    );
  }
}

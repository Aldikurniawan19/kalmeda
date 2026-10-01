import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/home/presentation/controllers/reminder_controller.dart';

/// Bottom sheet modal for configuring cycle and health reminder notifications.
class ReminderSettingsBottomSheet extends StatefulWidget {
  const ReminderSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReminderSettingsBottomSheet(),
    );
  }

  @override
  State<ReminderSettingsBottomSheet> createState() => _ReminderSettingsBottomSheetState();
}

class _ReminderSettingsBottomSheetState extends State<ReminderSettingsBottomSheet> {
  late bool _period;
  late bool _fertile;
  late bool _water;
  late bool _pad;
  late bool _vitamin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final controller = ReminderController();
    _period = controller.periodReminder;
    _fertile = controller.fertileReminder;
    _water = controller.waterReminder;
    _pad = controller.padReminder;
    _vitamin = controller.vitaminReminder;

    controller.loadPreferences().then((_) {
      if (mounted) {
        setState(() {
          _period = controller.periodReminder;
          _fertile = controller.fertileReminder;
          _water = controller.waterReminder;
          _pad = controller.padReminder;
          _vitamin = controller.vitaminReminder;
        });
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final controller = ReminderController();
    controller.setReminderState(
      period: _period,
      fertile: _fertile,
      water: _water,
      pad: _pad,
      vitamin: _vitamin,
    );

    await controller.savePreferences();

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan pengingat berhasil disimpan.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: AppSizes.space12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5DEE6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.space16),

          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.space8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengingat Siklus & Kesehatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Atur notifikasi pengingat otomatis untuk hari-hari penting',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          const Divider(height: 1, color: Color(0xFFF3EEF5)),

          // Switches List & Action Buttons
          Flexible(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space20,
                vertical: AppSizes.space14,
              ),
              children: [
                _ReminderToggleTile(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.primary,
                  title: 'Pengingat Perkiraan Haid',
                  description: 'Notifikasi H-2 sebelum perkiraan menstruasi dimulai agar kamu selalu siap.',
                  value: _period,
                  onChanged: (val) => setState(() => _period = val),
                ),
                const SizedBox(height: AppSizes.space12),

                _ReminderToggleTile(
                  icon: Icons.spa_rounded,
                  iconColor: AppColors.ovulationSolid,
                  title: 'Pengingat Masa Subur & Ovulasi',
                  description: 'Pemberitahuan saat memasuki jendela masa subur dan hari ovulasi puncak.',
                  value: _fertile,
                  onChanged: (val) => setState(() => _fertile = val),
                ),
                const SizedBox(height: AppSizes.space12),

                _ReminderToggleTile(
                  icon: Icons.local_drink_rounded,
                  iconColor: const Color(0xFF0288D1),
                  title: 'Pengingat Minum Air Putih',
                  description: 'Pengingat hidrasi harian untuk menjaga metabolisme dan mencegah kram otot.',
                  value: _water,
                  onChanged: (val) => setState(() => _water = val),
                ),
                const SizedBox(height: AppSizes.space12),

                _ReminderToggleTile(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFF8E24AA),
                  title: 'Pengingat Ganti Pembalut',
                  description: 'Notifikasi berkala untuk higienitas dan kenyamanan area kewanitaan.',
                  value: _pad,
                  onChanged: (val) => setState(() => _pad = val),
                ),
                const SizedBox(height: AppSizes.space12),

                _ReminderToggleTile(
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF43A047),
                  title: 'Pengingat Suplemen & Zat Besi',
                  description: 'Pengingat asupan suplemen penambah darah saat menstruasi deras.',
                  value: _vitamin,
                  onChanged: (val) => setState(() => _vitamin = val),
                ),
                const SizedBox(height: AppSizes.space20),

                // Primary Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20),
                              SizedBox(width: AppSizes.space8),
                              Text(
                                'Simpan Pengaturan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSizes.space10),

                // Test notification action button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ReminderController().sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifikasi uji coba berhasil dikirim ke bilah notifikasi.'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFFFDDE6), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_active_rounded, size: 18),
                    label: const Text(
                      'Kirim Notifikasi Uji Coba',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.space24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: value ? const Color(0xFFFFDDE6) : const Color(0xFFF3EDF5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.space8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.space8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: const Color(0xFFFFD4E2),
            inactiveThumbColor: const Color(0xFFB0A8B3),
            inactiveTrackColor: const Color(0xFFEDE7EF),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';
import 'package:menstracker/features/record/domain/repositories/record_repository.dart';
import 'package:menstracker/features/record/presentation/controllers/daily_checkin_service.dart';

/// Quick mood logger and emotional health guidance bottom sheet.
class QuickMoodBottomSheet extends StatefulWidget {
  final VoidCallback? onOpenFullRecord;

  const QuickMoodBottomSheet({super.key, this.onOpenFullRecord});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onOpenFullRecord,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          QuickMoodBottomSheet(onOpenFullRecord: onOpenFullRecord),
    );
  }

  @override
  State<QuickMoodBottomSheet> createState() => _QuickMoodBottomSheetState();
}

class _QuickMoodBottomSheetState extends State<QuickMoodBottomSheet> {
  final RecordRepository _recordRepository = RecordRepositoryImpl();
  int _selectedMood = 0;
  bool _isSaving = false;

  static const _moods = [
    {
      'name': 'Bahagia',
      'icon': 'assets/icon/iconBahagia.png',
      'bg': AppColors.moodBahagiaBg,
      'tip':
          'Energi estrogen dan serotonin sedang optimal. Manfaatkan untuk aktivitas produktif dan kreatif!',
    },
    {
      'name': 'Tenang',
      'icon': 'assets/icon/iconTenang.png',
      'bg': AppColors.moodTenangBg,
      'tip':
          'Kondisi emosi stabil. Pertahankan ritme ini dengan meditasi ringan dan asupan makanan seimbang.',
    },
    {
      'name': 'Sedih',
      'icon': 'assets/icon/iconSedih.png',
      'bg': AppColors.moodSedihBg,
      'tip':
          'Fluktuasi progesteron wajar memicu emosi meluap. Istirahat sejenak dan dengarkan musik santai.',
    },
    {
      'name': 'Lelah',
      'icon': 'assets/icon/iconLelah.png',
      'bg': AppColors.moodLelahBg,
      'tip':
          'Tubuh membutuhkan waktu pemulihan energi. Tidur cukup 7–8 jam dan kurangi beban fisik berat.',
    },
    {
      'name': 'Nyeri',
      'icon': 'assets/icon/iconNyeri.png',
      'bg': AppColors.moodNyeriBg,
      'tip':
          'Gunakan kompres hangat di area panggul dan konsumsi air hangat untuk meredakan kram otot.',
    },
    {
      'name': 'Kembung',
      'icon': 'assets/icon/iconKembung.png',
      'bg': AppColors.moodKembungBg,
      'tip':
          'Kurangi asupan garam dan perbanyak buah kaya kalium (pisang, pepaya) untuk menstabilkan cairan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    final existing = HomeController().selectedDateRecord;
    if (existing != null) {
      _selectedMood = existing.moodIndex.clamp(0, _moods.length - 1);
    }
  }

  Future<void> _handleSaveQuickMood() async {
    final user = AuthController().currentUser;
    if (user == null || user.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masuk terlebih dahulu untuk menyimpan mood.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final existing = await _recordRepository.getRecordByDate(now);

      final isPeriod =
          HomeController().cycleOverview?.isPeriodActive == true ||
          HomeController().cycleOverview?.isPeriodProlonged == true;
      final defaultFlow = isPeriod ? 3 : 0;

      final record = CycleRecordModel(
        id: existing?.id ?? '',
        userId: user.uid,
        date: now,
        flowIndex: existing?.flowIndex ?? defaultFlow,
        moodIndex: _selectedMood,
        symptoms: existing?.symptoms ?? [],
        waterCups: existing?.waterCups ?? 8,
        exerciseIndex: existing?.exerciseIndex ?? 1,
        notes: existing?.notes ?? '',
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      await _recordRepository.saveRecord(record);
      DailyCheckinService().markCurrentSlotCompleted();
      DailyCheckinService().syncDailyInactivityNotification();
      await HomeController().loadData();

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mood "${_moods[_selectedMood]['name']}" berhasil dicatat untuk hari ini.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMood = _moods[_selectedMood];

    return Container(
      padding: const EdgeInsets.only(bottom: AppSizes.space24),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.space8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/icon/iconMood.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagaimana Mood Kamu Hari Ini?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ketuk pilihan mood untuk melihat tips kesehatan',
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
          const SizedBox(height: AppSizes.space12),
          const Divider(height: 1, color: Color(0xFFF3EEF5)),
          const SizedBox(height: AppSizes.space16),

          // Mood Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (index) {
                final m = _moods[index];
                final isSelected = _selectedMood == index;

                return InkWell(
                  onTap: () => setState(() => _selectedMood = index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 50,
                    height: 68,
                    decoration: BoxDecoration(
                      color: m['bg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2.0)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          m['icon'] as String,
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['name'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSizes.space16),

          // Dynamic Mood Tip Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.space14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F9),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: const Color(0xFFFFDDE6), width: 1.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saran Medis Mood: ${activeMood['name']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeMood['tip'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space20),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenFullRecord?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFFFB8CC)),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.space14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Catatan Lengkap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveQuickMood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.space14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Mood',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

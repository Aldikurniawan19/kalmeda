import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';
import 'package:menstracker/features/record/domain/repositories/record_repository.dart';

/// Interactive modal bottom sheet displaying full chronological history of cycle and symptom records.
class CycleHistoryBottomSheet extends StatelessWidget {
  final VoidCallback? onAddRecord;

  const CycleHistoryBottomSheet({super.key, this.onAddRecord});

  static Future<void> show(BuildContext context, {VoidCallback? onAddRecord}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CycleHistoryBottomSheet(onAddRecord: onAddRecord),
    );
  }

  static const _flowLabels = [
    'Tidak Ada',
    'Flek / Bercak',
    'Darah Ringan',
    'Darah Sedang',
    'Darah Deras',
  ];

  static const _moodLabels = [
    'Bahagia',
    'Tenang',
    'Sedih',
    'Lelah',
    'Nyeri',
    'Kembung',
  ];

  static const _symptomLabels = [
    'Kram Perut',
    'Kembung',
    'Kelelahan',
    'Sakit Kepala',
    'Sakit Pinggang',
    'Payudara Nyeri',
    'Jerawat',
    'Nafsu Makan',
  ];

  @override
  Widget build(BuildContext context) {
    final RecordRepository recordRepository = RecordRepositoryImpl();

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
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/icon/iconRiwayat.png',
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
                        'Riwayat Catatan Siklus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daftar lengkap catatan menstruasi, mood, dan gejala',
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

          // Stream of Records List
          Expanded(
            child: StreamBuilder<List<CycleRecordModel>>(
              stream: recordRepository.getRecordsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSizes.space32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/Komponen/komponenKalender.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSizes.space16),
                        const Text(
                          'Belum Ada Catatan Tersimpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.space6),
                        const Text(
                          'Catat kondisi tubuh, aliran haid, dan mood harianmu untuk melihat riwayat kesehatan di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSizes.space20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onAddRecord?.call();
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Buat Catatan Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space20,
                    vertical: AppSizes.space14,
                  ),
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.space12),
                  itemBuilder: (context, index) {
                    final item = records[index];
                    final flowText =
                        _flowLabels[item.flowIndex.clamp(
                          0,
                          _flowLabels.length - 1,
                        )];
                    final moodText =
                        _moodLabels[item.moodIndex.clamp(
                          0,
                          _moodLabels.length - 1,
                        )];

                    return Container(
                      padding: const EdgeInsets.all(AppSizes.space14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        border: Border.all(
                          color: const Color(0xFFF3EDF5),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header: Date & Flow Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormatter.format(
                                  item.date,
                                  includeDayName: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F4),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  flowText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.space10),

                          // Badges Row: Mood & Water
                          Row(
                            children: [
                              _MiniBadge(
                                icon: Icons.mood_rounded,
                                label: moodText,
                                color: const Color(0xFF8E24AA),
                              ),
                              const SizedBox(width: AppSizes.space8),
                              _MiniBadge(
                                icon: Icons.local_drink_rounded,
                                label: '${item.waterCups} Gelas',
                                color: const Color(0xFF0288D1),
                              ),
                            ],
                          ),

                          // Symptoms Chips (if any)
                          if (item.symptoms.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.space10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.symptoms.map((sIdx) {
                                final sName =
                                    (sIdx >= 0 && sIdx < _symptomLabels.length)
                                    ? _symptomLabels[sIdx]
                                    : 'Gejala';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3F8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Notes (if any)
                          if (item.notes.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.space8),
                            Text(
                              '"${item.notes}"',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/home/data/models/period_history_episode.dart';
import 'package:menstracker/features/home/data/services/confirmed_period_storage.dart';
import 'package:menstracker/features/home/presentation/controllers/home_controller.dart';
import 'package:menstracker/features/home/presentation/widgets/period_history_calendar_card.dart';
import 'package:menstracker/features/home/presentation/widgets/period_history_card.dart';
import 'package:menstracker/features/home/presentation/widgets/period_history_detail_bottom_sheet.dart';
import 'package:menstracker/features/home/presentation/widgets/period_history_empty_state.dart';
import 'package:menstracker/features/home/presentation/widgets/period_history_summary_card.dart';
import 'package:menstracker/features/record/data/models/cycle_record_model.dart';
import 'package:menstracker/features/record/data/repositories/record_repository_impl.dart';
import 'package:menstracker/features/record/domain/repositories/record_repository.dart';

/// Full-screen display of menstrual history.
/// Dynamically adjusts the "X Bulan Terakhir" label and month boundary to match
/// the actual number of months detected in storage (up to a maximum of 6 months).
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class PeriodHistoryScreen extends StatefulWidget {
  final VoidCallback? onAddRecord;
  final ValueChanged<int>? onNavigateTab;

  const PeriodHistoryScreen({
    super.key,
    this.onAddRecord,
    this.onNavigateTab,
  });

  /// Navigates to [PeriodHistoryScreen] with smooth push transition.
  static Future<void> open(
    BuildContext context, {
    VoidCallback? onAddRecord,
    ValueChanged<int>? onNavigateTab,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeriodHistoryScreen(
          onAddRecord: onAddRecord,
          onNavigateTab: onNavigateTab,
        ),
      ),
    );
  }

  @override
  State<PeriodHistoryScreen> createState() => _PeriodHistoryScreenState();
}

class _PeriodHistoryScreenState extends State<PeriodHistoryScreen> {
  final RecordRepository _recordRepository = RecordRepositoryImpl();

  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _selectedDate;
  bool _hasInitializedMonth = false;
  List<ConfirmedPeriodEntry> _confirmedPeriods = [];

  @override
  void initState() {
    super.initState();
    _loadConfirmedPeriods();
    // Silently synchronize full cloud records into local offline cache
    _recordRepository.syncAllFromCloud().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
  }

  Future<void> _loadConfirmedPeriods() async {
    final uid = HomeController().userProfile?.uid ?? '';
    final list = await ConfirmedPeriodStorage.loadPeriods(uid);
    if (mounted) {
      setState(() {
        _confirmedPeriods = list;
      });
    }
  }

  void _handleAddRecord() {
    Navigator.of(context).pop();
    if (widget.onAddRecord != null) {
      widget.onAddRecord!();
    } else if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(2); // Navigate to Record tab
    }
  }

  void _goToPrevMonth(DateTime earliestMonth) {
    final prevMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month - 1,
      1,
    );
    if (!prevMonth.isBefore(earliestMonth)) {
      setState(() {
        _displayedMonth = prevMonth;
        _selectedDate = null;
      });
    }
  }

  void _goToNextMonth(DateTime latestMonth) {
    final nextMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      1,
    );
    if (!nextMonth.isAfter(latestMonth)) {
      setState(() {
        _displayedMonth = nextMonth;
        _selectedDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<List<CycleRecordModel>>(
      stream: _recordRepository.getRecordsStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        final allRecords = snapshot.data ?? [];
        final profile = HomeController().userProfile?.cycleProfile;

        // Extract real period episodes from user confirmations & system predictions
        final allEpisodes = PeriodHistoryEpisode.extractEpisodes(
          records: allRecords,
          profile: profile,
          confirmedPeriods: _confirmedPeriods,
        );

        // 1. Detect all unique calendar months containing period records from storage
        final detectedMonthKeys = <DateTime>{};
        for (final ep in allEpisodes) {
          detectedMonthKeys.add(DateTime(ep.startDate.year, ep.startDate.month, 1));
          detectedMonthKeys.add(DateTime(ep.endDate.year, ep.endDate.month, 1));
        }
        for (final r in allRecords) {
          if (r.flowIndex > 0) {
            detectedMonthKeys.add(DateTime(r.date.year, r.date.month, 1));
          }
        }

        // Sort chronologically ascending
        final sortedDetectedMonths = detectedMonthKeys.toList()
          ..sort((a, b) => a.compareTo(b));

        // Dynamically adjust to the number of detected months from storage, capped at max 6:
        // - If > 6 months, show at most 6
        // - If < 6 months, show however many there are (e.g. 1, 2, 3...)
        final rawDetectedCount = sortedDetectedMonths.length;
        final int detectedMonthsCount =
            rawDetectedCount > 6 ? 6 : rawDetectedCount;

        // Subtitle dynamic text: e.g. "1 Bulan Terakhir", "2 Bulan Terakhir", max "6 Bulan Terakhir"
        final subtitleText = detectedMonthsCount > 0
            ? '$detectedMonthsCount Bulan Terakhir'
            : 'Belum Ada Data';

        // Select the 6 most recent detected months from storage
        final effectiveMonths = sortedDetectedMonths.length > 6
            ? sortedDetectedMonths.sublist(sortedDetectedMonths.length - 6)
            : sortedDetectedMonths;

        final DateTime earliestMonth;
        final DateTime latestMonth;
        if (effectiveMonths.isNotEmpty) {
          earliestMonth = effectiveMonths.first;
          latestMonth = effectiveMonths.last;
        } else {
          earliestMonth = DateTime(now.year, now.month, 1);
          latestMonth = DateTime(now.year, now.month, 1);
        }

        // On first data load, default displayed month to the most recent month with data
        if (!_hasInitializedMonth && effectiveMonths.isNotEmpty) {
          _displayedMonth = latestMonth;
          _hasInitializedMonth = true;
        }

        // Ensure displayed month is clamped within valid detected months range
        if (_displayedMonth.isAfter(latestMonth)) {
          _displayedMonth = latestMonth;
        } else if (_displayedMonth.isBefore(earliestMonth)) {
          _displayedMonth = earliestMonth;
        }

        final hasPrevMonth = _displayedMonth.isAfter(earliestMonth);
        final hasNextMonth = _displayedMonth.isBefore(latestMonth);

        // Episodes that touch the currently viewed month
        final monthEpisodes = allEpisodes.where((ep) {
          final start = ep.startDate;
          final end = ep.endDate;
          final isSameStartMonth =
              start.year == _displayedMonth.year &&
              start.month == _displayedMonth.month;
          final isSameEndMonth =
              end.year == _displayedMonth.year &&
              end.month == _displayedMonth.month;
          return isSameStartMonth || isSameEndMonth;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Haid Sebelumnya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Catat Menstruasi',
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _handleAddRecord,
              ),
              const SizedBox(width: AppSizes.space8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFF0ECF3)),
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : allEpisodes.isEmpty
                  ? SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: PeriodHistoryEmptyState(
                        onAddRecord: _handleAddRecord,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space20,
                        vertical: AppSizes.space16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Clinical Aggregated Summary Card (Adjusted to detected months)
                          PeriodHistorySummaryCard(
                            episodes: allEpisodes,
                            monthsCount: detectedMonthsCount,
                          ),
                          const SizedBox(height: AppSizes.space16),

                          // 2. Month Calendar Card with Left & Right Arrows for month switching
                          PeriodHistoryCalendarCard(
                            displayedMonth: _displayedMonth,
                            monthEpisodes: monthEpisodes,
                            records: allRecords,
                            selectedDate: _selectedDate,
                            hasPrevMonth: hasPrevMonth,
                            hasNextMonth: hasNextMonth,
                            onPrevMonth: () => _goToPrevMonth(earliestMonth),
                            onNextMonth: () => _goToNextMonth(latestMonth),
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate =
                                    _selectedDate == date ? null : date;
                              });
                            },
                          ),
                          const SizedBox(height: AppSizes.space20),

                          // 3. Section Title & Details Below the Calendar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Rincian Siklus ${DateFormatter.formatMonthYear(_displayedMonth)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.space8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: monthEpisodes.isNotEmpty
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFF5F3F6),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusCircular,
                                  ),
                                ),
                                child: Text(
                                  monthEpisodes.isNotEmpty
                                      ? '${monthEpisodes.length} Periode'
                                      : '0 Periode',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: monthEpisodes.isNotEmpty
                                        ? const Color(0xFF2E7D32)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.space12),

                          // 4. Period Cards for this Month or Informative Empty Card
                          if (monthEpisodes.isNotEmpty) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: monthEpisodes.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSizes.space12),
                              itemBuilder: (context, index) {
                                final ep = monthEpisodes[index];
                                return PeriodHistoryCard(
                                  episode: ep,
                                  onDetailTap: () =>
                                      PeriodHistoryDetailBottomSheet.show(
                                    context,
                                    episode: ep,
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            // Month has no recorded period: clean informative note
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.space16,
                                vertical: AppSizes.space20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFF0ECF3),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSizes.space10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 22,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.space10),
                                  Text(
                                    'Tidak Ada Catatan Menstruasi di Bulan ${DateFormatter.formatMonthYear(_displayedMonth)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.space4),
                                  const Text(
                                    'Menampilkan data nyata yang pernah Anda catat pada bulan ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSizes.space20),

                          // 5. Clinical Recommendation Callout
                          Container(
                            padding: const EdgeInsets.all(AppSizes.space14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F7FA),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                              border: Border.all(
                                color: const Color(0xFFEDE8F2),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.space6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.space10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Konsultasi Medis Kalmeda',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        detectedMonthsCount > 1
                                            ? 'Gunakan tanda panah kiri & kanan di kalender untuk melihat riwayat menstruasi pada bulan-bulan lainnya dalam $detectedMonthsCount bulan terakhir.'
                                            : 'Menampilkan riwayat menstruasi yang tercatat di penyimpanan. Catat terus siklus haidmu secara berkala untuk memantau keteraturan siklus.',
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
                          const SizedBox(height: AppSizes.space32),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

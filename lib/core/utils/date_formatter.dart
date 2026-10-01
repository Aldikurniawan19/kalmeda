/// Helper utility for Indonesian date formatting and calendar calculations.
class DateFormatter {
  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> shortDayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  /// Formats date into standard Indonesian format, e.g. "12 Mei 2026" or "Selasa, 12 Mei 2026".
  static String format(
    DateTime date, {
    bool includeDayName = false,
    bool shortMonth = false,
  }) {
    final month = shortMonth ? shortMonthNames[date.month - 1] : monthNames[date.month - 1];
    final dayStr = '${date.day} $month ${date.year}';
    if (includeDayName) {
      final dayName = dayNames[date.weekday - 1];
      return '$dayName, $dayStr';
    }
    return dayStr;
  }

  /// Formats date to "Bulan Tahun", e.g. "Mei 2026".
  static String formatMonthYear(DateTime date) {
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  /// Formats date to short month + day, e.g. "12 Mei".
  static String formatDayMonth(DateTime date) {
    return '${date.day} ${monthNames[date.month - 1]}';
  }

  /// Checks if two dates represent the exact same calendar day.
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Strips time components and returns pure calendar date at midnight.
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

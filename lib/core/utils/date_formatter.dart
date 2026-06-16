import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat _dayMonthYearTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dayMonthYear.format(date);

  static String formatDateTime(DateTime date) => _dayMonthYearTime.format(date);

  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static String formatIso(DateTime date) => _isoDate.format(date);

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      // Try common formats
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd-MM-yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd MMM yyyy'),
      ];
      for (final format in formats) {
        try {
          return format.parse(dateString);
        } catch (_) {
          continue;
        }
      }
      return null;
    }
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

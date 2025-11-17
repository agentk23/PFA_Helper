import 'package:intl/intl.dart';
import 'error_handler.dart';

/// Safe date and number formatters with error handling
class SafeFormatters {
  /// Safely format date with fallback
  static String formatDate(DateTime date, {String pattern = 'dd.MM.yyyy'}) {
    try {
      return DateFormat(pattern).format(date);
    } catch (e, stackTrace) {
      ErrorHandler.logError('formatDate', e, stackTrace);
      // Fallback to simple formatting
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  /// Safely format date with month name
  static String formatDateWithMonth(DateTime date, {bool includeYear = true}) {
    try {
      final pattern = includeYear ? 'MMMM yyyy' : 'MMMM';
      return DateFormat(pattern).format(date);
    } catch (e, stackTrace) {
      ErrorHandler.logError('formatDateWithMonth', e, stackTrace);
      // Fallback to month number
      final months = [
        'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
        'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie'
      ];
      final monthName = months[date.month - 1];
      return includeYear ? '$monthName ${date.year}' : monthName;
    }
  }

  /// Safely format currency
  static String formatCurrency(double amount, {String symbol = 'RON'}) {
    try {
      return '${amount.toStringAsFixed(2)} $symbol';
    } catch (e, stackTrace) {
      ErrorHandler.logError('formatCurrency', e, stackTrace);
      return '0.00 $symbol';
    }
  }

  /// Safely format percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    try {
      return '${value.toStringAsFixed(decimals)}%';
    } catch (e, stackTrace) {
      ErrorHandler.logError('formatPercentage', e, stackTrace);
      return '0%';
    }
  }

  /// Safely parse double from string
  static double? parseDouble(String value) {
    try {
      return double.parse(value.trim().replaceAll(',', '.'));
    } catch (e, stackTrace) {
      ErrorHandler.logError('parseDouble', e, stackTrace);
      return null;
    }
  }

  /// Safely parse int from string
  static int? parseInt(String value) {
    try {
      return int.parse(value.trim());
    } catch (e, stackTrace) {
      ErrorHandler.logError('parseInt', e, stackTrace);
      return null;
    }
  }

  /// Safely format number with thousands separator
  static String formatNumber(num value, {int decimals = 0}) {
    try {
      final pattern = '#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}';
      final formatter = NumberFormat(pattern, 'ro');
      return formatter.format(value);
    } catch (e, stackTrace) {
      ErrorHandler.logError('formatNumber', e, stackTrace);
      return value.toStringAsFixed(decimals);
    }
  }

  /// Get Romanian month names
  static List<String> get romanianMonths => [
        'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
        'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie'
      ];

  /// Get month name in Romanian
  static String getMonthName(int month) {
    if (month < 1 || month > 12) return 'Necunoscut';
    return romanianMonths[month - 1];
  }
}

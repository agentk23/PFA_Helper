import 'package:intl/intl.dart';

/// Safe date and number formatters with Romanian locale
class SafeFormatters {
  static final currencyFormat = NumberFormat.currency(
    locale: 'ro_RO',
    symbol: 'RON',
    decimalDigits: 2,
  );

  static final dateFormat = DateFormat('dd.MM.yyyy', 'ro_RO');
  static final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'ro_RO');
  static final monthYearFormat = DateFormat('MMMM yyyy', 'ro_RO');

  static String formatCurrency(double amount) {
    try {
      return currencyFormat.format(amount);
    } catch (e) {
      return '${amount.toStringAsFixed(2)} RON';
    }
  }

  static String formatDate(DateTime date) {
    try {
      return dateFormat.format(date);
    } catch (e) {
      return date.toString().split(' ')[0];
    }
  }

  static String formatDateTime(DateTime dateTime) {
    try {
      return dateTimeFormat.format(dateTime);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String formatMonthYear(DateTime date) {
    try {
      return monthYearFormat.format(date);
    } catch (e) {
      return '${date.month}/${date.year}';
    }
  }
}

import 'package:intl/intl.dart';

/// Utility helper functions
class Helpers {
  Helpers._();

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatCurrency(double amount, String currency) {
    final formatter = NumberFormat('#,##0.00', 'en_IN');
    return '$currency${formatter.format(amount)}';
  }

  static String generateOrderNumber() {
    final now = DateTime.now();
    final prefix = 'ORD';
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final ms = now.millisecondsSinceEpoch % 100000;
    return '$prefix$year$month${ms.toString().padLeft(5, '0')}';
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static String toIso(DateTime date) {
    return date.toIso8601String();
  }

  /// Checks if a delivery date is overdue
  static bool isOverdue(String? deliveryDateStr) {
    if (deliveryDateStr == null) return false;
    final date = parseDate(deliveryDateStr);
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }
}

import 'package:intl/intl.dart';

/// Utility class for formatting Indian currency (INR)
class CurrencyFormatter {
  /// Formats a number as Indian Rupees with proper formatting
  /// Example: 1234567.89 -> ₹12,34,567.89
  static String formatINR(double amount, {int decimals = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    );
    return formatter.format(amount);
  }

  /// Formats a number in compact Indian format (Lakhs/Crores)
  /// Example: 1000000 -> ₹10L, 10000000 -> ₹1Cr
  static String formatINRCompact(double amount) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final prefix = isNegative ? '-₹' : '₹';

    if (absAmount >= 10000000) {
      // Crores (1 Crore = 10 Million)
      final crores = absAmount / 10000000;
      return '$prefix${crores.toStringAsFixed(2)}Cr';
    } else if (absAmount >= 100000) {
      // Lakhs (1 Lakh = 100 Thousand)
      final lakhs = absAmount / 100000;
      return '$prefix${lakhs.toStringAsFixed(2)}L';
    } else if (absAmount >= 1000) {
      // Thousands
      final thousands = absAmount / 1000;
      return '$prefix${thousands.toStringAsFixed(2)}K';
    } else {
      return '$prefix${absAmount.toStringAsFixed(2)}';
    }
  }

  /// Formats without currency symbol
  /// Example: 1234567.89 -> 12,34,567.89
  static String formatNumber(double amount, {int decimals = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimals,
    );
    return formatter.format(amount).trim();
  }

  /// Formats percentage with + or - sign
  /// Example: 2.5 -> +2.50%, -1.5 -> -1.50%
  static String formatPercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }

  /// Converts amount to words (Indian numbering)
  /// Example: 150000 -> "1.5 Lakh"
  static String toWords(double amount) {
    if (amount >= 10000000) {
      final crores = amount / 10000000;
      return '${crores.toStringAsFixed(1)} Crore${crores > 1 ? 's' : ''}';
    } else if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '${lakhs.toStringAsFixed(1)} Lakh${lakhs > 1 ? 's' : ''}';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(1)} Thousand';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

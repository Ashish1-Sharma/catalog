class CurrencyUtils {
  static String formatAmount(double? amount, {String currency = '₹'}) {
    if (amount == null) return '$currency 0.00';
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

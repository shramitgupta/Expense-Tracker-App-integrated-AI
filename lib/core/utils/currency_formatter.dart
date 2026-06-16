import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 1,
  );

  static String format(double amount) => _inrFormat.format(amount);

  static String formatCompact(double amount) => _compactFormat.format(amount);

  static String formatWithSign(double amount) {
    final formatted = _inrFormat.format(amount.abs());
    return amount < 0 ? '-$formatted' : formatted;
  }
}

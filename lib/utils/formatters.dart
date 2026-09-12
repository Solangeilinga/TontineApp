import 'package:intl/intl.dart';

class Formatters {
  static String amount(double amount, [String currency = 'XOF']) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }

  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String phone(String phone) {
    if (phone.startsWith('+226') && phone.length == 12) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 6)} ${phone.substring(6, 8)} ${phone.substring(8, 10)} ${phone.substring(10)}';
    }
    return phone;
  }
}

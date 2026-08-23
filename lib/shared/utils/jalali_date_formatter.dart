import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Formats a timestamp as a Jalali calendar date with Persian digits.
///
/// Example: `۱۴۰۵/۰۴/۱۰`
String formatJalaliDate(DateTime dateTime) {
  final jalali = Jalali.fromDateTime(dateTime.toLocal());
  final year = jalali.year.toString().padLeft(4, '0');
  final month = jalali.month.toString().padLeft(2, '0');
  final day = jalali.day.toString().padLeft(2, '0');
  return '$year/$month/$day'.toPersianDigit();
}

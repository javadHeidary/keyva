import 'package:shamsi_date/shamsi_date.dart';

String formatPasswordHistoryCopiedAt(DateTime dateTime) {
  final local = dateTime.toLocal();
  final jalali = Jalali.fromDateTime(local);
  final y = jalali.year.toString().padLeft(4, '0');
  final m = jalali.month.toString().padLeft(2, '0');
  final d = jalali.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y/$m/$d • $h:$min';
}

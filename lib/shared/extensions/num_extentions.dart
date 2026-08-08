extension PersianNum on num {
  String get toPr {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return toString().replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => persianDigits[int.parse(match.group(0)!)],
    );
  }
}

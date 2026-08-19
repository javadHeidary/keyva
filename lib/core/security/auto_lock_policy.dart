abstract final class AutoLockPolicy {
  static const immediate = Duration.zero;
  static const thirtySeconds = Duration(seconds: 30);
  static const oneMinute = Duration(minutes: 1);
  static const fiveMinutes = Duration(minutes: 5);

  static const values = <Duration>[
    immediate,
    thirtySeconds,
    oneMinute,
    fiveMinutes,
  ];

  static bool isSupported(Duration timeout) => values.contains(timeout);

  static String label(Duration timeout) {
    if (timeout == immediate) {
      return 'فوری';
    }
    if (timeout == thirtySeconds) {
      return '۳۰ ثانیه';
    }
    if (timeout == fiveMinutes) {
      return '۵ دقیقه';
    }
    return '۱ دقیقه';
  }
}

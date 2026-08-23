enum RestoreProgressStage {
  starting,
  validating,
  derivingKey,
  decrypting,
  deserializing,
  preparingAccount,
  creatingAccount,
  unlocking,
  persisting,
  refreshing,
  completed,
  failed,
}

typedef RestoreProgressCallback = void Function(RestoreProgress progress);

class RestoreProgressMessages {
  RestoreProgressMessages._();

  static const starting = 'در حال شروع بازیابی...';
  static const validating = 'در حال بررسی اطلاعات...';
  static const derivingKey = 'در حال آماده‌سازی کلید...';
  static const decrypting = 'در حال رمزگشایی...';
  static const deserializing = 'در حال بررسی اطلاعات...';
  static const preparingAccount = 'در حال آماده‌سازی گاوصندوق...';
  static const creatingAccount = 'در حال ایجاد حساب...';
  static const unlocking = 'در حال آماده‌سازی گاوصندوق...';
  static const persisting = 'در حال ذخیره‌سازی...';
  static const refreshing = 'در حال ذخیره‌سازی...';
  static const completed = 'بازیابی کامل شد';
  static const stayOpen =
      'لطفاً تا پایان بازیابی، برنامه را نبندید و از آن خارج نشوید.';
}

class RestoreProgress {
  RestoreProgress({
    required this.stage,
    required int percent,
    required this.message,
  }) : percent = percent.clamp(0, 100);

  final RestoreProgressStage stage;
  final int percent;
  final String message;

  bool get isCompleted => stage == RestoreProgressStage.completed;

  static RestoreProgress decryptStarting() => RestoreProgress(
    stage: RestoreProgressStage.starting,
    percent: 0,
    message: RestoreProgressMessages.starting,
  );

  static RestoreProgress decryptValidating() => RestoreProgress(
    stage: RestoreProgressStage.validating,
    percent: 10,
    message: RestoreProgressMessages.validating,
  );

  static RestoreProgress decryptDerivingKey() => RestoreProgress(
    stage: RestoreProgressStage.derivingKey,
    percent: 20,
    message: RestoreProgressMessages.derivingKey,
  );

  static RestoreProgress decryptDecrypting() => RestoreProgress(
    stage: RestoreProgressStage.decrypting,
    percent: 50,
    message: RestoreProgressMessages.decrypting,
  );

  static RestoreProgress decryptDeserializing() => RestoreProgress(
    stage: RestoreProgressStage.deserializing,
    percent: 75,
    message: RestoreProgressMessages.deserializing,
  );

  static RestoreProgress decryptCompleted() => RestoreProgress(
    stage: RestoreProgressStage.completed,
    percent: 100,
    message: RestoreProgressMessages.completed,
  );

  static RestoreProgress replacePersisting() => RestoreProgress(
    stage: RestoreProgressStage.persisting,
    percent: 40,
    message: RestoreProgressMessages.persisting,
  );

  static RestoreProgress replaceRefreshing() => RestoreProgress(
    stage: RestoreProgressStage.refreshing,
    percent: 85,
    message: RestoreProgressMessages.refreshing,
  );

  static RestoreProgress newAccountPreparing() => RestoreProgress(
    stage: RestoreProgressStage.preparingAccount,
    percent: 10,
    message: RestoreProgressMessages.preparingAccount,
  );

  static RestoreProgress newAccountCreating() => RestoreProgress(
    stage: RestoreProgressStage.creatingAccount,
    percent: 25,
    message: RestoreProgressMessages.creatingAccount,
  );

  static RestoreProgress newAccountUnlocking() => RestoreProgress(
    stage: RestoreProgressStage.unlocking,
    percent: 55,
    message: RestoreProgressMessages.unlocking,
  );

  static RestoreProgress newAccountPersisting() => RestoreProgress(
    stage: RestoreProgressStage.persisting,
    percent: 85,
    message: RestoreProgressMessages.persisting,
  );

  static RestoreProgress commitCompleted() => RestoreProgress(
    stage: RestoreProgressStage.completed,
    percent: 100,
    message: RestoreProgressMessages.completed,
  );
}

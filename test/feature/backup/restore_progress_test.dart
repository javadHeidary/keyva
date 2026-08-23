import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/backup/model/restore_progress.dart';

void main() {
  test('percent is clamped between 0 and 100', () {
    final low = RestoreProgress(
      stage: RestoreProgressStage.starting,
      percent: -20,
      message: RestoreProgressMessages.starting,
    );
    final high = RestoreProgress(
      stage: RestoreProgressStage.completed,
      percent: 140,
      message: RestoreProgressMessages.completed,
    );
    expect(low.percent, 0);
    expect(high.percent, 100);
    expect(high.isCompleted, isTrue);
  });
}

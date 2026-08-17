import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';

void main() {
  test('Success holds data and reports isSuccess', () {
    const result = Success<int>(42);

    expect(result.isSuccess, isTrue);
    expect(result.isFailure, isFalse);
    expect(result.data, 42);
  });

  test('FailureResult holds AppFailure and reports isFailure', () {
    const failure = DatabaseFailure();
    const result = FailureResult<int>(failure);

    expect(result.isSuccess, isFalse);
    expect(result.isFailure, isTrue);
    expect(result.failure, same(failure));
  });
}

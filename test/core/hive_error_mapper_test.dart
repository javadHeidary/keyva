import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:keyva/core/database/hive_error_mapper.dart';
import 'package:keyva/core/exceptions/app_failure.dart';

void main() {
  test('maps HiveError to DatabaseFailure without leaking the original message', () {
    const secret = 'C:/users/vault/secret-path.hive';
    final mapped = HiveErrorMapper.map(HiveError(secret));

    expect(mapped, isA<DatabaseFailure>());
    expect(mapped.message, 'Database operation failed');
    expect(mapped.message, isNot(contains(secret)));
    expect(mapped.message, isNot(contains('HiveError')));
  });

  test('passes AppFailure through unchanged', () {
    const failure = DatabaseFailure();
    expect(HiveErrorMapper.map(failure), same(failure));
  });

  test('maps unexpected errors to UnknownFailure without leaking details', () {
    const secret = 'wrapped-vault-key-bytes';
    final mapped = HiveErrorMapper.map(StateError(secret));

    expect(mapped, isA<UnknownFailure>());
    expect(mapped.message, 'An unexpected error occurred');
    expect(mapped.message, isNot(contains(secret)));
  });
}

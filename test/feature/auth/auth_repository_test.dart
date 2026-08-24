import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/constants/database_constants.dart';
import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/crypto_service_impl.dart';
import 'package:keyva/core/crypto/key_management_service_impl.dart';
import 'package:keyva/core/database/hive_database.dart';
import 'package:keyva/core/database/hive_user_data_source.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';
import 'package:keyva/core/database/user_data_source.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/core/session/session_service_impl.dart';
import 'package:keyva/feature/auth/repository/auth_repository.dart';
import 'package:keyva/feature/auth/repository/auth_repository_impl.dart';

void main() {
  late Directory tempDir;
  HiveDatabase? database;
  late UserDataSource users;
  late CryptoService crypto;
  late SessionService session;
  late AuthRepository auth;

  const kdfTimeout = Timeout(Duration(minutes: 2));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('keyva_auth_');
    database = await HiveDatabase.initialize(testDatabasePath: tempDir.path);
    users = HiveUserDataSource(database!);
    crypto = CryptoServiceImpl();
    session = SessionServiceImpl();
    auth = AuthRepositoryImpl(
      users: users,
      crypto: crypto,
      keys: KeyManagementServiceImpl(crypto),
      session: session,
      database: database!,
    );
  });

  tearDown(() async {
    await database?.close();
    database = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'createAccount persists a wrapped user and does not open a session',
    () async {
      const password = 'correct-master-password';
      final created = _expectSuccess(
        await auth.createAccount(username: 'علی', masterPassword: password),
      );

      expect(_isUuidV4(created.id), isTrue);
      expect(created.username, 'علی');
      expect(created.kdfSalt.length, SecurityConstants.saltLength);
      expect(created.kdfParameters.algorithm, SecurityConstants.kdfAlgorithm);
      expect(created.kdfParameters.memoryCost, SecurityConstants.kdfMemoryCost);
      expect(created.kdfParameters.timeCost, SecurityConstants.kdfTimeCost);
      expect(
        created.kdfParameters.parallelism,
        SecurityConstants.kdfParallelism,
      );
      expect(
        created.kdfParameters.outputLength,
        SecurityConstants.kdfOutputLength,
      );
      expect(
        created.wrappedVaultKey.version,
        SecurityConstants.wrappedKeyVersion,
      );
      expect(
        created.wrappedVaultKey.nonce.length,
        SecurityConstants.nonceLength,
      );
      expect(
        created.wrappedVaultKey.authenticationTag.length,
        SecurityConstants.authenticationTagLength,
      );
      expect(created.wrappedVaultKey.ciphertext, isNotEmpty);
      expect(session.isAuthenticated, isFalse);

      final loaded = _expectSuccess(await users.findById(created.id));
      expect(loaded, isNotNull);
      expect(loaded!.id, created.id);
      expect(_recordContainsPassword(loaded, password), isFalse);

      final derived = _expectSuccess(
        await crypto.deriveKey(
          masterPassword: password,
          salt: loaded.kdfSalt,
          parameters: loaded.kdfParameters,
        ),
      );
      expect(derived, isNot(loaded.kdfSalt));
      expect(derived, isNot(loaded.wrappedVaultKey.ciphertext));
      expect(derived, isNot(loaded.wrappedVaultKey.nonce));
      expect(derived, isNot(loaded.wrappedVaultKey.authenticationTag));
    },
    timeout: kdfTimeout,
  );

  test('createAccount generates unique user ids and salts', () async {
    final first = _expectSuccess(
      await auth.createAccount(
        username: 'اول',
        masterPassword: 'password-one-long',
      ),
    );
    final second = _expectSuccess(
      await auth.createAccount(
        username: 'دوم',
        masterPassword: 'password-two-long',
      ),
    );

    expect(first.id, isNot(second.id));
    expect(first.kdfSalt, isNot(second.kdfSalt));
  }, timeout: kdfTimeout);

  test(
    'correct master password authenticates and creates a session',
    () async {
      const password = 'correct-master-password';
      final created = _expectSuccess(
        await auth.createAccount(username: 'علی', masterPassword: password),
      );

      final authenticated = _expectSuccess(
        await auth.authenticate(userId: created.id, masterPassword: password),
      );

      expect(authenticated.id, created.id);
      expect(session.isAuthenticated, isTrue);
      expect(session.current!.userId, created.id);
      expect(session.current!.username, 'علی');
      expect(session.vaultKey, isNotNull);
      expect(session.vaultKey!.length, SecurityConstants.vaultKeyLength);
      expect(session.vaultKey, isNot(created.wrappedVaultKey.ciphertext));
      expect(
        database!.appSettings.get(HiveSettingsKeys.activeUserId),
        created.id,
      );
    },
    timeout: kdfTimeout,
  );

  test(
    'incorrect master password fails closed without a session',
    () async {
      final created = _expectSuccess(
        await auth.createAccount(
          username: 'علی',
          masterPassword: 'correct-master-password',
        ),
      );

      final result = await auth.authenticate(
        userId: created.id,
        masterPassword: 'wrong-master-password',
      );

      _expectAuthenticationFailure(result);
      expect(session.isAuthenticated, isFalse);
      expect(session.current, isNull);
      expect(session.vaultKey, isNull);
    },
    timeout: kdfTimeout,
  );

  test('unknown user id fails closed without a session', () async {
    final result = await auth.authenticate(
      userId: '00000000-0000-4000-8000-000000000000',
      masterPassword: 'any-password',
    );

    _expectAuthenticationFailure(result);
    expect(session.isAuthenticated, isFalse);
  }, timeout: kdfTimeout);

  test(
    'corrupted wrapped vault key fails closed without a session',
    () async {
      const password = 'correct-master-password';
      final created = _expectSuccess(
        await auth.createAccount(username: 'علی', masterPassword: password),
      );

      final tamperedCiphertext = Uint8List.fromList(
        created.wrappedVaultKey.ciphertext,
      );
      tamperedCiphertext[0] = tamperedCiphertext[0] ^ 0xFF;
      await users.update(
        UserRecord(
          id: created.id,
          username: created.username,
          createdAt: created.createdAt,
          updatedAt: created.updatedAt,
          kdfSalt: created.kdfSalt,
          kdfParameters: created.kdfParameters,
          wrappedVaultKey: WrappedVaultKey(
            version: created.wrappedVaultKey.version,
            nonce: created.wrappedVaultKey.nonce,
            ciphertext: tamperedCiphertext,
            authenticationTag: created.wrappedVaultKey.authenticationTag,
          ),
          securitySettings: created.securitySettings,
        ),
      );

      final result = await auth.authenticate(
        userId: created.id,
        masterPassword: password,
      );

      _expectAuthenticationFailure(result);
      expect(session.isAuthenticated, isFalse);
      expect(session.current, isNull);
    },
    timeout: kdfTimeout,
  );

  test('failed authentication clears a previous session', () async {
    const password = 'correct-master-password';
    final created = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: password),
    );
    _expectSuccess(
      await auth.authenticate(userId: created.id, masterPassword: password),
    );
    expect(session.isAuthenticated, isTrue);

    _expectAuthenticationFailure(
      await auth.authenticate(
        userId: created.id,
        masterPassword: 'wrong-master-password',
      ),
    );
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
  }, timeout: kdfTimeout);

  test('logout clears the session and in-memory vault key', () async {
    const password = 'correct-master-password';
    final created = _expectSuccess(
      await auth.createAccount(username: 'علی', masterPassword: password),
    );
    _expectSuccess(
      await auth.authenticate(userId: created.id, masterPassword: password),
    );
    final vaultKey = session.vaultKey!;

    final loggedOut = await auth.logout();
    expect(loggedOut, isA<Success<void>>());
    expect(session.current, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.vaultKey, isNull);
    expect(vaultKey, Uint8List(SecurityConstants.vaultKeyLength));

    final stillThere = _expectSuccess(await users.findById(created.id));
    expect(stillThere, isNotNull);
  }, timeout: kdfTimeout);

  test('hasAnyAccount is false until a user exists', () async {
    expect(_expectSuccess(await auth.hasAnyAccount()), isFalse);
    await users.create(_storedUser(id: 'user-1'));
    expect(_expectSuccess(await auth.hasAnyAccount()), isTrue);
  });

  test('resolveUnlockUserId uses the only stored account', () async {
    _expectAuthenticationFailure(await auth.resolveUnlockUserId());
    await users.create(_storedUser(id: 'user-1'));
    expect(_expectSuccess(await auth.resolveUnlockUserId()), 'user-1');
  });

  test('resolveUnlockUserId prefers the remembered active user', () async {
    await users.create(_storedUser(id: 'user-1'));
    await users.create(_storedUser(id: 'user-2'));
    await database!.appSettings.put(HiveSettingsKeys.activeUserId, 'user-2');
    expect(_expectSuccess(await auth.resolveUnlockUserId()), 'user-2');
  });

  test(
    'resolveUnlockUserId fails closed when multiple accounts have no active id',
    () async {
      await users.create(_storedUser(id: 'user-1'));
      await users.create(_storedUser(id: 'user-2'));
      _expectAuthenticationFailure(await auth.resolveUnlockUserId());
    },
  );

  test(
    'getAccounts returns safe summaries and does not require vault data',
    () async {
      expect(_expectSuccess(await auth.getAccounts()), isEmpty);
      await users.create(_storedUser(id: 'user-a', username: 'علی'));
      await users.create(_storedUser(id: 'user-b', username: 'رضا'));

      final summaries = _expectSuccess(await auth.getAccounts());
      expect(summaries, hasLength(2));
      expect(
        summaries.map((account) => account.id),
        containsAll(['user-a', 'user-b']),
      );
      expect(
        summaries.map((account) => account.username),
        containsAll(['علی', 'رضا']),
      );
      expect(database!.vaults.isEmpty, isTrue);

      final loaded = _expectSuccess(await auth.getAccount('user-b'));
      expect(loaded.id, 'user-b');
      expect(loaded.username, 'رضا');
    },
  );

  test('setPreventScreenshots persists for the authenticated user', () async {
    await users.create(_storedUser(id: 'user-1'));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    expect(
      _expectSuccess(await auth.currentSecuritySettings()).preventScreenshots,
      isFalse,
    );
    _expectSuccess(await auth.setPreventScreenshots(true));
    expect(
      _expectSuccess(
        await users.findById('user-1'),
      )!.securitySettings.preventScreenshots,
      isTrue,
    );
    expect(
      _expectSuccess(await auth.currentSecuritySettings()).preventScreenshots,
      isTrue,
    );

    _expectSuccess(await auth.setPreventScreenshots(false));
    expect(
      _expectSuccess(
        await users.findById('user-1'),
      )!.securitySettings.preventScreenshots,
      isFalse,
    );
  });

  test('setAutoLockTimeout persists and a new repository loads it', () async {
    await users.create(_storedUser(id: 'user-1'));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    expect(
      _expectSuccess(await auth.currentSecuritySettings()).autoLockTimeout,
      const Duration(minutes: 1),
    );
    _expectSuccess(await auth.setAutoLockTimeout(const Duration(seconds: 30)));

    final restarted = AuthRepositoryImpl(
      users: HiveUserDataSource(database!),
      crypto: crypto,
      keys: KeyManagementServiceImpl(crypto),
      session: session,
      database: database!,
    );
    expect(
      _expectSuccess(await restarted.currentSecuritySettings()).autoLockTimeout,
      const Duration(seconds: 30),
    );
    expect(
      _expectSuccess(
        await users.findById('user-1'),
      )!.securitySettings.autoLockTimeout,
      const Duration(seconds: 30),
    );
  });

  test('setAutoLockTimeout rejects a negative duration', () async {
    await users.create(_storedUser(id: 'user-1'));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    final result = await auth.setAutoLockTimeout(const Duration(seconds: -1));
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(
      _expectSuccess(await auth.currentSecuritySettings()).autoLockTimeout,
      const Duration(minutes: 1),
    );
  });

  test(
    'setAutoLockTimeout leaves the previous timeout when update fails',
    () async {
      await users.create(_storedUser(id: 'user-1'));
      session.setAuthenticated(
        userId: 'user-1',
        username: 'علی',
        vaultKey: Uint8List(32),
      );
      _expectSuccess(
        await auth.setAutoLockTimeout(const Duration(seconds: 30)),
      );

      final failingAuth = AuthRepositoryImpl(
        users: _UpdateFailingUsers(users),
        crypto: crypto,
        keys: KeyManagementServiceImpl(crypto),
        session: session,
        database: database!,
      );
      final result = await failingAuth.setAutoLockTimeout(
        const Duration(minutes: 5),
      );
      expect(result, isA<FailureResult<void>>());
      expect(
        _expectSuccess(
          await users.findById('user-1'),
        )!.securitySettings.autoLockTimeout,
        const Duration(seconds: 30),
      );
    },
  );

  test('setPreventScreenshots requires an authenticated session', () async {
    await users.create(_storedUser(id: 'user-1'));
    _expectAuthenticationFailure(await auth.setPreventScreenshots(true));
    expect(
      _expectSuccess(
        await users.findById('user-1'),
      )!.securitySettings.preventScreenshots,
      isFalse,
    );
  });

  test(
    'updateProfile persists username and avatar and refreshes the session',
    () async {
      await users.create(_storedUser(id: 'user-1', username: 'علی'));
      session.setAuthenticated(
        userId: 'user-1',
        username: 'علی',
        vaultKey: Uint8List(32),
      );

      expect(
        _expectSuccess(await auth.currentUser()).avatarId,
        UserRecord.defaultAvatarId,
      );

      _expectSuccess(
        await auth.updateProfile(username: 'رضا', avatarId: 'shield'),
      );

      final loaded = _expectSuccess(await users.findById('user-1'))!;
      expect(loaded.username, 'رضا');
      expect(loaded.avatarId, 'shield');
      expect(session.current!.username, 'رضا');
      expect(session.vaultKey, isNotNull);

      final current = _expectSuccess(await auth.currentUser());
      expect(current.username, 'رضا');
      expect(current.avatarId, 'shield');
    },
  );

  test('updateProfile rejects an empty username', () async {
    await users.create(_storedUser(id: 'user-1'));
    session.setAuthenticated(
      userId: 'user-1',
      username: 'علی',
      vaultKey: Uint8List(32),
    );

    final result = await auth.updateProfile(username: '  ', avatarId: 'star');
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(_expectSuccess(await users.findById('user-1'))!.username, 'علی');
  });

  test('updateProfile requires an authenticated session', () async {
    await users.create(_storedUser(id: 'user-1'));
    _expectAuthenticationFailure(
      await auth.updateProfile(username: 'رضا', avatarId: 'shield'),
    );
  });
}

class _UpdateFailingUsers implements UserDataSource {
  _UpdateFailingUsers(this._inner);

  final UserDataSource _inner;

  @override
  Future<Result<void>> create(UserRecord user) => _inner.create(user);

  @override
  Future<Result<UserRecord?>> findById(String id) => _inner.findById(id);

  @override
  Future<Result<bool>> exists(String id) => _inner.exists(id);

  @override
  Future<Result<List<String>>> listIds() => _inner.listIds();

  @override
  Future<Result<List<UserRecord>>> list() => _inner.list();

  @override
  Future<Result<void>> update(UserRecord user) async {
    return const FailureResult(DatabaseFailure());
  }

  @override
  Future<Result<void>> delete(String id) => _inner.delete(id);
}

UserRecord _storedUser({required String id, String username = 'علی'}) {
  return UserRecord(
    id: id,
    username: username,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    kdfSalt: Uint8List.fromList(List<int>.filled(16, 1)),
    kdfParameters: const KdfParameters(
      algorithm: SecurityConstants.kdfAlgorithm,
      memoryCost: SecurityConstants.kdfMemoryCost,
      timeCost: SecurityConstants.kdfTimeCost,
      parallelism: SecurityConstants.kdfParallelism,
      outputLength: SecurityConstants.kdfOutputLength,
    ),
    wrappedVaultKey: WrappedVaultKey(
      version: SecurityConstants.wrappedKeyVersion,
      nonce: Uint8List.fromList(List<int>.filled(12, 2)),
      ciphertext: Uint8List.fromList(List<int>.filled(48, 3)),
      authenticationTag: Uint8List.fromList(List<int>.filled(16, 4)),
    ),
    securitySettings: SecuritySettings.initial(),
  );
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectAuthenticationFailure(Result<dynamic> result) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<AuthenticationFailure>());
  expect(failure.message, 'Unable to unlock your vault.');
}

bool _isUuidV4(String id) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(id);
}

bool _recordContainsPassword(UserRecord user, String password) {
  if (user.id == password || user.username == password) {
    return true;
  }
  final passwordBytes = Uint8List.fromList(password.codeUnits);
  return _bytesEqual(user.kdfSalt, passwordBytes) ||
      _bytesEqual(user.wrappedVaultKey.nonce, passwordBytes) ||
      _bytesEqual(user.wrappedVaultKey.ciphertext, passwordBytes) ||
      _bytesEqual(user.wrappedVaultKey.authenticationTag, passwordBytes);
}

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

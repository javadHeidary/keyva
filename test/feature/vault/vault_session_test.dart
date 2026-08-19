import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';
import 'package:keyva/feature/vault/session/vault_session_impl.dart';

void main() {
  late VaultSession session;

  final createdAt = DateTime.utc(2026, 6, 1, 8);
  final updatedAt = DateTime.utc(2026, 6, 2, 9);

  LoginItem login({
    String id = 'login-1',
    String password = 'session-secret',
  }) {
    return LoginItem(
      id: id,
      title: 'Mail',
      username: 'vault-user',
      password: password,
      website: 'https://mail.test',
      notes: 'private-note',
      categoryId: 'cat-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card() {
    return BankCardItem(
      id: 'card-1',
      title: 'Primary',
      cardNumber: '6037991234567890',
      cardHolder: 'Ali Reza',
      expiryDate: '12/28',
      cvv: '456',
      bankName: 'Melli',
      notes: null,
      categoryId: 'cat-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note() {
    return SecureNoteItem(
      id: 'note-1',
      title: 'WiFi',
      content: 'building-code-42',
      categoryId: 'cat-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category() {
    return CategoryItem(
      id: 'cat-1',
      name: 'Personal',
      icon: 'home',
      createdAt: createdAt,
    );
  }

  VaultData sampleVault({List<LoginItem>? logins}) {
    return VaultData(
      version: VaultData.currentVersion,
      logins: logins ?? [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: [category()],
    );
  }

  setUp(() {
    session = VaultSessionImpl();
  });

  test('starts locked with no vault data', () {
    expect(session.isUnlocked, isFalse);
    expect(session.vaultData, isNull);
  });

  test('unlock stores vault data and marks the session unlocked', () async {
    final vault = sampleVault();

    _expectSuccess(await session.unlock(vault));

    expect(session.isUnlocked, isTrue);
    expect(session.vaultData, vault);
    expect(session.vaultData!.logins.single.password, 'session-secret');
  });

  test('vault data is accessible only while unlocked', () async {
    expect(session.vaultData, isNull);

    _expectSuccess(await session.unlock(sampleVault()));
    expect(session.vaultData, isNotNull);

    _expectSuccess(await session.lock());
    expect(session.vaultData, isNull);
    expect(session.isUnlocked, isFalse);
  });

  test('lock clears vault data', () async {
    _expectSuccess(await session.unlock(sampleVault()));
    _expectSuccess(await session.lock());

    expect(session.isUnlocked, isFalse);
    expect(session.vaultData, isNull);
  });

  test('locking twice is safe', () async {
    _expectSuccess(await session.lock());
    _expectSuccess(await session.lock());

    expect(session.isUnlocked, isFalse);
    expect(session.vaultData, isNull);
  });

  test('unlock replaces a previously unlocked vault', () async {
    _expectSuccess(await session.unlock(sampleVault(logins: [login()])));
    final replacement = sampleVault(logins: [login(id: 'login-2')]);

    _expectSuccess(await session.unlock(replacement));

    expect(session.isUnlocked, isTrue);
    expect(session.vaultData, replacement);
    expect(session.vaultData!.logins.single.id, 'login-2');
  });

  test('source list mutation cannot change session collections', () async {
    final sourceLogins = [login()];
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: sourceLogins,
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );

    _expectSuccess(await session.unlock(vault));

    sourceLogins.add(login(id: 'login-extra'));

    expect(session.vaultData!.logins, [login()]);
  });

  test('session does not expose mutable collections', () async {
    _expectSuccess(await session.unlock(sampleVault()));

    expect(
      () => session.vaultData!.logins.add(login(id: 'login-extra')),
      throwsUnsupportedError,
    );
    expect(() => session.vaultData!.bankCards.removeAt(0), throwsUnsupportedError);
    expect(() => session.vaultData!.secureNotes.clear(), throwsUnsupportedError);
    expect(
      () => session.vaultData!.categories[0] = category(),
      throwsUnsupportedError,
    );
  });
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

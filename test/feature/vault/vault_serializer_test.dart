import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer_impl.dart';

void main() {
  final serializer = VaultSerializerImpl();
  final createdAt = DateTime.utc(2026, 4, 10, 12, 0, 0);
  final updatedAt = DateTime.utc(2026, 4, 11, 15, 30, 0);

  VaultData emptyVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  LoginItem login({
    String id = 'login-1',
    String? website = 'https://example.com',
    String? notes = 'login-notes',
    String? categoryId = 'cat-1',
  }) {
    return LoginItem(
      id: id,
      title: 'Mailbox',
      username: 'vault-user',
      password: 'super-secret-login',
      website: website,
      notes: notes,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({
    String id = 'card-1',
    String? notes = 'card-notes',
    String? categoryId = 'cat-1',
  }) {
    return BankCardItem(
      id: id,
      title: 'Debit',
      cardNumber: '5022291234567890',
      cardHolder: 'Sara Ahmadi',
      expiryDate: '01/29',
      cvv: '999',
      bankName: 'Pasargad',
      notes: notes,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note({
    String id = 'note-1',
    String? categoryId = 'cat-1',
  }) {
    return SecureNoteItem(
      id: id,
      title: 'Recovery',
      content: 'seed-phrase-must-not-leak',
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category({String id = 'cat-1', String? icon = 'folder'}) {
    return CategoryItem(
      id: id,
      name: 'Personal',
      icon: icon,
      createdAt: createdAt,
    );
  }

  Future<VaultData> roundTrip(VaultData vault) async {
    final bytes = _expectSuccess(await serializer.serialize(vault));
    return _expectSuccess(await serializer.deserialize(bytes));
  }

  test('empty vault round-trips', () async {
    final restored = await roundTrip(emptyVault());
    expect(restored, emptyVault());
  });

  test('one LoginItem round-trips', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    expect(await roundTrip(vault), vault);
  });

  test('multiple LoginItems round-trip', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(), login(id: 'login-2', website: null, notes: null)],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    expect(await roundTrip(vault), vault);
  });

  test('BankCardItem round-trips', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: [card()],
      secureNotes: const [],
      categories: const [],
    );
    expect(await roundTrip(vault), vault);
  });

  test('SecureNoteItem round-trips', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: [note()],
      categories: const [],
    );
    expect(await roundTrip(vault), vault);
  });

  test('CategoryItem round-trips', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: [category()],
    );
    expect(await roundTrip(vault), vault);
  });

  test('mixed vault preserves ids timestamps and category relationships', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: [category()],
    );

    final restored = await roundTrip(vault);
    expect(restored, vault);
    expect(restored.logins.single.id, 'login-1');
    expect(restored.bankCards.single.id, 'card-1');
    expect(restored.secureNotes.single.id, 'note-1');
    expect(restored.categories.single.id, 'cat-1');
    expect(restored.logins.single.categoryId, 'cat-1');
    expect(restored.bankCards.single.categoryId, 'cat-1');
    expect(restored.secureNotes.single.categoryId, 'cat-1');
    expect(restored.logins.single.createdAt, createdAt);
    expect(restored.logins.single.updatedAt, updatedAt);
  });

  test('explicit JSON null for optional fields is preserved', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(website: null, notes: null, categoryId: null)],
      bankCards: [card(notes: null, categoryId: null)],
      secureNotes: [note(categoryId: null)],
      categories: [category(icon: null)],
    );

    final bytes = _expectSuccess(await serializer.serialize(vault));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final loginJson = json['logins'].single as Map<String, dynamic>;
    expect(loginJson.containsKey('website'), isTrue);
    expect(loginJson['website'], isNull);
    expect(loginJson['notes'], isNull);
    expect(loginJson['categoryId'], isNull);
    expect((json['categories'].single as Map)['icon'], isNull);

    expect(await roundTrip(vault), vault);
  });

  test('serializing the same vault twice is deterministic', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: [category()],
    );

    final first = _expectSuccess(await serializer.serialize(vault));
    final second = _expectSuccess(await serializer.serialize(vault));
    expect(first, second);
  });

  test('empty bytes fail closed', () async {
    _expectValidationFailure(
      await serializer.deserialize(Uint8List(0)),
      forbidden: const ['super-secret-login'],
    );
  });

  test('malformed JSON fails closed', () async {
    _expectValidationFailure(
      await serializer.deserialize(_bytes('{')),
      forbidden: const ['FormatException', 'super-secret-login'],
    );
  });

  test('unsupported version fails closed', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json['version'] = 99;
    _expectValidationFailure(
      await serializer.deserialize(_jsonBytes(json)),
      forbidden: const ['99'],
    );
  });

  test('omitted version is not defaulted', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json.remove('version');
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('omitted collection is not defaulted to empty', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json.remove('logins');
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('missing nullable key fails closed', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final loginJson = Map<String, dynamic>.from(json['logins'].single as Map);
    loginJson.remove('website');
    json['logins'] = [loginJson];
    _expectValidationFailure(
      await serializer.deserialize(_jsonBytes(json)),
      forbidden: const ['super-secret-login', 'https://example.com'],
    );
  });

  test('isPinned true round-trips', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login().copyWith(isPinned: true)],
      bankCards: [card().copyWith(isPinned: true)],
      secureNotes: [note().copyWith(isPinned: true)],
      categories: const [],
    );
    expect(await roundTrip(vault), vault);
  });

  test('missing isPinned deserializes as false', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: [card()],
      secureNotes: [note()],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final loginJson = Map<String, dynamic>.from(json['logins'].single as Map);
    final cardJson = Map<String, dynamic>.from(json['bankCards'].single as Map);
    final noteJson = Map<String, dynamic>.from(
      json['secureNotes'].single as Map,
    );
    loginJson.remove('isPinned');
    cardJson.remove('isPinned');
    noteJson.remove('isPinned');
    json['logins'] = [loginJson];
    json['bankCards'] = [cardJson];
    json['secureNotes'] = [noteJson];

    final restored = _expectSuccess(
      await serializer.deserialize(_jsonBytes(json)),
    );
    expect(restored.logins.single.isPinned, isFalse);
    expect(restored.bankCards.single.isPinned, isFalse);
    expect(restored.secureNotes.single.isPinned, isFalse);
  });

  test('isPinned wrong type fails closed', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final loginJson = Map<String, dynamic>.from(json['logins'].single as Map);
    loginJson['isPinned'] = 'yes';
    json['logins'] = [loginJson];
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('unknown keys fail closed', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json['extra'] = true;
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('unknown item keys fail closed', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final loginJson = Map<String, dynamic>.from(json['logins'].single as Map);
    loginJson['favorite'] = true;
    json['logins'] = [loginJson];
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('wrong field types fail closed', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json['version'] = '1';
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('invalid timestamp strings fail closed', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final loginJson = Map<String, dynamic>.from(json['logins'].single as Map);
    loginJson['createdAt'] = 'not-a-timestamp';
    json['logins'] = [loginJson];
    _expectValidationFailure(
      await serializer.deserialize(_jsonBytes(json)),
      forbidden: const ['not-a-timestamp', 'FormatException'],
    );
  });

  test('invalid UTF-8 bytes fail closed', () async {
    _expectValidationFailure(
      await serializer.deserialize(Uint8List.fromList(const [0xFF, 0xFE])),
      forbidden: const ['FormatException', 'Utf8'],
    );
  });

  test('null on required fields fails closed', () async {
    final json = await _serializedJson(serializer, emptyVault());
    json['version'] = null;
    _expectValidationFailure(await serializer.deserialize(_jsonBytes(json)));
  });

  test('duplicate item ids fail closed', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(), login(id: 'login-2')],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final json = await _serializedJson(serializer, vault);
    final first = Map<String, dynamic>.from(json['logins'][0] as Map);
    final second = Map<String, dynamic>.from(json['logins'][1] as Map);
    second['id'] = first['id'];
    json['logins'] = [first, second];
    _expectValidationFailure(
      await serializer.deserialize(_jsonBytes(json)),
      forbidden: const ['super-secret-login'],
    );
  });

  test('serialize rejects unsupported in-memory version', () async {
    final vault = VaultData(
      version: 2,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    _expectValidationFailure(await serializer.serialize(vault));
  });

  test('serialize rejects duplicate ids', () async {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login(), login()],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    _expectValidationFailure(
      await serializer.serialize(vault),
      forbidden: const ['super-secret-login'],
    );
  });

  test('failure messages do not include vault contents or exception text', () async {
    final result = await serializer.deserialize(
      _bytes('{"password":"super-secret-login"}'),
    );
    _expectValidationFailure(
      result,
      forbidden: const [
        'super-secret-login',
        'FormatException',
        'TypeError',
        'password',
      ],
    );
  });
}

Future<Map<String, dynamic>> _serializedJson(
  VaultSerializer serializer,
  VaultData vault,
) async {
  final bytes = _expectSuccess(await serializer.serialize(vault));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

Uint8List _jsonBytes(Object value) {
  return Uint8List.fromList(utf8.encode(jsonEncode(value)));
}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectValidationFailure(
  Result<dynamic> result, {
  List<String> forbidden = const [],
}) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<ValidationFailure>());
  expect(failure.message, 'Vault data is invalid');
  for (final value in forbidden) {
    expect(failure.message, isNot(contains(value)));
  }
}

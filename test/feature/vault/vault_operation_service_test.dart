import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service_impl.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

void main() {
  late _FakeVaultSession session;
  late _FakeVaultDataService dataService;
  late VaultOperationService operations;

  final createdAt = DateTime.utc(2026, 7, 1, 10);
  final updatedAt = DateTime.utc(2026, 7, 2, 11);

  LoginItem login({
    String id = 'login-1',
    String title = 'Mail',
  }) {
    return LoginItem(
      id: id,
      title: title,
      username: 'keep-this-user',
      password: 'keep-this-password',
      website: 'https://mail.test',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BankCardItem card({
    String id = 'card-1',
    String title = 'Travel',
  }) {
    return BankCardItem(
      id: id,
      title: title,
      cardNumber: '6219861234567890',
      cardHolder: 'Nima Karimi',
      expiryDate: '06/30',
      cvv: '321',
      bankName: 'Saman',
      notes: null,
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SecureNoteItem note({
    String id = 'note-1',
    String title = 'Gate',
  }) {
    return SecureNoteItem(
      id: id,
      title: title,
      content: 'building-code-42',
      categoryId: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryItem category({
    String id = 'cat-1',
    String name = 'Work',
  }) {
    return CategoryItem(
      id: id,
      name: name,
      icon: 'inbox',
      createdAt: createdAt,
    );
  }

  VaultData emptyVault() {
    return VaultData(
      version: VaultData.currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
  }

  Future<void> unlockWith(VaultData vault) async {
    _expectSuccess(await session.unlock(vault));
  }

  setUp(() {
    session = _FakeVaultSession();
    dataService = _FakeVaultDataService(session);
    operations = VaultOperationServiceImpl(
      vaultData: dataService,
      vaultSession: session,
    );
  });

  group('getVault', () {
    test('returns the current Vault', () async {
      final vault = emptyVault();
      await unlockWith(vault);

      final result = _expectSuccess(await operations.getVault());

      expect(result, same(vault));
    });

    test('returns AuthenticationFailure when locked', () async {
      _expectFailure<AuthenticationFailure>(await operations.getVault());
    });
  });

  group('getItemById', () {
    test('returns an existing item', () async {
      final mail = login();
      final travel = card();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [mail],
          bankCards: [travel],
          secureNotes: const [],
          categories: const [],
        ),
      );

      expect(_expectSuccess(await operations.getItemById(mail.id)), mail);
      expect(_expectSuccess(await operations.getItemById(travel.id)), travel);
    });

    test('returns ValidationFailure for a missing item', () async {
      await unlockWith(emptyVault());

      _expectFailure<ValidationFailure>(
        await operations.getItemById('missing'),
      );
    });

    test('returns AuthenticationFailure when locked', () async {
      _expectFailure<AuthenticationFailure>(
        await operations.getItemById('login-1'),
      );
    });
  });

  group('addItem', () {
    test('adds the item, leaves existing items unchanged, and persists', () async {
      final existing = login();
      final siblingCard = card();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [existing],
          bankCards: [siblingCard],
          secureNotes: const [],
          categories: const [],
        ),
      );

      final added = login(id: 'login-2', title: 'Work');
      _expectSuccess(await operations.addItem(added));

      final vault = session.vaultData!;
      expect(vault.logins, [existing, added]);
      expect(vault.bankCards, [siblingCard]);
      expect(dataService.persistCount, 1);
      expect(dataService.lastMutation, added);
    });

    test('dispatches a bank card to VaultDataService', () async {
      await unlockWith(emptyVault());
      final travel = card();

      _expectSuccess(await operations.addItem(travel));

      expect(session.vaultData!.bankCards, [travel]);
      expect(dataService.persistCount, 1);
      expect(dataService.lastMutation, travel);
    });

    test('returns ValidationFailure for an unsupported item type', () async {
      await unlockWith(emptyVault());

      _expectFailure<ValidationFailure>(await operations.addItem('not-an-item'));
      expect(dataService.persistCount, 0);
      expect(session.vaultData!.logins, isEmpty);
    });
  });

  group('updateItem', () {
    test('replaces the item, leaves unrelated items unchanged, and persists', () async {
      final original = login();
      final sibling = login(id: 'login-2', title: 'Bank');
      final siblingCard = card();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [original, sibling],
          bankCards: [siblingCard],
          secureNotes: const [],
          categories: const [],
        ),
      );

      final updated = login(title: 'Work Mail');
      _expectSuccess(await operations.updateItem(updated));

      final vault = session.vaultData!;
      expect(vault.logins, [updated, sibling]);
      expect(vault.bankCards, [siblingCard]);
      expect(dataService.persistCount, 1);
      expect(dataService.lastMutation, updated);
    });

    test('returns ValidationFailure for a missing item', () async {
      final existing = login();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [existing],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        ),
      );

      _expectFailure<ValidationFailure>(
        await operations.updateItem(login(id: 'missing')),
      );
      expect(session.vaultData!.logins, [existing]);
      expect(dataService.persistCount, 0);
    });

    test('returns ValidationFailure for an unsupported item type', () async {
      await unlockWith(emptyVault());

      _expectFailure<ValidationFailure>(
        await operations.updateItem(Object()),
      );
      expect(dataService.persistCount, 0);
    });
  });

  group('deleteItem', () {
    test('removes the item, leaves unrelated items unchanged, and persists', () async {
      final target = login();
      final sibling = login(id: 'login-2', title: 'Bank');
      final siblingCard = card();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [target, sibling],
          bankCards: [siblingCard],
          secureNotes: const [],
          categories: const [],
        ),
      );

      _expectSuccess(await operations.deleteItem(target.id));

      final vault = session.vaultData!;
      expect(vault.logins, [sibling]);
      expect(vault.bankCards, [siblingCard]);
      expect(dataService.persistCount, 1);
      expect(dataService.lastMutation, target.id);
    });

    test('returns ValidationFailure for a missing item without calling VaultDataService', () async {
      final existing = login();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [existing],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        ),
      );

      _expectFailure<ValidationFailure>(await operations.deleteItem('missing'));
      expect(session.vaultData!.logins, [existing]);
      expect(dataService.mutationRequested, isFalse);
      expect(dataService.persistCount, 0);
    });

    test('deletes a bank card through VaultDataService', () async {
      final travel = card();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: const [],
          bankCards: [travel],
          secureNotes: const [],
          categories: const [],
        ),
      );

      _expectSuccess(await operations.deleteItem(travel.id));

      expect(session.vaultData!.bankCards, isEmpty);
      expect(dataService.persistCount, 1);
    });
  });

  group('failure propagation', () {
    test('propagates CryptoFailure from VaultDataService', () async {
      await unlockWith(emptyVault());
      dataService.nextFailure = const CryptoFailure();

      _expectFailure<CryptoFailure>(await operations.addItem(login()));
      expect(session.vaultData!.logins, isEmpty);
      expect(dataService.persistCount, 0);
    });

    test('propagates DatabaseFailure from VaultDataService', () async {
      final existing = login();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [existing],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        ),
      );
      dataService.nextFailure = const DatabaseFailure();

      _expectFailure<DatabaseFailure>(
        await operations.updateItem(login(title: 'Work Mail')),
      );
      expect(session.vaultData!.logins, [existing]);
      expect(dataService.persistCount, 0);
    });

    test('propagates AuthenticationFailure from VaultDataService', () async {
      await unlockWith(emptyVault());
      dataService.nextFailure = const AuthenticationFailure();

      _expectFailure<AuthenticationFailure>(await operations.addItem(note()));
      expect(session.vaultData!.secureNotes, isEmpty);
      expect(dataService.persistCount, 0);
    });

    test('propagates ValidationFailure from VaultDataService on add', () async {
      final existing = login();
      await unlockWith(
        VaultData(
          version: VaultData.currentVersion,
          logins: [existing],
          bankCards: const [],
          secureNotes: const [],
          categories: const [],
        ),
      );
      dataService.nextFailure = const ValidationFailure();

      _expectFailure<ValidationFailure>(
        await operations.addItem(login(id: 'login-2')),
      );
      expect(session.vaultData!.logins, [existing]);
      expect(dataService.persistCount, 0);
    });
  });

  test('add, update, and delete also work for notes and categories', () async {
    await unlockWith(emptyVault());
    final gate = note();
    final work = category();

    _expectSuccess(await operations.addItem(gate));
    _expectSuccess(await operations.addItem(work));
    expect(session.vaultData!.secureNotes, [gate]);
    expect(session.vaultData!.categories, [work]);

    final renamed = note(title: 'Door');
    _expectSuccess(await operations.updateItem(renamed));
    expect(session.vaultData!.secureNotes, [renamed]);
    expect(session.vaultData!.categories, [work]);

    _expectSuccess(await operations.deleteItem(work.id));
    expect(session.vaultData!.categories, isEmpty);
    expect(session.vaultData!.secureNotes, [renamed]);
  });
}

class _FakeVaultSession implements VaultSession {
  VaultData? _vaultData;

  @override
  bool get isUnlocked => _vaultData != null;

  @override
  VaultData? get vaultData => _vaultData;

  @override
  Future<Result<void>> unlock(VaultData vaultData) async {
    _vaultData = vaultData;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> lock() async {
    _vaultData = null;
    return const Success<void>(null);
  }
}

class _FakeVaultDataService implements VaultDataService {
  _FakeVaultDataService(this._session);

  final VaultSession _session;

  int persistCount = 0;
  bool mutationRequested = false;
  Object? lastMutation;
  AppFailure? nextFailure;

  @override
  Future<Result<void>> addLogin(LoginItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _addItem(current.logins, item, (login) => login.id),
        (logins) => _rebuild(current, logins: logins),
      ),
    );
  }

  @override
  Future<Result<void>> updateLogin(LoginItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _replaceItem(current.logins, item, (login) => login.id),
        (logins) => _rebuild(current, logins: logins),
      ),
    );
  }

  @override
  Future<Result<void>> deleteLogin(String id) {
    return _mutate(
      id,
      (current) => _withCollection(
        _removeItem(current.logins, id, (login) => login.id),
        (logins) => _rebuild(current, logins: logins),
      ),
    );
  }

  @override
  Future<Result<void>> addBankCard(BankCardItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _addItem(current.bankCards, item, (card) => card.id),
        (bankCards) => _rebuild(current, bankCards: bankCards),
      ),
    );
  }

  @override
  Future<Result<void>> updateBankCard(BankCardItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _replaceItem(current.bankCards, item, (card) => card.id),
        (bankCards) => _rebuild(current, bankCards: bankCards),
      ),
    );
  }

  @override
  Future<Result<void>> deleteBankCard(String id) {
    return _mutate(
      id,
      (current) => _withCollection(
        _removeItem(current.bankCards, id, (card) => card.id),
        (bankCards) => _rebuild(current, bankCards: bankCards),
      ),
    );
  }

  @override
  Future<Result<void>> addSecureNote(SecureNoteItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _addItem(current.secureNotes, item, (note) => note.id),
        (secureNotes) => _rebuild(current, secureNotes: secureNotes),
      ),
    );
  }

  @override
  Future<Result<void>> updateSecureNote(SecureNoteItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _replaceItem(current.secureNotes, item, (note) => note.id),
        (secureNotes) => _rebuild(current, secureNotes: secureNotes),
      ),
    );
  }

  @override
  Future<Result<void>> deleteSecureNote(String id) {
    return _mutate(
      id,
      (current) => _withCollection(
        _removeItem(current.secureNotes, id, (note) => note.id),
        (secureNotes) => _rebuild(current, secureNotes: secureNotes),
      ),
    );
  }

  @override
  Future<Result<void>> addCategory(CategoryItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _addItem(current.categories, item, (category) => category.id),
        (categories) => _rebuild(current, categories: categories),
      ),
    );
  }

  @override
  Future<Result<void>> updateCategory(CategoryItem item) {
    return _mutate(
      item,
      (current) => _withCollection(
        _replaceItem(current.categories, item, (category) => category.id),
        (categories) => _rebuild(current, categories: categories),
      ),
    );
  }

  @override
  Future<Result<void>> deleteCategory(String id) {
    return _mutate(
      id,
      (current) => _withCollection(
        _removeItem(current.categories, id, (category) => category.id),
        (categories) => _rebuild(current, categories: categories),
      ),
    );
  }

  Future<Result<void>> _mutate(
    Object mutation,
    Result<VaultData> Function(VaultData current) build,
  ) async {
    mutationRequested = true;
    lastMutation = mutation;
    if (nextFailure != null) {
      final failure = nextFailure!;
      nextFailure = null;
      return FailureResult(failure);
    }
    if (!_session.isUnlocked) {
      return const FailureResult(AuthenticationFailure());
    }
    final current = _session.vaultData;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }
    final candidate = build(current);
    if (candidate is FailureResult<VaultData>) {
      return FailureResult(candidate.failure);
    }
    persistCount++;
    await _session.unlock((candidate as Success<VaultData>).data);
    return const Success(null);
  }

  Result<VaultData> _withCollection<T>(
    Result<List<T>> collection,
    VaultData Function(List<T> items) rebuild,
  ) {
    if (collection is FailureResult<List<T>>) {
      return FailureResult(collection.failure);
    }
    return Success(rebuild((collection as Success<List<T>>).data));
  }

  Result<List<T>> _addItem<T>(
    List<T> items,
    T item,
    String Function(T item) idOf,
  ) {
    final id = idOf(item);
    if (items.any((existing) => idOf(existing) == id)) {
      return const FailureResult(ValidationFailure());
    }
    return Success([...items, item]);
  }

  Result<List<T>> _replaceItem<T>(
    List<T> items,
    T item,
    String Function(T item) idOf,
  ) {
    final id = idOf(item);
    final index = items.indexWhere((existing) => idOf(existing) == id);
    if (index < 0) {
      return const FailureResult(ValidationFailure());
    }
    final copy = List<T>.of(items);
    copy[index] = item;
    return Success(copy);
  }

  Result<List<T>> _removeItem<T>(
    List<T> items,
    String id,
    String Function(T item) idOf,
  ) {
    final index = items.indexWhere((existing) => idOf(existing) == id);
    if (index < 0) {
      return const FailureResult(ValidationFailure());
    }
    final copy = List<T>.of(items)..removeAt(index);
    return Success(copy);
  }

  VaultData _rebuild(
    VaultData current, {
    List<LoginItem>? logins,
    List<BankCardItem>? bankCards,
    List<SecureNoteItem>? secureNotes,
    List<CategoryItem>? categories,
  }) {
    return VaultData(
      version: current.version,
      logins: logins ?? current.logins,
      bankCards: bankCards ?? current.bankCards,
      secureNotes: secureNotes ?? current.secureNotes,
      categories: categories ?? current.categories,
    );
  }
}

T _expectSuccess<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).data;
}

void _expectFailure<F extends AppFailure>(Result<dynamic> result) {
  expect(result, isA<FailureResult<dynamic>>());
  final failure = (result as FailureResult<dynamic>).failure;
  expect(failure, isA<F>());
}

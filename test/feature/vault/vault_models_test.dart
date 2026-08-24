import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1, 8, 30);
  final updatedAt = DateTime.utc(2026, 1, 2, 9, 45);

  final login = LoginItem(
    id: 'login-1',
    title: 'Email',
    username: 'user@example.com',
    password: 'secret-password',
    website: 'https://mail.example.com',
    notes: 'work account',
    categoryId: 'cat-1',
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  final card = BankCardItem(
    id: 'card-1',
    title: 'Primary',
    cardNumber: '6037991234567890',
    cardHolder: 'Ali Reza',
    expiryDate: '12/28',
    cvv: '123',
    bankName: 'Melli',
    notes: 'salary card',
    categoryId: 'cat-1',
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  final note = SecureNoteItem(
    id: 'note-1',
    title: 'WiFi',
    content: 'home-network-key',
    categoryId: 'cat-1',
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  final category = CategoryItem(
    id: 'cat-1',
    name: 'Work',
    icon: 'briefcase',
    createdAt: createdAt,
  );

  test('models can be created with valid data', () {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login],
      bankCards: [card],
      secureNotes: [note],
      categories: [category],
    );

    expect(vault.version, VaultData.currentVersion);
    expect(vault.logins.single, login);
    expect(vault.bankCards.single, card);
    expect(vault.secureNotes.single, note);
    expect(vault.categories.single, category);
  });

  test('initial vault includes the three default categories', () {
    final vault = VaultData.initial();

    expect(vault.version, VaultData.currentVersion);
    expect(vault.logins, isEmpty);
    expect(vault.bankCards, isEmpty);
    expect(vault.secureNotes, isEmpty);
      expect(vault.categories.map((item) => item.id), [
      'cat_personal',
      'cat_finance',
      'cat_work',
    ]);
    expect(vault.categories.map((item) => item.name), ['شخصی', 'مالی', 'کاری']);
    expect(vault, VaultData.initial());
  });

  test('required fields are preserved', () {
    expect(login.id, 'login-1');
    expect(login.title, 'Email');
    expect(login.username, 'user@example.com');
    expect(login.password, 'secret-password');
    expect(login.website, 'https://mail.example.com');
    expect(login.notes, 'work account');
    expect(login.categoryId, 'cat-1');
    expect(login.createdAt, createdAt);
    expect(login.updatedAt, updatedAt);

    expect(card.cardNumber, '6037991234567890');
    expect(card.cardHolder, 'Ali Reza');
    expect(card.expiryDate, '12/28');
    expect(card.cvv, '123');
    expect(card.bankName, 'Melli');

    expect(note.content, 'home-network-key');
    expect(category.icon, 'briefcase');
  });

  test('nullable fields can be explicitly null', () {
    final loginWithoutOptionals = LoginItem(
      id: 'login-2',
      title: 'Local',
      username: 'local',
      password: 'pw',
      website: null,
      notes: null,
      categoryId: null,
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.utc(2026, 3, 2),
    );

    expect(loginWithoutOptionals.website, isNull);
    expect(loginWithoutOptionals.notes, isNull);
    expect(loginWithoutOptionals.categoryId, isNull);
  });

  test('value equality compares all fields', () {
    final sameLogin = LoginItem(
      id: login.id,
      title: login.title,
      username: login.username,
      password: login.password,
      website: login.website,
      notes: login.notes,
      categoryId: login.categoryId,
      createdAt: login.createdAt,
      updatedAt: login.updatedAt,
    );
    expect(sameLogin, login);
    expect(sameLogin.hashCode, login.hashCode);

    final otherLogin = LoginItem(
      id: 'login-other',
      title: login.title,
      username: login.username,
      password: login.password,
      website: login.website,
      notes: login.notes,
      categoryId: login.categoryId,
      createdAt: login.createdAt,
      updatedAt: login.updatedAt,
    );
    expect(otherLogin, isNot(login));

    final first = VaultData(
      version: VaultData.currentVersion,
      logins: [login],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    final second = VaultData(
      version: VaultData.currentVersion,
      logins: [login],
      bankCards: const [],
      secureNotes: const [],
      categories: const [],
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('vault collections cannot be mutated after construction', () {
    final sourceLogins = [login];
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: sourceLogins,
      bankCards: [card],
      secureNotes: [note],
      categories: [category],
    );

    sourceLogins.add(
      LoginItem(
        id: 'login-extra',
        title: 'Extra',
        username: 'extra',
        password: 'extra-secret',
        website: null,
        notes: null,
        categoryId: null,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );

    expect(vault.logins, [login]);
    expect(() => vault.logins.add(login), throwsUnsupportedError);
    expect(() => vault.bankCards.removeAt(0), throwsUnsupportedError);
    expect(() => vault.secureNotes.clear(), throwsUnsupportedError);
    expect(() => vault.categories[0] = category, throwsUnsupportedError);
  });

  test('isPinned defaults to false and participates in equality', () {
    expect(login.isPinned, isFalse);
    expect(card.isPinned, isFalse);
    expect(note.isPinned, isFalse);

    final pinned = login.copyWith(isPinned: true);
    expect(pinned.isPinned, isTrue);
    expect(pinned, isNot(login));
    expect(login.copyWith(isPinned: false), login);
  });

  test('pinnedItemCount counts across item types', () {
    final vault = VaultData(
      version: VaultData.currentVersion,
      logins: [login.copyWith(isPinned: true)],
      bankCards: [card.copyWith(isPinned: true)],
      secureNotes: [note],
      categories: [category],
    );
    expect(vault.pinnedItemCount, 2);
    expect(VaultData.maxPinnedItems, 5);
  });
}
